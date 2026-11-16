# v2.5.0 發版紀錄

日期：2026-11-17。版本：`2.5.0+25000`。狀態：[已正式發布](https://github.com/funkeyyou/zaimanhua/releases/tag/v2.5.0)，發布時間 02:24:28（UTC+8）。

範圍：條漫寬度設定（方形摺疊屏）。對外說明見 [版本說明](releases/v2.5.0.md)。

## 改動

- 新增「条漫宽度」：鋪滿／自動／自訂（40%～100%）。自動模式在畫面寬高比 ≥ 0.7（方形摺疊屏展開、平板、橫屏）時收窄到 9:16 寬度，直板手機維持鋪滿；預設為自動。計算放在 `vertical_page_width.dart`，附 5 項測試。
- 圖片收窄後置中，兩側空白仍屬於同一個捲動列表，可以直接滑動。
- 閱讀器左右點擊翻頁區原本用帶顏色的透明 `Container`，會吃掉觸控，底下的列表收不到滑動；改成 `SizedBox.expand()`，只接點擊。橫向翻頁模式的左右滑動不受影響。

## 驗證

- 本機：analyze 0 error／0 warning（13 則既有 info）；230 項測試全部通過。
- MuMu 模擬 Galaxy Z Fold 內屏（1812×2176、DPI 420、直向）：自動模式收窄置中；左側空白上滑可捲動；點中間叫出選單；點右側往下翻頁；自訂 70% 正常。截圖在 `docs/images/fold-reader/`。
- 未驗證：實體摺疊機、iOS／iPad、Windows 視窗縮放下的實際手感。

## 發布檢查

- Tag `v2.5.0` 指向 `2cc9bb4`，與 `zaimanhua` 主分支一致；先建草稿，CI 上傳產物核對後公開。
- [正式 CI 43926298065](https://github.com/funkeyyou/zaimanhua/actions/runs/43926298065)：分析、測試、Android／Windows／iOS 建置與上傳全部成功。
- 產物大小與 SHA-256 與 Release digest 一致：
  - `ZAI-X-android.apk`：92983699 bytes，`567a2504125d367009d67f71dfcff1a75faa8cd77595417c9480b07ec4d0b8c5`
  - `ZAI-X-windows-x64.zip`：32136896 bytes，`de13c773f26808658780057c2066fb6d8d67265d677cfd1744432568a5c362d8`
  - `ZAI-X-ios-unsigned.ipa`：27528605 bytes，`ebb556f4d0e2d38694b5580dd283150446e1a274e1b8a5dbb83a1ce4f4d0b0b8`
- APK：versionName 2.5.0、versionCode 25000，簽章 SHA-256 `4e2f8407…b222` 與前版相同。
- 匿名 latest API 回傳 v2.5.0。v2.4.1 產物已備份在 `build/release-2.4.1/current/` 並核對一致，舊 Release 已刪除、tag 保留。
