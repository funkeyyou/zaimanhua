# 再漫畫（ZAI-X fork）功能路線圖

基底：[Fusn126/ZAI_X](https://github.com/Fusn126/ZAI_X)（已完成 zaimanhua.com API 遷移），源自 [xiaoyaocz/flutter_dmzj](https://github.com/xiaoyaocz/flutter_dmzj)。

**開發原則：安卓優先。功能先在安卓落地，下一步再同步驗證 Windows 版。**

## P0 基礎設施（先讓迭代循環轉起來）

- [x] 自有 GitHub 倉庫 + CI（tag 觸發自動出 APK 與 Windows zip；無 secrets 時自動退回 debug 簽名）
- [ ] Android 正式簽名金鑰（keystore + repo secrets）——debug 簽名的 APK 每次更新都要先解除安裝才能裝新版，正式金鑰解決此問題
- [ ] 本機 Android 開發環境（JDK 17 + Android SDK，約 2–3 GB，需同意 Google SDK 授權條款）——沒有它也能靠 CI 出包，但改一行程式要等十幾分鐘；裝了才能接手機即時除錯
- [ ] App 內更新檢查指向本倉庫的 `document/app_version.json`（需倉庫轉 public，或另尋可公開存取的位置）

## P1 快速勝利（小工作量、立即有感）

- [x] App 內自動簽到（ZAI_X 已內建：啟動時已登入且未簽到就自動簽）
- [x] 獨立自動簽到工具（不開 App 也能簽）：`tools/auto_signin/`，支援本機排程與 GitHub Actions 每日 cron 兩種跑法
- [x] 繁體中文介面——建置期 OpenCC s2twp 轉換（`tools/s2twp/`）：源碼保持簡體與上游一致，CI 矩陣同時產出簡/繁兩種 APK 與 Windows 包；本機繁體 Windows 版用 `tools/s2twp/build_tc_windows.ps1`
- [ ] 內容（漫畫標題/簡介）簡轉繁顯示切換——需執行期轉換，另行設計
- [ ] 簽到結果通知（安卓通知列 / Windows toast）

## P2 閱讀體驗（安卓優先）

- [ ] 觸控翻頁區域自訂（上游 issue #157，長期未實作的社群願望）
- [ ] 平板／橫屏雙頁模式
- [ ] 閱讀器內亮度調節、保持螢幕常亮
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
- [ ] Windows 非 ASCII 路徑建置問題：文件化 junction 做法（`C:\Users\funke\zmh`），或向 Flutter 上游回報

## 維護原則

- 定期合併上游 Fusn126/ZAI_X 的新 commit（remote `zaix`），保留 xiaoyaocz 主線 remote 以便對照
- 遵守 GPL-3.0：保留原作者署名與授權，禁止商業用途
- 每個功能：安卓實測 → Windows 實測 → 才進 tag 發版
