# v2.6.1 發版紀錄

日期：2026-11-17。版本：`2.6.1+26100`。狀態：[已正式發布](https://github.com/funkeyyou/zaimanhua/releases/tag/v2.6.1)。

範圍：修正 v2.6.0 連續閱讀時兩話之間夾著吐槽區、「查看更多」與分隔條，閱讀不連貫（[#7](https://github.com/funkeyyou/zaimanhua/issues/7)）。v2.6.0 Release 已由使用者刪除（tag 保留），檢查更新的原站與 gh-proxy 都已回到 v2.5.0；已更新到 2.6.0 的使用者可收到 2.6.1。

## 改動

- 新增 `showViewPointPage`：連續閱讀生效（上下滾動、站內作品、開關開啟）時，各話結尾不再加吐槽頁；吐槽仍可從下方選單的吐槽按鈕開啟。關閉連續閱讀或改為左右翻頁時照舊顯示。
- 原 `setShowViewPoint` 改為 `syncViewPointPages`，依目前設定補上或拿掉吐槽頁；切換「显示吐槽」「连续阅读」、閱讀方向與重設偏好時都會同步，並重新對回目前頁。
- 依使用者要求拿掉兩話之間的分隔條，下一話第一張圖直接接在上一話最後一張後面，換話只反映在狀態列。

## 驗證

- 本機：analyze 0 error／0 warning（13 則既有 info）；236 項測試全部通過。
- MuMu（1920×1080 橫向）：《8级魔法师的回归》第 10 話變為 34 頁（不含吐槽頁）；從第 10 話最後一頁往下滑，下方直接接第 11 話第一張圖，中間沒有吐槽區、按鈕或分隔，狀態列由「第10话 34 / 34」換成「第11话 1 / 33」。截圖 `docs/images/continuous-reader/seamless.png`。
- 未驗證：實機雙指縮放手感、iOS／Windows 實際操作。

## 發布檢查

- 開發分支 `codex/issue-7-zoom-continuous`（已關聯 #7）快轉合併回 `zaimanhua`；tag `v2.6.1` 指向 `93321aa`。先建草稿，CI 產物核對後公開。
- [正式 CI 44049545984](https://github.com/funkeyyou/zaimanhua/actions/runs/44049545984)：分析、測試、Android／Windows／iOS 建置與上傳全部成功。
- 產物大小與 SHA-256 與 Release digest 一致：
  - `ZAI-X-android.apk`：93082507 bytes，`3730aa8b5494aaba99b2d67246a7442f162dd7e17ec8ada50cdc606d7158ee1f`
  - `ZAI-X-windows-x64.zip`：32147234 bytes，`1ac3d095821c0e2b09b0c4ca65ffb6b488d4e641273ea224aac3730d24fa602f`
  - `ZAI-X-ios-unsigned.ipa`：27540045 bytes，`1caae7544778e2c93a325d069ecb7174ca1204ebd7f1ba0733da14a9d4cdb5a9`
- APK：versionName 2.6.1、versionCode 26100，簽章與前版相同。舊 Release（v2.5.0）保留。
