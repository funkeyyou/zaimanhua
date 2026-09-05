# 再漫畫（ZAI-X fork）功能路線圖

基底：[Fusn126/ZAI_X](https://github.com/Fusn126/ZAI_X)（已完成 zaimanhua.com API 遷移），源自 [xiaoyaocz/flutter_dmzj](https://github.com/xiaoyaocz/flutter_dmzj)。

**開發原則：安卓優先。功能先在安卓落地，下一步再同步驗證 Windows 版。**

## P0 基礎設施（先讓迭代循環轉起來）

- [x] 自有 GitHub 倉庫 + CI（tag 觸發自動出 APK 與 Windows zip；無 secrets 時自動退回 debug 簽名）
- [x] Android 正式簽名金鑰（keystore 位於 C:\Users\funke\keys，密碼與 base64 已存入 repo secrets；使用者已於 2026-09-05 完成備份）
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
- [x] App 內一鍵更新：檢查到新版直接在 App 內下載，安卓喚起系統安裝器（需「安裝未知來源應用」權限），Windows 下載 zip 後在檔案總管選取；失敗自動退回瀏覽器
- [x] 搜尋歷史與建議：官方熱門搜尋接口已 404，改用本機資料——搜尋歷史（最多 20 筆、可單刪可清空）＋依輸入比對閱讀紀錄與本地收藏的作品，點了直接進詳情
- [x] 閱讀統計：本機累計每日話數與閱讀時長（漫畫／小說分開），「我的」新增入口，含今天／最近 7 天／總計、連續閱讀天數與 7 天長條圖，可一鍵清空
- [x] 任務中心與自動領取：官方 H5 走 task/list 與 task/get_reward 兩個 GET（與簽到同一個 lpi 服務），已接成任務清單＋手動／全部領取，設定開啟時啟動登入後自動領。欄位命名無公開文件，解析同時容納 snake_case 與 camelCase，長按任務可看原始 JSON

## P2 閱讀體驗（安卓優先）

- [x] 觸控翻頁區域自訂（上游 issue #157）：設定→漫画→翻頁觸控區寬度，左右各 5–40%（預設 10% 同舊版），即時生效
- [x] 平板／折疊機雙頁對開（v1.3.0）：關閉／寬屏／總是，右到左時前頁在右，封面可單獨成頁；條漫與上下捲動不適用
- [x] 在第一頁往前翻改為跳到上一話最後一頁（v1.3.0）
- [x] 保持螢幕常亮（設定→常規，預設開啟；漫畫/小說閱讀器進入生效、退出釋放，wakelock_plus 全平台）
- [x] 閱讀器內亮度調節（安卓/iOS）：閱讀器設定面板頂部滑桿＋「跟隨系統」還原鈕；應用級亮度，退出閱讀自動還原（screen_brightness）
- [x] 卷末自動銜接下一話的順滑度優化（剩最後 3 頁時預抓下一話內容與前兩頁圖，換話跳過整屏 loading）
- [x] E-ink 模式打磨（翻頁動畫、圖片淡入、頁面轉場全部關閉，音量鍵翻頁）
- [x] 繼續閱讀進度可靠性：末頁不再被誤判為越界而回到第 1 頁；載入中退出、延遲回應與吐槽頁也不會覆蓋正確進度
- [x] 已讀章節標記：新開 ZaiComicReadChapter 記錄每部漫畫看過的話，詳情頁把看過的變淡、長按可切換已讀／未讀、批次標到某一話為止或清空；舊資料以歷史裡的最後一話回填

## P3 收藏與跨裝置同步

- [x] 雲端閱讀進度同步：漫畫與小說的秒／毫秒比較錯誤都已修復，舊遠端進度不再覆蓋較新的本地進度；啟動時的 `syncRemoteHistory()` 改由 `main.initServices()` 在 DBService 就緒後觸發（UserService 比 DBService 早初始化，寫在 `init()` 會撞上還沒開的 Hive box）
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
- [x] permission_handler 12 → 13.0.2：AGP 8.11.1 + Kotlin 2.2.20 已滿足其建置需求，另把 `compileSdk` 提到 37（permission_handler_android 14 要求）
- [x] flutter_smart_dialog 5.3.0、lottie 3.5.1、wakelock_plus 1.8.0（原本只是被 pubspec.lock 鎖住）
- [x] protobuf 3.1 → 6.0：舊生成碼不相容（`PbList` 無名建構子），以 protoc 36.1 + protoc_plugin 25 依 `assets/proto` 重生；三份 descriptor 的 154 個欄位（名稱/編號/label/型別）與舊版逐項比對一致，另加 wire 格式解碼測試把關
- [ ] build_runner 2.4.13 → 2.16 仍卡住：hive_generator 2.0.1 綁 `source_gen ^1.0.0`、`analyzer <7`，且已停止維護；要動就得改用社群分支（hive_ce）或自行維護 adapter
- [x] CI Windows 建置改回 `windows-latest`（VS2026）：C++/WinRT 在 C++17 模式仍引用 `<experimental/coroutine>`，以 `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` 抑制 STL1011
- [ ] 待 permission_handler_windows 改走 C++20 `<coroutine>` 後，移除 `windows/CMakeLists.txt` 的抑制巨集（微軟已預告該標頭會移除）
- [ ] 任務中心欄位待實機核對：目前 task/list 的欄位名是依常見寫法推測，領獎也同時帶 task_id／taskId／id 三種參數。登入後長按任務看原始 JSON，就能把解析收斂成確定的欄位
- [x] CI 加入 analyze + test 門檻（`flutter analyze --no-fatal-infos`，Android/Windows 建置都要等它通過）
- [x] CI actions 升版（checkout/upload-artifact v7、setup-java v6），棄用警告歸零
- [x] 內建思源黑體 Medium 裁剪版（12.8 MB）：部分安卓 ROM 無視 Flutter 字重請求，主題層 w500/w600 不足以解決，改為內建字體
- [x] Windows 非 ASCII 路徑：README 寫上 junction 做法（`C:\Users\funke\zmh`）。除了原生建置，`flutter analyze` 在中文路徑下也會因 LSP 訊息長度算錯而丟 `FormatException`

## 維護原則

- 定期合併上游 Fusn126/ZAI_X 的新 commit（remote `zaix`），保留 xiaoyaocz 主線 remote 以便對照
- 遵守 GPL-3.0：保留原作者署名與授權，禁止商業用途
- 每個功能：安卓實測 → Windows 實測 → 才進 tag 發版
- 本機建置與 analyze 走 ASCII junction（`C:\Users\funke\zmh`）；Windows 端本機缺 ATL，最終以 CI 產物驗收

## 版本紀錄

- v1.7.2：小說端遠端紀錄不再覆蓋較新的本地進度、啟動時同步遠端閱讀歷史；protobuf 6（重生成生成碼）、permission_handler 13（compileSdk 37）、flutter_smart_dialog 5.3、lottie 3.5.1、wakelock_plus 1.8 升級；CI Windows 改回最新映像
- v1.7.1：修復漫畫退出後繼續閱讀偶爾回到該話第 1 頁；末頁、吐槽頁、載入中退出與延遲回應均不再覆蓋正確進度，並修正漫畫遠端／本地進度的新舊判斷
- v1.7.0：補齊 18 個官方隱藏漫畫標籤、修復隱藏標籤與狀態／地區篩選、自製分類封面
- v1.6.0：書架排序／篩選改為整批準備後呈現、已下載章節匯出 cbz、續傳重複頁修復、閱讀器按鍵補強、CI analyze/test 門檻、Flutter 3.47.2 與依賴升級
- v1.5.0：簽到結果通知、卷末預先載入下一話、方向鍵只翻頁不換話、E-Ink 取消頁面轉場、開源主頁指向本倉庫
- v1.4.1：閱讀器返回不再連帶關掉選集頁、頁面轉場改滑動消除空白閃爍、App 內更新檢查可用、關於視窗與伺服器板塊標題跟隨簡繁設定
- v1.4.0：書架分頁、訂閱排序升降序與題材標籤篩選、訂閱更新提醒、折疊機推薦區塊填滿、desugaring 修復
- v1.3.0：雙頁對開、上一話最後一頁、安卓資訊改走可轉換的渲染路徑、底部導航文字標籤
- v1.2.0：內建思源黑體、翻頁觸控區可調、螢幕常亮、閱讀器亮度、每日簽到入口
- v1.1.0：界面語言執行期切換、伺服器內容即時簡轉繁、Android 正式簽名
