# 再漫畫（zaimanhua.com）每日自動簽到
# 行為與 App 內建簽到完全一致：POST /login/passwd（密碼 MD5）取得 token，再 POST /task/sign_in
#
# 憑證來源（優先序）：
#   1. 環境變數 ZMH_USERNAME / ZMH_PASSWORD（GitHub Actions 用 secrets 注入）
#   2. 本機 DPAPI 加密憑證檔（先執行 setup_local_signin.ps1 建立）
#
# 結束碼：0 = 簽到成功或今日已簽；1 = 登入失敗/網路錯誤/憑證缺失

$ErrorActionPreference = "Stop"

function Get-Md5Hex([string]$s) {
  $md5 = [System.Security.Cryptography.MD5]::Create()
  try {
    $bytes = $md5.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($s))
    return (($bytes | ForEach-Object { $_.ToString("x2") }) -join "")
  } finally { $md5.Dispose() }
}

# --- 取得憑證 ---
$username = $env:ZMH_USERNAME
$password = $env:ZMH_PASSWORD

if (-not $username -or -not $password) {
  $credPath = Join-Path $env:LOCALAPPDATA "zaimanhua-signin\cred.xml"
  if (Test-Path $credPath) {
    $cred = Import-Clixml $credPath
    $username = $cred.UserName
    $password = $cred.GetNetworkCredential().Password
  }
}
if (-not $username -or -not $password) {
  Write-Error "找不到帳號密碼：請設定 ZMH_USERNAME/ZMH_PASSWORD 環境變數，或先執行 setup_local_signin.ps1"
  exit 1
}

# --- 1. 登入（與 App 相同：密碼以小寫 MD5 傳送）---
try {
  $login = Invoke-RestMethod -Method Post `
    -Uri "https://account-api.zaimanhua.com/v1/login/passwd" `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{ username = $username; passwd = (Get-Md5Hex $password) } `
    -TimeoutSec 30
} catch {
  Write-Error "登入請求失敗：$($_.Exception.Message)"
  exit 1
}

$loginErr = $login.errno; if ($null -eq $loginErr) { $loginErr = $login.code }
if ($loginErr -ne 0) {
  $msg = $login.errmsg; if (-not $msg) { $msg = $login.msg }
  Write-Error "登入失敗（errno=$loginErr）：$msg"
  exit 1
}
$token = $login.data.user.token
if (-not $token) { Write-Error "登入回應中沒有 token，API 可能已變更"; exit 1 }
Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 登入成功（uid=$($login.data.user.uid)）"

# --- 2. 簽到 ---
try {
  $r = Invoke-RestMethod -Method Post `
    -Uri "https://m.zaimanhua.com/lpi/v1/task/sign_in" `
    -Headers @{ Authorization = "Bearer $token" } `
    -TimeoutSec 30
} catch {
  Write-Error "簽到請求失敗：$($_.Exception.Message)"
  exit 1
}

if ($r.errno -eq 0) {
  Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] 簽到成功"
} elseif ($r.errno -eq 1) {
  $msg = $r.errmsg; if (-not $msg) { $msg = "今天已簽到過" }
  Write-Output "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg（視為成功）"
} else {
  Write-Error "簽到失敗：errno=$($r.errno) $($r.errmsg)"
  exit 1
}
exit 0
