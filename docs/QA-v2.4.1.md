# v2.4.1 發版紀錄

日期：2026-11-02。版本：`2.4.1+24100`。狀態：[已正式發布](https://github.com/funkeyyou/zaimanhua/releases/tag/v2.4.1)，發布時間 01:06:21（UTC+8）。

範圍：修正漫畫評論區空白（[#6](https://github.com/funkeyyou/zaimanhua/issues/6)）。對外說明見 [版本說明](releases/v2.4.1.md)。

## 原因

- 作品詳情 `is_need_login=1` 的作品，`/app/v1/comment/list` 在沒有 `Authorization` 時一律回傳空列表（errno 0、total 0）；`is_need_login=0` 的作品不受影響。
- 官方 App 2.3.8 用同一個接口；換 `type`、`_v`、排序參數都沒有差異，帶假 token 也一樣是空的。
- 以 MuMu 上本 App 已登入帳號的 token 直接查詢：83319 由 0 筆變成 245 筆，89105 由 0 筆變成 28 筆，89138 由 0 筆變成 20 筆；20844（不需登入）前後都是 102 筆。
- `CommentRequest.getComment` 原本沒有設 `needLogin`，已登入也不帶 token。修正為 `needLogin: true`：已登入時附上 token 與 uid，未登入時行為不變。

## 驗證

- 本機：analyze 0 error／0 warning（13 則既有 info）；225 項測試全部通過。
- MuMu：本機正式簽名包與正式 CI APK 覆蓋安裝，登入狀態保留；需登入作品的最新評論與熱門評論都能正常顯示。
- 未驗證：iOS 實機（TestFlight 由 Mac mini 另行打包上傳）；未登入時需登入作品的評論區仍是空白，屬預期行為。

## 發布檢查

- 第一次推送 tag 時，主分支因遠端已有 iOS 相關提交被拒，草稿也沒建立；當次 CI 41328300417 已取消、遠端 tag 已刪除，沒有產生 Release。rebase 到 `0c51799` 後重新發布（`pubspec.yaml` 版本衝突取 `2.4.1+24100`）。
- Tag `v2.4.1` 指向 `3aed977e26c43e0b159356687344d7d297b793e9`，與 `zaimanhua` 主分支一致；先建立 Release 草稿，CI 產物上傳後核對才公開。
- [正式 CI 41328506150](https://github.com/funkeyyou/zaimanhua/actions/runs/41328506150)：分析、測試、Android／Windows／iOS 建置及資產上傳全部成功。
- 正式產物下載到 `build/release-2.4.1/current/`，大小及 SHA-256 與 Release digest 一致：
  - `ZAI-X-android.apk`：92967551 bytes，`5f36e365055c92bf4a863a87dbc55dc44fa3ba61e79368f1f1f42a4456837fcb`
  - `ZAI-X-windows-x64.zip`：32118213 bytes，`480bf9e268d98bff5f2338aa8aaf640b2a0c3fd56472647056cdb1713e361dc0`
  - `ZAI-X-ios-unsigned.ipa`：27509410 bytes，`8084ea803e362ecab089433f868d32a914f23df09ed8d8cb2a853084b564c051`
- 正式 APK：套件 `com.xycz.zmhx`，versionName 2.4.1、versionCode 24100，簽章 SHA-256 `4e2f84076e0c2a4361a8b23d9678b58b763bb43ecd45f437aa9bd0acd018b222` 與 v2.4.0 相同。
- 匿名 latest API 回傳 v2.4.1（非草稿、非預發布），含三個資產。
- 舊版 v2.4.0 的 APK／ZIP 已備份在 `build/release-2.4.0/current/`，刪除前核對大小及 SHA-256 與 Release digest 一致；舊 Release 已移除、tag 保留，下載頁僅保留最新版。
