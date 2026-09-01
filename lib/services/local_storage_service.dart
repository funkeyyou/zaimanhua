import 'package:zai_x/app/log.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

class LocalStorageService extends GetxService {
  static LocalStorageService get instance => Get.find<LocalStorageService>();

  static bool kDebug = false;

  /// 顯示模式
  /// * [0] 跟隨系統
  /// * [1] 淺色模式
  /// * [2] 深色模式
  static const String kThemeMode = "ThemeMode";

  /// 首次執行
  static const String kFirstRun = "FirstRun";

  /// 使用者登入資訊
  /// * 型別：LoginResultModel
  static const String kUserAuthInfo = "UserAuthInfo";

  /// 漫畫閱讀方向
  static const String kComicReaderDirection = "ComicReaderDirection";

  /// 漫畫全屏閱讀
  static const String kComicReaderFullScreen = "ComicReaderFullScreen";

  /// 漫畫閱讀顯示狀態資訊
  static const String kComicReaderShowStatus = "ComicReaderShowStatus";

  /// 漫畫閱讀尾頁顯示觀點/吐槽
  static const String kComicReaderShowViewPoint = "ComicReaderShowViewPoint";

  /// 啟用舊版吐槽
  static const String kComicReaderOldViewPoint = "ComicReaderOldViewPoint";

  /// 小說閱讀方向
  static const String kNovelReaderDirection = "NovelReaderDirection";

  /// 小說字型大小
  static const String kNovelReaderFontSize = "NovelReaderFontSize";

  /// Novel reader custom font path
  static const String kNovelReaderFontPath = "NovelReaderFontPath";

  /// Novel reader imported font paths
  static const String kNovelReaderFontPaths = "NovelReaderFontPaths";

  /// 小說行距
  static const String kNovelReaderLineSpacing = "NovelReaderLineSpacing";

  /// 小說閱讀主題
  static const String kNovelReaderTheme = "NovelReaderTheme";

  /// 小說閱讀顯示狀態資訊
  static const String kNovelReaderShowStatus = "NovelReaderShowStatus";

  /// 小說全屏閱讀
  static const String kNovelReaderFullScreen = "NovelReaderFullScreen";

  /// 下載是否允許使用流量
  static const String kDownloadAllowCellular = "DownloadAllowCellular";

  /// 下載小說最大任務數
  static const String kDownloadNovelTaskCount = "DownloadNovelTaskCount";

  /// 下載漫畫最大任務數
  static const String kDownloadComicTaskCount = "DownloadComicTaskCount";

  /// 漫畫搜尋使用Web介面
  static const String kComicSearchUseWebApi = "ComicSearchUseWebApi";

  /// 顯示字型大小跟隨系統
  static const String kUseSystemFontSize = "UseSystemFontSize";

  /// 漫畫-左手模式
  static const String kComicReaderLeftHandMode = "ComicReaderLeftHandMode";

  /// 小說-左手模式
  static const String kNovelReaderLeftHandMode = "NovelReaderLeftHandMode";

  /// 漫畫閱讀優先載入高畫質圖
  static const String kComicReaderHD = "ComicReaderHD";

  /// 漫畫閱讀-翻頁動畫
  static const String kComicReaderPageAnimation = "ComicReaderPageAnimation";

  /// 小說閱讀-翻頁動畫
  static const String kNovelReaderPageAnimation = "NovelReaderPageAnimation";

  /// 新聞字型大小
  static const String kNewsFontSize = "NewsFontSize";

  /// 自動新增神隱漫畫至收藏夾
  static const String kCollectHideComic = "CollectHideComic";

  /// Reader volume key page turning
  static const String kReaderVolumeKeyTurnPage = "ReaderVolumeKeyTurnPage";

  /// E-ink display mode
  static const String kEInkMode = "EInkMode";

  late Box settingsBox;
  Future init() async {
    var dir = await getApplicationSupportDirectory();
    settingsBox = await Hive.openBox(
      "LocalStorage",
      path: dir.path,
    );
  }

  T getValue<T>(dynamic key, T defaultValue) {
    var value = settingsBox.get(key, defaultValue: defaultValue) as T;
    Log.d("Get LocalStorage：$key\r\n$value");
    return value;
  }

  Future setValue<T>(dynamic key, T value) async {
    Log.d("Set LocalStorage：$key\r\n$value");
    return await settingsBox.put(key, value);
  }

  Future removeValue<T>(dynamic key) async {
    Log.d("Remove LocalStorage：$key");
    return await settingsBox.delete(key);
  }

  bool get isFirst => getValue("First", true);

  void setNoFirst() {
    setValue("First", false);
  }

  Future<Directory> getNovelCacheDirectory() async {
    var dir = await getApplicationSupportDirectory();
    var novelDir = Directory(p.join(dir.path, "novel_cache"));
    if (!await novelDir.exists()) {
      novelDir = await novelDir.create();
    }
    return novelDir;
  }

  Future saveNovelContent({
    required int volumeId,
    required int chapterId,
    required String content,
  }) async {
    try {
      var novelDir = await getNovelCacheDirectory();

      var fileName = p.join(novelDir.path, "${volumeId}_$chapterId.txt");
      var file = File(fileName);
      await file.writeAsString(content);
    } catch (e) {
      Log.logPrint(e);
    }
  }

  Future<String?> getNovelContent(
      {required int volumeId, required int chapterId}) async {
    try {
      var novelDir = await getNovelCacheDirectory();
      var fileName = p.join(novelDir.path, "${volumeId}_$chapterId.txt");
      var file = File(fileName);

      if (await file.exists()) {
        var content = await file.readAsString();
        return content;
      }
      return null;
    } catch (e) {
      Log.logPrint(e);
      return null;
    }
  }

  Future<int> getNovelCacheSize() async {
    var novelDir = await getNovelCacheDirectory();
    var size = 0;
    await for (var item in novelDir.list()) {
      size += item.statSync().size;
    }
    return size;
  }

  Future<bool> cleanNovelCacheSize() async {
    try {
      var novelDir = await getNovelCacheDirectory();

      await novelDir.delete(recursive: true);
      return true;
    } catch (e) {
      Log.logPrint(e);
      return false;
    }
  }
}
