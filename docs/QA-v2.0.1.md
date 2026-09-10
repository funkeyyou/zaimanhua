# v2.0.1 發版紀錄

日期：2026-09-11。版本：`2.0.1+20001`。狀態：[已正式發布](https://github.com/funkeyyou/zaimanhua/releases/tag/v2.0.1)，發布時間 00:20:17（UTC+8）。

範圍：已驗收的橫向跨集手勢修正，詳見 [手勢驗證紀錄](QA-2026-09-11-reader-swipe.md)。使用者確認 Android 驗收通過；本機 81 項測試通過。

- Tag `v2.0.1` 指向 `fde8823f14ee159f01ec039e177fb8069a4c13ac`。
- [正式 CI 34500240234](https://github.com/funkeyyou/zaimanhua/actions/runs/34500240234)：analyze、81 項測試、Android／Windows 建置及資產上傳全部成功。
- APK：`com.xycz.zmhx`，versionName `2.0.1`、versionCode `20001`；簽章驗證成功，與 v2.0.0 實際 APK 憑證一致。
- 簽章 SHA-256：`4e2f84076e0c2a4361a8b23d9678b58b763bb43ecd45f437aa9bd0acd018b222`。
- Windows ZIP 完整解壓；EXE FileVersion／ProductVersion `2.0.1+20001`，FileDescription「再漫畫X」，ProductName `zai_x`。
- 兩個下載產物 SHA-256 與 GitHub digest 一致，保存在 `build/release-2.0.1/current/`。
- 匿名 latest API 回傳 v2.0.1，非草稿／非預發佈；兩個公開下載 HEAD 均 HTTP 200，大小正確。
- 下載頁已移除 v2.0.0 Release／線上安裝檔，僅保留 v2.0.1；舊 tag 與 `build/release-2.0.0/current/` 備份保留，刪除前已核對備份雜湊。
- 本次 Windows 驗證為建置與產物檢查，未另作實機手勢驗收。

| 資產 | bytes | SHA-256 |
| --- | ---: | --- |
| ZAI-X-android.apk | 88616231 | `924aa7d7b81b514dbac87d886e4cd398e55e9d0c0934421838950babbd46ad23` |
| ZAI-X-windows-x64.zip | 29087798 | `1953682f236dd97cc7f88f9b875302adab8ff3064cb62167ae60e7f46e0de8f3` |
