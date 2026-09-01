# 一次性設定：儲存加密憑證 + 註冊每日排程工作
# 請「自己」在 PowerShell 視窗執行本腳本（會互動式詢問帳密，密碼不會顯示、不會離開這台電腦）
#
#   powershell -ExecutionPolicy Bypass -File setup_local_signin.ps1
#
# 完成後每天 09:00 自動簽到（開機晚了會補跑）。
# 移除：  Unregister-ScheduledTask -TaskName "ZaimanhuaSignin" -Confirm:$false
#         Remove-Item -Recurse "$env:LOCALAPPDATA\zaimanhua-signin"

$ErrorActionPreference = "Stop"

$dir = Join-Path $env:LOCALAPPDATA "zaimanhua-signin"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

# 1. 詢問帳密，DPAPI 加密後存檔（只有目前這個 Windows 使用者能解開）
$cred = Get-Credential -Message "輸入再漫畫帳號密碼（僅加密儲存於本機）"
if (-not $cred) { Write-Error "已取消"; exit 1 }
$cred | Export-Clixml -Path (Join-Path $dir "cred.xml")
Write-Output "憑證已加密儲存至 $dir\cred.xml"

# 2. 先跑一次驗證帳密正確
$scriptPath = Join-Path $PSScriptRoot "auto_signin.ps1"
& powershell -NoProfile -ExecutionPolicy Bypass -File $scriptPath
if ($LASTEXITCODE -ne 0) {
  Write-Error "驗證失敗，未註冊排程。請重新執行本腳本輸入正確帳密。"
  Remove-Item (Join-Path $dir "cred.xml") -Force
  exit 1
}

# 3. 註冊每日 09:00 排程（錯過會盡快補跑）
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
  -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -At 09:00
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries
Register-ScheduledTask -TaskName "ZaimanhuaSignin" -Action $action -Trigger $trigger `
  -Settings $settings -Description "再漫畫每日自動簽到" -Force | Out-Null

Write-Output "排程已註冊：每天 09:00 自動簽到（工作名稱 ZaimanhuaSignin）"
