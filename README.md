# 再漫畫

本倉庫是 [Fusn126/ZAI_X](https://github.com/Fusn126/ZAI_X)（再漫画第三方客戶端，源自 [xiaoyaocz/flutter_dmzj](https://github.com/xiaoyaocz/flutter_dmzj)）的個人迭代分支，**安卓優先開發，功能再同步 Windows 版**。

## 本分支新增功能

- **界面語言切換**：跟隨系統／簡體／繁體（台灣用語），切換即時生效
- **內容即時簡轉繁**：漫畫標題、資訊內文、小說正文、評論等伺服器內容依語言設定顯示（OpenCC 全量詞表，最長詞優先）
- **翻頁觸控區寬度可調**：左右各 5–40%（上游 issue #157）
- **閱讀時螢幕常亮**（可關）；**閱讀器內亮度調節**（安卓/iOS，退出自動還原）
- **每日自動簽到**：App 內建 + 獨立排程工具（`tools/auto_signin`，不開 App 也能簽）
- Android 正式簽名發佈、CI 自動出包（見 [Releases](../../releases)）

- 開發路線：[docs/ROADMAP.md](docs/ROADMAP.md)
- 每日自動簽到工具（不開 App 也能簽）：[tools/auto_signin](tools/auto_signin)
- 建置：Flutter 3.38.10（CI 舊檔寫的 3.22 已過時）；Windows 本機建置請走 ASCII 路徑（中文路徑會使原生建置步驟讀壞檔案，可用 `mklink /J` 建 junction）
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
