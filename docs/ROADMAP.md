# 再漫畫（ZAI-X fork）功能路線圖

基底：[Fusn126/ZAI_X](https://github.com/Fusn126/ZAI_X)（已完成 zaimanhua.com API 遷移），源自 [xiaoyaocz/flutter_dmzj](https://github.com/xiaoyaocz/flutter_dmzj)。

**開發原則：安卓優先。功能先在安卓落地，下一步再同步驗證 Windows 版。**

## P0 基礎設施（先讓迭代循環轉起來）

- [x] 自有 GitHub 倉庫 + CI（tag 觸發自動出 APK 與 Windows zip；無 secrets 時自動退回 debug 簽名）
- [x] Android 正式簽名金鑰（keystore 位於 C:\Users\funke\keys，密碼與 base64 已存入 repo secrets；**務必備份，遺失則無法更新已安裝的 App**）
- [x] 本機 Android 開發環境（JDK 17.0.20.1 + Android SDK 36 + build-tools 36.0.0，flutter 已指向）
- [ ] App 內更新檢查指向本倉庫的 `document/app_version.json`（需倉庫轉 public，或另尋可公開存取的位置）

## P1 快速勝利（小工作量、立即有感）

- [x] App 內自動簽到（ZAI_X 已內建：啟動時已登入且未簽到就自動簽）
- [x] 獨立自動簽到工具（不開 App 也能簽）：`tools/auto_signin/`，支援本機排程與 GitHub Actions 每日 cron 兩種跑法
- [x] 繁體中文介面——**執行期切換**（設定→界面语言：跟隨系統/簡/繁，預設跟隨系統）。做法：源碼字面量保持簡體（貼近上游），codemod 為 UI 字串加 `.i18n` 後綴，`tools/i18n/gen_dict.py` 以 OpenCC s2twp 生成整句對照表（`lib/app/i18n_dict.g.dart`），插值字串走逐字備援。新增 UI 字串後重跑 gen_dict；合併上游後重跑 `tools/i18n/apply_i18n.py` + `fix_const.py`
- [x] 內容（分類/標題/資訊內文/小說正文/評論）即時簡轉繁：OpenCC 全量詞表 42,620 條、最長詞優先，隨界面語言設定生效
- [x] 「我的」頁每日簽到入口（顯示今日狀態，可手動簽到）
- [ ] 簽到結果通知（安卓通知列 / Windows toast）

## P2 閱讀體驗（安卓優先）

- [x] 觸控翻頁區域自訂（上游 issue #157）：設定→漫画→翻頁觸控區寬度，左右各 5–40%（預設 10% 同舊版），即時生效
- [ ] 平板／橫屏雙頁模式
- [x] 保持螢幕常亮（設定→常規，預設開啟；漫畫/小說閱讀器進入生效、退出釋放，wakelock_plus 全平台）
- [x] 閱讀器內亮度調節（安卓/iOS）：閱讀器設定面板頂部滑桿＋「跟隨系統」還原鈕；應用級亮度，退出閱讀自動還原（screen_brightness）
- [ ] 卷末自動銜接下一話的順滑度優化
- [ ] E-ink 模式打磨（ZAI_X 已加入基本版）

## P3 收藏與跨裝置同步

- [ ] 驗證並修復雲端閱讀進度同步（安卓看到哪、Windows 接著看）
- [ ] 訂閱清單分組／排序改進
- [ ] 本地收藏、閱讀紀錄匯出／匯入

## P4 下載與離線

- [ ] 驗證 1.06「修復漫画下载失败」之後的批量下載穩定性
- [ ] 已下載內容匯出為 cbz／資料夾
- [ ] 僅 Wi-Fi 下載選項（安卓）

## P5 技術債（穿插進行）

- [ ] Flutter 3.38.10 → 3.47 升級；90 個被舊約束卡住的過時套件逐步更新
- [ ] CI 加入 `flutter analyze` 作為合併門檻
- [x] CI actions 升版（checkout/upload-artifact v7、setup-java v6），棄用警告歸零
- [x] 內建思源黑體 Medium 裁剪版（12.8 MB）：部分安卓 ROM 無視 Flutter 字重請求，主題層 w500/w600 不足以解決，改為內建字體
- [ ] Windows 非 ASCII 路徑建置問題：文件化 junction 做法（`C:\Users\funke\zmh`），或向 Flutter 上游回報

## 維護原則

- 定期合併上游 Fusn126/ZAI_X 的新 commit（remote `zaix`），保留 xiaoyaocz 主線 remote 以便對照
- 遵守 GPL-3.0：保留原作者署名與授權，禁止商業用途
- 每個功能：安卓實測 → Windows 實測 → 才進 tag 發版
