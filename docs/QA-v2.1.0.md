# v2.1.0 發版紀錄

日期：2026-09-24。版本：`2.1.0+21000`。狀態：[已正式發布](https://github.com/funkeyyou/zaimanhua/releases/tag/v2.1.0)，發布時間 21:18:48（UTC+8）。

範圍：關於頁作者資訊更新為 funkeyyou，以及閱讀器與導航的內部調整。對外說明見 [v2.1.0 版本說明](releases/v2.1.0.md)。

- Tag `v2.1.0` 指向 `7ba4cf3895e405674a574c2e8f67304e15d6d500`。
- 本機 analyze 0 error／0 warning（13 條既有 info），104 項測試通過。
- [正式 CI 36003857320](https://github.com/funkeyyou/zaimanhua/actions/runs/36003857320)：analyze、測試、Android／Windows 建置及資產上傳全部成功。
- 本機 release APK：`com.xycz.zmhx`，versionName `2.1.0`、versionCode `21000`；簽章 SHA-256 `4e2f84076e0c2a4361a8b23d9678b58b763bb43ecd45f437aa9bd0acd018b222`，與 v2.0.1 相同。
- MuMu：自 2.0.1 覆蓋安裝成功，既有資料保留；導航與關於頁顯示 Ver 2.1.0、funkeyyou；錯誤日誌無 FATAL EXCEPTION、Unhandled Exception、RenderFlex 或 E/flutter。
- Windows ZIP：下載後 SHA-256 與 GitHub digest 一致，解壓 55 個檔案；EXE ProductVersion `2.1.0+21000`、FileDescription「再漫畫X」、ProductName `zai_x`。實際啟動後導航與分頁標題正常顯示繁體。
- 匿名 latest API 回傳 v2.1.0（非草稿），資產為 APK 與 Windows ZIP。
- v2.0.1 的 APK 與 Windows ZIP 已保存在 `build/release-2.0.1/current/`，雜湊與原 GitHub 資產一致。

| 資產 | bytes | SHA-256（GitHub digest） |
| --- | ---: | --- |
| ZAI-X-android.apk | 89206791 | `a989ff2f7a0f0fb67a44037737b0f90af14841a5a905685d6c266bc13c8484f9` |
| ZAI-X-windows-x64.zip | 29175561 | `1c46ee5b7464c9856e917c8921e8a84c4bef41db1c32e5706558750aacf1a0a8` |

