# 再漫畫

本倉庫是 [Fusn126/ZAI_X](https://github.com/Fusn126/ZAI_X)（再漫画第三方客戶端，源自 [xiaoyaocz/flutter_dmzj](https://github.com/xiaoyaocz/flutter_dmzj)）的個人迭代分支，**安卓優先開發，功能再同步 Windows 版**。

## 下載

[Releases](../../releases) 提供安卓 APK 與 Windows 免安裝壓縮檔。App 內「我的 → 檢查更新」讀的也是同一處。

## 本分支新增功能

### 語言

- **界面語言切換**：跟隨系統／簡體／繁體（台灣用語），切換即時生效，不需重開 App
- **伺服器內容即時簡轉繁**：漫畫標題、資訊內文、小說正文、評論、板塊標題、題材標籤（OpenCC s2twp 全量詞表，最長詞優先）
- **內建思源黑體 Medium**：解決安卓預設中文字重過細、閱讀吃力

### 閱讀器

- **雙頁對開**：折疊機展開與平板橫向自動啟用，可強制開關，封面可單獨成頁
- **卷末預先載入下一話**：讀到剩最後三頁時先抓好內容與前兩頁圖，換話不必再等整屏 loading
- **第一頁往前翻**：回到上一話的最後一頁，而不是第一頁
- **翻頁觸控區寬度可調**：左右各 5–40%（上游 issue #157）
- **鍵盤翻頁**：←／→ 與 PageUp／PageDown 單純翻頁，翻到頭尾才換話
- **閱讀時螢幕常亮**（可關）、**閱讀器內亮度調節**（安卓／iOS，退出自動還原）
- **E-Ink 模式**：關閉翻頁動畫、頁面轉場與圖片淡入，開啟音量鍵翻頁

### 書架與訂閱

- **書架分頁**：底部導航常駐入口，直接看我的訂閱
- **訂閱排序與篩選**：訂閱時間／更新時間，升冪降冪；題材標籤篩選（標籤由漫畫詳情補抓並快取）
- **訂閱更新提醒**：背景週期檢查，有新話發通知

### 其他

- **每日自動簽到**：App 內建並回報結果通知；另有獨立排程工具（[tools/auto_signin](tools/auto_signin)，不開 App 也能簽）
- **App 內更新檢查**：直接讀本倉庫的 GitHub Release，依平台挑安裝檔
- **底部導航文字標籤**、折疊機與寬螢幕的多欄排版適配
- Android 正式簽名發佈、CI 自動出包

## 開發

- Flutter 3.38.10（CI 設定檔裡若見 3.22 為過時資訊）
- Windows 本機建置請走 ASCII 路徑：中文路徑會讓原生建置步驟讀壞檔案，可用 `mklink /J` 建 junction
- 新增中文 UI 字串後執行 `tools/i18n/gen_dict.py` 重建簡繁對照表；合併上游後另跑 `tools/i18n/apply_i18n.py`
- 開發路線：[docs/ROADMAP.md](docs/ROADMAP.md)
- 授權：GPL-3.0，保留原作者署名，禁止商業用途

以下為 ZAI_X 原 README：

---

本家app的摇一摇广告太烦人了，这个改版原作者太久没更新，所以就自己fork大修了下。
</br>
自己在用，基本功能应该正常，因为改了flutter版本可能会有兼容问题就不往原来的代码仓合并了。
</br>
现在只有android和windows版本，ios和mac因为没有设备需要自己拉源码编译。下面是原来的readme：

---

<p align="center">
    <img width="128" src="/document/logo.png" alt="DMZJX logo">
</p>
<h2 align="center">ZAI-X</h2>

<p align="center">
使用Flutter编写的再漫画跨平台第三方客户端
</p>

![浅色模式](/document/screenshot_light.jpg)

![深色模式](/document/screenshot_dark.jpg)

## 支持平台

- [x] Android
- [x] iOS
- [x] Windows `Beta`
- [x] MacOS `Beta`
- [x] Linux `Beta`

请到[Releases](https://github.com/xiaoyaocz/flutter_dmzj/releases)下载最新版本，iOS请下载ipa文件自行签名安装。

反馈问题、相关讨论请到[Discussions](https://github.com/xiaoyaocz/flutter_dmzj/discussions)，代码改进请直接提交PR。

## 声明

- 本项目为[再漫画](https://zaimanhua.com)第三方开源APP

- 本项目仅用于学习交流编程技术，严禁将本项目用于商业目的。如有任何商业行为，均与本项目无关。

- 本项目内所有资源版权均归属于其著作者或动漫之家所有

- 如果本项目存在侵犯您的相关权益的情况，请及时与开发者联系，开发者将会及时删除有关内容。

## License

[GPL-3.0 License](https://github.com/xiaoyaocz/flutter_dmzj/blob/main/LICENSE)，禁止用于任何商业用途
