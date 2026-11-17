# v2.6.0 發版紀錄

日期：2026-11-17。版本：`2.6.0+26000`。狀態：[已正式發布](https://github.com/funkeyyou/zaimanhua/releases/tag/v2.6.0)。

範圍：上下滾動模式雙指縮放與連續閱讀（[#7](https://github.com/funkeyyou/zaimanhua/issues/7)）。開發分支 `codex/issue-7-zoom-continuous` 已透過 GitHub Development 關聯 #7，快轉合併回 `zaimanhua`。

## 改動

- 雙指縮放：`VerticalZoomView` 以原始指標事件處理，不進手勢競技場，點擊翻頁與呼出選單不受影響。整條列表一起放大（1～4 倍），捏合時暫停列表捲動；放大後單指上下照常捲動、左右平移；捏回接近原大小會還原。支援觸控板縮放。
- 連續閱讀（預設開啟，可在閱讀設定關閉）：上下滾動接近話尾時抓下一話接在列表後方，兩話間有「第 N 話」分隔；捲進哪一話就切換章節、進度、吐槽與已讀。拉到底若下一話已接上則直接捲過去；接不上（VIP、最後一話、載入失敗）照舊換話。索引換算放在 `continuous_chapters.dart`。
- 「讀完」判斷改為按章節記錄，避免連續閱讀時各話互相影響。

## 驗證

- 本機：analyze 0 error／0 warning（13 則既有 info）；239 項測試全部通過（新增：索引換算 3 項、縮放元件 3 項）。縮放以元件測試模擬兩指捏合驗證。
- MuMu（1920×1080 橫向）：《8级魔法师的回归》第 09 話一路往下滑直接進入第 10 話，中間沒有載入畫面，狀態列跟著換成第 10 話；分隔條顯示正常；往回滑回第 09 話，狀態列也切回。截圖在 `docs/images/continuous-reader/`。
- 未驗證：實機雙指縮放手感（模擬器 adb 無法做兩指手勢）、iOS／Windows 實際操作。

## 發布檢查

- Tag `v2.6.0` 指向 `03526c1`；先建草稿，CI 上傳產物核對後公開。版本說明依使用者提供的文案（簡體、附 issue 連結）。
- [正式 CI 44044354498](https://github.com/funkeyyou/zaimanhua/actions/runs/44044354498)：分析、測試、Android／Windows／iOS 建置與上傳全部成功。
- 產物大小與 SHA-256 與 Release digest 一致：
  - `ZAI-X-android.apk`：93082507 bytes，`e076d80acb6a8e5869aba7da59454f150a4f307b94df6ca133378645ec5f2596`
  - `ZAI-X-windows-x64.zip`：32147607 bytes，`91f2e7d05804825af16ffb6fc37b7f6b3ff93f9accb3491dca6c4e9c71f11985`
  - `ZAI-X-ios-unsigned.ipa`：27542122 bytes，`58f491fbae15e606cc2b830bc879d09f96ab006adcd5281479cdafe4b92745bf`
- APK：versionName 2.6.0、versionCode 26000，簽章與前版相同。
- 依使用者要求，自本版起不再刪除舊 Release；v2.5.0 保留。
