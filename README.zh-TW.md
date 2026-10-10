# 再漫畫X（ZAI-X）

[简体中文](README.md) · [繁體中文](README.zh-TW.md) · [English](README.en.md) · [下載 Releases](https://github.com/funkeyyou/zaimanhua/releases/latest) · [問題回報](https://github.com/funkeyyou/zaimanhua/issues)

**再漫畫（zaimanhua.com）的第三方客戶端，Android、iOS 與 Windows 都能用。**

再漫畫第三方客戶端：看漫畫、輕小說與資訊，支援 AI 搜尋、神隱漫畫、雙頁閱讀與每日自動簽到。
Unofficial Zaimanhua (再漫畫) client for Android, iOS and Windows: manga, light novels and news.

- **AI 搜尋**：用一句話描述想看的作品，例如「女主很強的奇幻冒險」「類似《葬送的芙莉蓮》的作品」，AI 讀過簡介後挑出符合的漫畫或輕小說，並寫上推薦理由。
- **找得到神隱作品**：官方搜尋找不到的神隱、下架漫畫，由內建的本地索引補上，詳情與完整章節都能開啟。
- **大螢幕也好讀**：折疊機與平板自動雙頁對開、多欄排版；Windows 支援鍵盤翻頁，也能在 App 內自動更新。
- **書架與閱讀進度**：依更新時間排序、篩出有未讀更新的作品，閱讀進度與再漫畫帳號同步。
- **打開 App 自動簽到**：登入後打開 App，當天還沒簽到就會自動完成每日簽到，並領取已達成的任務獎勵；簽到結果會用系統通知告訴你。

| 首頁 | 書架：最近閱讀與未讀更新 | 我的：打開 App 已自動簽到 |
| :---: | :---: | :---: |
| <img src="docs/images/home.jpg" alt="漫畫首頁：推薦輪播、我的書架與近期必看" width="240"> | <img src="docs/images/bookshelf.jpg" alt="書架：最近閱讀顯示上次的章節與頁碼，訂閱作品標出未讀更新" width="240"> | <img src="docs/images/profile.jpg" alt="我的：每日簽到顯示「已簽到」，頭像與暱稱已打碼" width="240"> |

| AI 搜尋：讀完簡介再推薦 | 神隱作品：完整章節 |
| :---: | :---: |
| <img src="docs/images/ai-search.jpg" alt="AI 搜尋：輸入「類似《葬送的芙莉蓮》的作品」，AI 讀了 45 部作品的簡介並挑出 11 部，每部附上推薦理由" width="240"> | <img src="docs/images/comic-detail.jpg" alt="神隱漫畫《來自深淵》的詳情頁，顯示簡介與 79 話的完整章節列表" width="240"> |

*截圖為 Android 版簡體介面，App 內可切換繁體；「我的」頁的頭像與暱稱已打碼。*

### 開始前需要什麼？

Android 7.0 以上的手機、平板或折疊機，iOS 15 以上的 iPhone／iPad，或是 Windows 10／11（64 位元）電腦。
多數漫畫、輕小說與資訊不登入也能看；訂閱、閱讀進度同步、簽到與部分章節需要再漫畫帳號，在 App 內登入即可。
本專案是非官方的社群作品，與再漫畫、動漫之家沒有隸屬關係。

### 資料從哪裡來？

漫畫、輕小說、資訊、評論與登入都直接連到再漫畫官方接口。官方搜尋找不到的神隱、下架作品，由 App 內建、每天更新的[本地漫畫索引](docs/comic-index.md)補上。
版本更新讀本倉庫的 GitHub Releases，預設經 gh-proxy 加速，連不上時改回 GitHub。
只有使用 AI 功能時才會把內容送往 AI 服務：AI 搜尋送出你輸入的描述，以及候選作品的書名、作者、題材、進度、人氣與簡介；AI 一鍵答題送出題目、選項，以及題目提到的作品在站內的公開資料。兩者都不含帳號或閱讀紀錄。

## 下載與安裝

以下連結都指向[最新版本](https://github.com/funkeyyou/zaimanhua/releases/latest)：

| 平台 | GitHub 直接下載 | 經 gh-proxy 加速 |
| --- | --- | --- |
| Android | [ZAI-X-android.apk](https://github.com/funkeyyou/zaimanhua/releases/latest/download/ZAI-X-android.apk) | [ZAI-X-android.apk](https://gh-proxy.com/https://github.com/funkeyyou/zaimanhua/releases/latest/download/ZAI-X-android.apk) |
| Windows | [ZAI-X-windows-x64.zip](https://github.com/funkeyyou/zaimanhua/releases/latest/download/ZAI-X-windows-x64.zip) | [ZAI-X-windows-x64.zip](https://gh-proxy.com/https://github.com/funkeyyou/zaimanhua/releases/latest/download/ZAI-X-windows-x64.zip) |
| iOS／iPadOS | [加入 TestFlight 測試](https://testflight.apple.com/join/x3N2EgWr) | — |

GitHub 下載太慢時可以改用 gh-proxy（第三方加速服務）；下載後可對照 Release 頁面列出的 SHA-256 確認檔案。

### Android

下載 APK 後點開安裝。第一次安裝時，系統會要求允許安裝未知來源的應用程式。

### iOS／iPadOS（TestFlight）

iOS 版透過 Apple 官方的 TestFlight 發佈，不需要越獄，也不用自己簽名：

1. 在 iPhone 或 iPad 上從 App Store 安裝 [TestFlight](https://apps.apple.com/app/testflight/id899247664)。
2. 用同一台裝置開啟 [ZAI-X 的 TestFlight 公開連結](https://testflight.apple.com/join/x3N2EgWr)，點「接受」，再點「安裝」。
3. 之後從主畫面開啟「再漫画X」就能使用。

- 公開連結有名額上限，額滿時會顯示「此 Beta 版已額滿」，請過幾天再試。
- 每個 TestFlight 版本有效 90 天；有新版時 TestFlight 會通知你，打開 TestFlight 點「更新」即可，書架、紀錄與設定都會保留。
- iOS 的訂閱更新提醒由系統決定何時在背景執行，可能比 Android 慢；打開 App 時一定會檢查一次。
- 想自行安裝也可以：每個 Release 附有未簽名的 `ZAI-X-ios-unsigned.ipa`，用 AltStore、SideStore 或 Sideloadly 以自己的 Apple ID 簽名後安裝（免費 Apple ID 每 7 天要重簽一次）。

### Windows

把 ZIP 解壓到可以寫入的資料夾（例如 `D:\Apps\ZAI-X`），執行 `ZAI-X.exe`。免安裝，也不需要系統管理員權限。

> 不要解壓到 `C:\Program Files` 這類需要管理員權限的位置，否則 App 內更新無法自動覆蓋，只能下載壓縮檔再手動解壓。

## 更新

App 內「我的 → 檢查更新」讀的是同一個 Releases，下載後會核對 SHA-256：

- **Android**：下載後喚起系統安裝器覆蓋安裝，書架、紀錄與設定都會保留。
- **iOS**：由 TestFlight 通知並更新；App 內「檢查更新」只會開啟 Release 頁面。
- **Windows**：v2.2.0 起可在 App 內自動覆蓋更新。App 關閉後換成新版並重新開啟，任何一步失敗都會還原原本的版本。更早的版本請先關閉 App，把新版 ZIP 解壓到原資料夾覆蓋一次。

Windows 版的書架、紀錄、設定與下載內容存在使用者資料夾（AppData），更新或搬動 App 資料夾都不會遺失。

目前最新版是 **v2.4.0**：新增使用者等級頁，題庫認證可以交給 AI 一鍵答題，完整內容見[版本說明](docs/releases/v2.4.0.md)。各版本的更新內容見 [docs/releases](docs/releases) 與 [ROADMAP 的版本紀錄](docs/ROADMAP.md#版本紀錄)。

## 功能

### 搜尋與探索

- **AI 搜尋**：漫畫與輕小說搜尋頁的開關。用一句話描述想看的作品，AI 先整理題材與條件、想出代表作，再從分類、官方搜尋與本地漫畫索引找出候選，讀過簡介後分成「符合」與「可能符合」並附上推薦理由；按「找更多作品」可以繼續往下找。AI 搜尋紀錄與一般搜尋紀錄分開保存
- **神隱作品詳情與章節**：可查看詳情、完整章節與評論；無法閱讀時顯示登入或權限提示
- **本地漫畫索引搜尋**：補上官方搜尋未收錄的作品，內建離線快照並每天檢查更新；可在「我的 → 更多設定 → 漫畫」關閉或手動更新，來源及維護方式見[索引說明](docs/comic-index.md)
- **搜尋歷史與本地建議**：最多 20 筆歷史可單刪可清空；輸入時比對閱讀紀錄與本地收藏，點了直接進詳情
- **專題合集**：首頁「火熱專題」的「漫畫專題大合集」可瀏覽全部專題，各專題列出收錄漫畫、推薦語與訂閱狀態；「訂閱全部」只送還沒訂閱的作品（#3）

### 閱讀器

- **雙頁對開**：折疊機展開與平板橫向自動啟用，可強制開關，封面可單獨成頁
- **卷末預先載入下一話**：讀到剩最後三頁時先抓好內容與前兩頁圖，換話不必再等整屏 loading
- **第一頁往前翻**：回到上一話的最後一頁，而不是第一頁
- **卷末換話像翻頁**：翻到最後一頁再滑一下就換話，不必長拖再放開（上下捲動維持拉一下放開，避免快速捲動誤跳）
- **翻頁觸控區寬度可調**：左右各 5–40%（上游 issue #157）
- **鍵盤翻頁**：←／→ 與 PageUp／PageDown 單純翻頁，翻到頭尾才換話
- **閱讀時螢幕常亮**（可關）、**閱讀器內亮度調節**（安卓／iOS，退出自動還原）
- **E-Ink 模式**：關閉翻頁動畫、頁面轉場與圖片淡入，開啟音量鍵翻頁
- **已讀章節標記**：詳情頁把看過的話變淡，長按可切換已讀／未讀、把某一話以前一次標完或清空整部
- **每部漫畫獨立閱讀設定**：閱讀器內調整方向、雙頁與封面排列只影響目前作品；未調整的選項沿用全局設定，可一鍵恢復全局
- **詳情頁閱讀入口**：明確的開始／繼續閱讀按鈕、上次閱讀區塊與章節進度

### 書架與訂閱

- **書架分頁**：底部導航常駐入口；最上方一列最近閱讀，依螢幕寬度增加作品數並顯示上次章節與頁碼，下方是我的訂閱
- **訂閱排序與篩選**：訂閱時間／更新時間，升冪降冪；題材標籤篩選（標籤由漫畫詳情補抓並快取）
- **更新時間排序修正**：改用接口的 `last_updatetime`（章節 ID 不是全站遞增，官方 App 以外的排法會把剛更新的作品排到後面），並設為預設排序
- **上次更新時間**：作品下方顯示「6小時前」「1天前」，跟官方書架一致
- **訂閱更新提醒**（Android）：背景週期檢查，有新話發通知
- **未讀更新／已追平**：書架可依閱讀進度篩選。點進詳情不再清除提醒，最新一話末頁成功載入且顯示後才算追平；手動標記已讀／未讀也會同步反映
- **書架快取與穩定刷新**：重開 App 先展示上次已排序的清單，再背景更新；失敗保留快取並提供重試。瀏覽中段時以「檢視更新」提示新清單，避免作品突然重排；快取按登入帳號隔離
- **瀏覽紀錄**：從書架右上角進入，本機紀錄可離線查看，登入後可切到雲端紀錄

### 分類與篩選

- **補齊隱藏標籤**：官方分類介面只回 37 個標籤，ゆり、AA、純愛、歷史、戰爭、武俠、機戰、福瑞等 18 個被藏起來；本分支收錄完整的 55 個，並以 [tools/tags](tools/tags) 一鍵重新抓取，不會再放到過期
- **從詳情頁點隱藏標籤能正確篩選**：以前點 ゆり 會掉回「全部漫畫」
- **狀態篩選修復**：原本連載／完結送出的值是錯的（且被寫死），實際完全沒作用
- **地區可與題材疊加**：地區改走獨立參數，例如「日本 × 愛情」
- **篩選面板分組**：排序／狀態／地區／受眾／題材，附一鍵重置
- **自製標籤封面**：18 個官方沒給圖的標籤，改用本倉庫的原創封面（[assets/category](assets/category)）

### 帳號與任務

- **打開 App 自動簽到**：登入後打開 App，當天還沒簽到就會自動簽到，並用系統通知（Windows 為桌面通知）告訴你結果，一天只提醒一次，可在設定裡的「簽到結果通知」關閉；「我的」頁可以查看今天的簽到狀態，也能手動簽到。不打開 App 也想簽到的話，可以用獨立排程工具（[tools/auto_signin](tools/auto_signin)）。GitHub Actions 的每日 cron 預設停用，要用得先加 `ZMH_USERNAME`／`ZMH_PASSWORD` secrets 與 `ENABLE_DAILY_SIGNIN=1` variable
- **任務中心**：官方每日／新人任務的進度與獎勵，可手動或一次領完；開啟自動領取後，啟動、離開閱讀器、發完評論、訂閱作品或回到前景時都會把已達成的獎勵領掉。（官方「累計觀看十分鐘漫畫」是靠官方 App 的行為日誌統計，本 App 無法達成）
- **使用者等級與 AI 一鍵答題**：點「我的」頁的等級標籤，可以查看目前等級的特權、晉升條件與題庫認證上次的成績。Lv4 升 Lv5 的「終極試煉之【題庫認證】」可以交給 AI 作答：AI 先查詢題目提到的作品在站內的資料，沒把握的題目再想一次，一兩分鐘答完 50 題；可以選擇交卷前先檢查、修改答案。答案由 AI 判斷，不保證過關，每台裝置每天 5 次
- **個人資料編輯**：暱稱（含官方可否修改與重複檢查）、個性簽名、性別、生日、所在地。頭像官方接口不開放，仍需在官方 App 更換
- **閱讀統計**：本機累計每日話數與閱讀時長，含今天／最近 7 天／總計、連續閱讀天數與 7 天長條圖，不上傳

### 介面、語言與大螢幕

- **界面語言切換**：跟隨系統／簡體／繁體（台灣用語），切換即時生效，不需重開 App
- **伺服器內容即時簡轉繁**：漫畫標題、資訊內文、小說正文、評論、板塊標題、題材標籤（OpenCC s2twp 全量詞表，最長詞優先）
- **內建思源黑體 Medium**：解決安卓預設中文字重過細、閱讀吃力
- **大螢幕適配**：寬螢幕主頁使用完整寬度，空間足夠時詳情頁並排；折疊與展開保留捲動位置；首頁、專題與分類依寬度增加欄數；底部導航附文字標籤
- **效能**：封面依顯示尺寸解碼，閱讀器正文保留完整解析度；離線圖片改用檔案圖片快取；載入完成後移除隱藏的讀取動畫，未顯示分頁暫停動畫計時

### 更新與發佈

- **App 內一鍵更新**：檢查與下載優先經 gh-proxy 加速，失敗接回 GitHub；APK／ZIP 下載後核對 SHA-256。安卓喚起系統安裝器；Windows 自動覆蓋安裝資料夾並重新開啟，失敗時還原原版本（安裝在無法寫入的位置時，改為下載壓縮檔後在檔案總管選取）
- Android 正式簽名發佈、CI 自動出包

## 常見問題

### 搜尋不到某部作品？

官方搜尋不收錄神隱與下架作品，App 會在搜尋結果上方另外列出本地漫畫索引找到的作品；索引可以在「我的 → 更多設定 → 漫畫」手動更新。
知道作品 ID 的話（網頁版網址 `manhua.zaimanhua.com/details/` 後面的數字），關閉 AI 搜尋後在漫畫搜尋框輸入這串數字，確認跳轉就能開啟該作品。

### 章節打不開，或是顯示「漫畫不存在」？

v2.2.0 起神隱作品也能開啟詳情與章節。仍然無法閱讀時，通常是需要登入或帳號等級不足，詳情頁會說明是哪一種。

### 需要每天手動簽到嗎？

不用。登入後打開 App 就會自動完成當天的簽到，並領取已達成的任務獎勵；當天已經簽過就不會重複簽到。App 一直留在背景的話，要重新開啟一次才會簽到。當天不打算打開 App 的話，可以用 [tools/auto_signin](tools/auto_signin) 在電腦上定時簽到。

### AI 搜尋要付費或自備 API Key 嗎？

不用。從 Releases 下載的版本已內建 AI 服務，每台裝置每天可以搜尋 50 次（按「找更多作品」也算一次），同一段描述 30 分鐘內重搜不另外計次。AI 一鍵答題也使用這個內建服務，每台裝置每天 5 次。AI 服務的額度有限，暫時無法使用時請改用一般搜尋。
自行從原始碼建置時，需要提供自己的服務設定，見[開發](#開發)。

### Windows 自動更新失敗？

先確認 App 放在可以寫入的資料夾。更新失敗時會還原原本的版本，下次啟動會提示結果；仍然失敗的話，關閉 App 後把新版 ZIP 解壓到原資料夾覆蓋即可。

### 有 iOS、macOS 或 Linux 版嗎？

iOS／iPadOS 版透過 TestFlight 提供，安裝方式見[上方說明](#iosipadostestflight)。macOS 與 Linux 目前只保留專案檔，沒有裝置可以測試，需要的話請自行建置。

## 開發

- 開發原則：安卓優先，功能在安卓落地後再同步驗證 Windows 版
- Flutter 3.47.2（本機與 CI 版本需一致）
- Windows 本機開發請走 ASCII 路徑：專案放在含中文的目錄時，原生建置會讀壞檔案，`flutter analyze` 也會因 LSP 訊息長度算錯而丟 `FormatException`。做法是建一個 junction 再從那裡操作：
  ```cmd
  mklink /J C:\dev\zmh "D:\專案\再漫畫"
  ```
  之後 `flutter analyze`／`flutter test`／`flutter build` 都在 `C:\dev\zmh` 下執行（同一份檔案，git 操作留在原路徑即可）。CI 跑在 ASCII 路徑，不受影響
- 新增中文 UI 字串後執行 `tools/i18n/gen_dict.py` 重建簡繁對照表；合併上游後另跑 `tools/i18n/apply_i18n.py`
- AI 搜尋需要 OpenAI 相容的 `/chat/completions` 服務。把設定寫成倉庫外的 JSON，例如 `{"baseUrl": "https://example.com/v1", "apiKey": "...", "model": "..."}`，執行 `dart run tools/ai/make_ai_defines.dart --in <設定.json> --out <ai_defines.json>`，建置時加上 `--dart-define-from-file=<ai_defines.json>`。工具每次以新的隨機遮罩混淆設定；CI 從 `ZAI_AI_CONFIG` secret 讀取同樣格式的 JSON。沒有設定時，搜尋頁不會出現 AI 開關
- 安卓效能診斷：`flutter build apk --profile -t tools/profile_app.dart`，以 `adb logcat -s flutter` 篩選 `ZMH_PROFILE`；每 10 秒輸出幀耗時、圖片快取與記憶體數字，不含帳號或閱讀內容。正式包仍使用 `lib/main.dart`
- 開發路線見 [docs/ROADMAP.md](docs/ROADMAP.md)，每版驗證紀錄在 `docs/QA-v*.md`
- 圖示來源及重建方式見[品牌素材](assets/brand/README.md)，介面驗證結果見 [UI 驗證紀錄](docs/QA-2026-09-09-UI.md)

## 致謝與授權

- 源自 [xiaoyaocz/flutter_dmzj](https://github.com/xiaoyaocz/flutter_dmzj)（動漫之家第三方 Flutter 客戶端），經 [Fusn126/ZAI_X](https://github.com/Fusn126/ZAI_X) 遷移到再漫畫接口，本倉庫在此基礎上持續維護。
- 授權：[GPL-3.0](LICENSE)，保留原作者署名；沿用原專案聲明，禁止用於任何商業用途。

## 聲明

- 本專案是[再漫畫](https://www.zaimanhua.com)的第三方開源 App，與再漫畫、動漫之家沒有隸屬關係。
- 本專案僅供學習交流程式技術，嚴禁用於商業目的；任何商業行為均與本專案無關。
- 作品內容與圖片的版權屬於原作者及再漫畫。
- 如果本專案侵犯了您的權益，請透過 [Issues](https://github.com/funkeyyou/zaimanhua/issues) 聯絡，將盡快處理並刪除相關內容。
