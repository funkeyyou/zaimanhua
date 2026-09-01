# 本機出繁體中文 Windows 版：轉換 -> 建置 -> 還原源碼
# 需求：python + pip install opencc-python-reimplemented；務必在乾淨工作目錄執行
# 用法（在倉庫根目錄）：powershell -ExecutionPolicy Bypass -File tools\s2twp\build_tc_windows.ps1
$repo = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$dirty = git -C $repo status --porcelain -- lib assets
if ($dirty) { Write-Error "lib/assets 有未提交變更，先提交或還原再執行"; exit 1 }
python "$PSScriptRoot\convert.py"
if ($LASTEXITCODE -ne 0) { Write-Error "轉換失敗"; exit 1 }
try {
  # 中文路徑會壞建置：一律走 junction C:\Users\funke\zmh
  Push-Location C:\Users\funke\zmh
  flutter build windows --release
} finally {
  Pop-Location
  git -C $repo checkout -- lib assets
  Write-Output "源碼已還原為簡體；繁體版在 build\windows\x64\runner\Release\"
}
