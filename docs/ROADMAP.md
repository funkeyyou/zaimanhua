# 再漫畫（ZAI-X fork）功能路線圖

基底：[Fusn126/ZAI_X](https://github.com/Fusn126/ZAI_X)（已完成 zaimanhua.com API 遷移），源自 [xiaoyaocz/flutter_dmzj](https://github.com/xiaoyaocz/flutter_dmzj)。

**開發原則：安卓優先。功能先在安卓落地，下一步再同步驗證 Windows 版。**

## P0 基礎設施（先讓迭代循環轉起來）

- [x] 自有 GitHub 倉庫 + CI（tag 觸發自動出 APK 與 Windows zip；無 secrets 時自動退回 debug 簽名）
- [x] Android 正式簽名金鑰（keystore 位於 C:\Users\funke\keys，密碼與 base64 已存入 repo secrets；**務必備份，遺失則無法更新已安裝的 App**）
- [x] 本機 Android 開發環境（JDK 17.0.20.1 + Android SDK 36 + build-tools 36.0.0，flutter 已指向）
- [x] App 內更新檢查改讀本倉庫的 GitHub Release（`api.github.com/repos/funkeyyou/zaimanhua/releases/latest`，自動依平台挑 apk／zip 資產）；倉庫已於 v1.4.1 轉為 public，API 可匿名存取

## P1 快速勝利（小工作量、立即有感）

- [x] App 內自動簽到（ZAI_X 已內建：啟動時已登入且未簽到就自動簽）
- [x] 獨立自動簽到工具（不開 App 也能簽）：`tools/auto_signin/`，支援本機排程與 GitHub Actions 每日 cron 兩種跑法
- [x] 繁體中文介面——**執行期切換**（設定→界面语言：跟隨系統/簡/繁，預設跟隨系統）。做法：源碼字面量保持簡體（貼近上游），codemod 為 UI 字串加 `.i18n` 後綴，`tools/i18n/gen_dict.py` 以 OpenCC s2twp 生成整句對照表（`lib/app/i18n_dict.g.dart`），插值字串走逐字備援。新增 UI 字串後重跑 gen_dict；合併上游後重跑 `tools/i18n/apply_i18n.py` + `fix_const.py`
- [x] 內容（分類/標題/資訊內文/小說正文/評論）即時簡轉繁：OpenCC 全量詞表 42,620 條、最長詞優先，隨界面語言設定生效
- [x] 「我的」頁每日簽到入口（顯示今日狀態，可手動簽到）
- [x] 訂閱更新提醒（安卓通知列）：Workmanager 週期檢查 + App 啟動前景檢查 + 「立即檢查」自測按鈕；狀態以 subscribe_notify.json 在主進程與背景 isolate 間交換（不共用 Hive box）
- [x] 簽到結果通知（安卓通知列 / Windows toast；設定可關，同一天只發一次）

## P2 閱讀體驗（安卓優先）

- [x] 觸控翻頁區域自訂（上游 issue #157）：設定→漫画→翻頁觸控區寬度，左右各 5–40%（預設 10% 同舊版），即時生效
- [x] 平板／折疊機雙頁對開（v1.3.0）：關閉／寬屏／總是，右到左時前頁在右，封面可單獨成頁；條漫與上下捲動不適用
- [x] 在第一頁往前翻改為跳到上一話最後一頁（v1.3.0）
- [x] 保持螢幕常亮（設定→常規，預設開啟；漫畫/小說閱讀器進入生效、退出釋放，wakelock_plus 全平台）
- [x] 閱讀器內亮度調節（安卓/iOS）：閱讀器設定面板頂部滑桿＋「跟隨系統」還原鈕；應用級亮度，退出閱讀自動還原（screen_brightness）
- [x] 卷末自動銜接下一話的順滑度優化（剩最後 3 頁時預抓下一話內容與前兩頁圖，換話跳過整屏 loading）
- [x] E-ink 模式打磨（翻頁動畫、圖片淡入、頁面轉場全部關閉，音量鍵翻頁）

## P3 收藏與跨裝置同步

- [ ] 雲端閱讀進度同步：實測正常（打開「歷史記錄」時拉取遠端並合併）。待處理：`DBService.syncRemoteComicHistory`／`syncRemoteNovelHistory` 比對新舊時本地用秒、遠端用毫秒，離線讀完且上傳失敗時會被舊進度覆蓋；另 `UserService` 啟動時的 `syncRemoteHistory()` 目前是註解狀態
- [x] 書架分頁（底部導航常駐我的訂閱）
- [x] 訂閱排序升／降序（訂閱時間、更新時間）＋ 題材標籤篩選（標籤由漫畫詳情補抓並快取於 SubscribeTagsCache）
- [ ] 本地收藏、閱讀紀錄匯出／匯入

## P4 下載與離線

- [x] 批量下載穩定性：修掉續傳時同一頁被記兩次（`files` 重複造成離線閱讀重複頁）
- [x] 已下載內容匯出為 cbz（下載詳情頁 → 編輯 → 選章節 → 匯出；桌面選資料夾、行動裝置走系統分享）
- [x] 僅 Wi-Fi 下載：設定頁「允許使用流量下載」關閉即為僅 Wi-Fi，切到流量會自動暫停

## P5 技術債（穿插進行）

- [x] Flutter 3.38.10 → 3.47.2 升級（本機與 CI 同步）；analyze 零錯誤、Android 建置與模擬器實測通過
- [x] 依賴升級：package_info_plus 10、share_plus 13、image_gallery_saver_plus 5、wakelock_plus 1.6、windows_single_instance 1.2，其餘鎖定版本內更新
- [ ] permission_handler 13：其 Android 端要求較新的 Kotlin/AGP 設定（`compilerOptions` DSL），需先整理 android/build.gradle 才能升
- [ ] 其餘過時套件（flutter_smart_dialog 5.3、lottie、intl、protobuf 6 等）受相依約束卡住，待上游放寬
- [x] CI 加入 analyze + test 門檻（`flutter analyze --no-fatal-infos`，Android/Windows 建置都要等它通過）
- [x] CI actions 升版（checkout/upload-artifact v7、setup-java v6），棄用警告歸零
- [x] 內建思源黑體 Medium 裁剪版（12.8 MB）：部分安卓 ROM 無視 Flutter 字重請求，主題層 w500/w600 不足以解決，改為內建字體
- [ ] Windows 非 ASCII 路徑建置問題：文件化 junction 做法（`C:\Users\funke\zmh`），或向 Flutter 上游回報

## 維護原則

## 版本紀錄

- v1.4.0：書架分頁、訂閱排序升降序與題材標籤篩選、訂閱更新提醒、折疊機推薦區塊填滿、desugaring 修復
- v1.4.1：閱讀器返回不再連帶關掉選集頁、頁面轉場改滑動消除空白閃爍、App 內更新檢查可用、關於視窗與伺服器板塊標題跟隨簡繁設定
- v1.5.0：簽到結果通知、卷末預先載入下一話、方向鍵只翻頁不換話、E-Ink 取消頁面轉場、開源主頁指向本倉庫
- v1.3.0：雙頁對開、上一話最後一頁、安卓資訊改走可轉換的渲染路徑、底部導航文字標籤
- v1.2.0：內建思源黑體、翻頁觸控區可調、螢幕常亮、閱讀器亮度、每日簽到入口
- v1.1.0：界面語言執行期切換、伺服器內容即時簡轉繁、Android 正式簽名

- 定期合併上游 Fusn126/ZAI_X 的新 commit（remote `zaix`），保留 xiaoyaocz 主線 remote 以便對照
- 遵守 GPL-3.0：保留原作者署名與授權，禁止商業用途
- 每個功能：安卓實測 → Windows 實測 → 才進 tag 發版
