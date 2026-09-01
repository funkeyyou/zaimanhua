# 再漫畫自動簽到工具

不用開 App 也能完成每日簽到。行為與 App 內建簽到完全相同（同一組 API、單帳號、一天一次），差別只是由排程代勞。

## 方式一：本機排程（Windows）

在 PowerShell 視窗執行一次：

```powershell
powershell -ExecutionPolicy Bypass -File tools\auto_signin\setup_local_signin.ps1
```

- 互動式輸入帳密 → 以 Windows DPAPI 加密存於 `%LOCALAPPDATA%\zaimanhua-signin\`（只有你這個 Windows 帳戶能解密，不會上傳任何地方）
- 立即試簽一次驗證帳密
- 註冊每日 09:00 的排程工作 `ZaimanhuaSignin`（開機晚了會補跑）

移除：

```powershell
Unregister-ScheduledTask -TaskName "ZaimanhuaSignin" -Confirm:$false
Remove-Item -Recurse "$env:LOCALAPPDATA\zaimanhua-signin"
```

限制：電腦整天沒開機就不會簽到。若要不依賴電腦，用方式二。

## 方式二：GitHub Actions 每日 cron（電腦關機也能簽）

1. 到倉庫 **Settings → Secrets and variables → Actions**：
   - **Secrets** 新增 `ZMH_USERNAME`、`ZMH_PASSWORD`
   - **Variables** 新增 `ENABLE_DAILY_SIGNIN` = `1`（開關；刪掉即停用）
2. 完成。`daily_signin.yml` 每天台北時間 08:30 執行；也可到 Actions 頁手動 Run 測試。

注意：帳密以 GitHub Secrets 儲存（加密、日誌中自動遮罩）。介意的話請用方式一，憑證完全不出本機。

## 說明

- 簽到「今天已簽過」視為成功（結束碼 0），只有登入失敗/網路錯誤才回報失敗
- API 細節：`POST account-api.zaimanhua.com/v1/login/passwd`（密碼 MD5）取 token → `POST m.zaimanhua.com/lpi/v1/task/sign_in`（Bearer）
- App 本身在啟動時也會自動簽到，兩者並存無害（後到的一方會收到「已簽到」）
