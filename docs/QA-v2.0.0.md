# v2.0.0 發版紀錄

日期：2026-09-09。狀態：[v2.0.0 已正式發佈](https://github.com/funkeyyou/zaimanhua/releases/tag/v2.0.0)，發布時間 15:50:17（UTC+8）。

## 來源與範圍

- 版本 `2.0.0+20000`，合併 `codex/reading-hub-ui` 至預設分支 `zaimanhua`。
- 功能基底 `22171c52ca638247bb89189e5476aa03498b2cf8`，已通過 [CI 34303946612](https://github.com/funkeyyou/zaimanhua/actions/runs/34303946612) 的 analyze、78 個測試、Android 與 Windows 建置。
- 本次發版只調整版本與文件，程式、圖示及平台設定保持已驗收內容。採用使用者確認的原創向量圖示，未套用後續生圖稿。
- 完整 UI 驗證見 [QA-2026-09-09-UI](QA-2026-09-09-UI.md)，對外說明見 [v2.0.0 版本說明](releases/v2.0.0.md)。

## 發版檢查

- Tag：`v2.0.0`；提交：`ee60e02439131fb7ed5d162a4afadfbe93390536`。
- [正式 CI 34324717547](https://github.com/funkeyyou/zaimanhua/actions/runs/34324717547)：analyze、78 個測試、Android release APK、Windows release ZIP 及兩平台資產上傳全數成功。
- APK：`com.xycz.zmhx`、versionName `2.0.0`、versionCode `20000`；桌面名稱簡體「再漫画X」、繁體「再漫畫X」。
- APK 簽章驗證通過，與 v1.9.0 實際憑證比對一致；憑證 SHA-256 為 `4e2f84076e0c2a4361a8b23d9678b58b763bb43ecd45f437aa9bd0acd018b222`。
- Windows ZIP 已完整解壓檢查。EXE 的 FileVersion／ProductVersion 均為 `2.0.0+20000`，FileDescription 為「再漫畫X」，ProductName 保留 `zai_x`，沿用原本資料位置。
- 匿名 `releases/latest?ts=...` 正確回傳 v2.0.0，非草稿、非預發佈，且包含兩個安裝檔；兩個公開下載連結均回 HTTP 200，Content-Length 與資產大小一致。
- 下載的兩個檔案 SHA-256 均與 GitHub 資產 digest 一致，存放於 `build/release-2.0.0/current/`。

| 資產 | bytes | SHA-256 |
| --- | ---: | --- |
| ZAI-X-android.apk | 88,534,311 | `a4dba16325d538c63d6c7275536643228123127111a3aedc1f9c742d6c499623` |
| ZAI-X-windows-x64.zip | 29,086,002 | `562128d25cc5781dc34b3fef4509578bc2353b9bac71a4da8be88d8981d0a1e1` |

## 舊版下載整理

- 依使用者只保留最新版的設定，在 2.0.0 公開且下載驗證成功後，移除 v1.9.0 Release 與其線上安裝檔；Release 清單現在僅有 v2.0.0 Latest。
- v1.9.0 tag 仍保留，指向 `a2525f45f9d1168ffad34c143ab6fff89f8bf9ca`，原始碼歷史未刪除。
- v1.9.0 APK 與 Windows ZIP 仍保存在 `build/release-1.9.0/current/`，已在刪除遠端資產前核對 SHA-256 與 GitHub 原資產一致；原版本說明亦保留在 `docs/releases/v1.9.0.md`。
