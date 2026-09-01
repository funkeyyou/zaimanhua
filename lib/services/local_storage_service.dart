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

  /// 显示模式
  /// * [0] 跟随系统
  /// * [1] 浅色模式
  /// * [2] 深色模式
  static const String kThemeMode = "ThemeMode";

  /// 界面语言
  /// * [0] 跟随系统
  /// * [1] 简体中文
  /// * [2] 繁体中文
  static const String kAppLanguage = "AppLanguage";

  /// 首次运行
  static const String kFirstRun = "FirstRun";

  /// 用户登录信息
  /// * 类型：LoginResultModel
  static const String kUserAuthInfo = "UserAuthInfo";

  /// 漫画阅读方向
  static const String kComicReaderDirection = "ComicReaderDirection";

  /// 漫画全屏阅读
  static const String kComicReaderFullScreen = "ComicReaderFullScreen";

  /// 漫画阅读显示状态信息
  static const String kComicReaderShowStatus = "ComicReaderShowStatus";

  /// 漫画阅读尾页显示观点/吐槽
  static const String kComicReaderShowViewPoint = "ComicReaderShowViewPoint";

  /// 启用旧版吐槽
  static const String kComicReaderOldViewPoint = "ComicReaderOldViewPoint";

  /// 小说阅读方向
  static const String kNovelReaderDirection = "NovelReaderDirection";

  /// 小说字体大小
  static const String kNovelReaderFontSize = "NovelReaderFontSize";

  /// Novel reader custom font path
  static const String kNovelReaderFontPath = "NovelReaderFontPath";

  /// Novel reader imported font paths
  static const String kNovelReaderFontPaths = "NovelReaderFontPaths";

  /// 小说行距
  static const String kNovelReaderLineSpacing = "NovelReaderLineSpacing";

  /// 小说阅读主题
  static const String kNovelReaderTheme = "NovelReaderTheme";

  /// 小说阅读显示状态信息
  static const String kNovelReaderShowStatus = "NovelReaderShowStatus";

  /// 小说全屏阅读
  static const String kNovelReaderFullScreen = "NovelReaderFullScreen";

  /// 下载是否允许使用流量
  static const String kDownloadAllowCellular = "DownloadAllowCellular";

  /// 下载小说最大任务数
  static const String kDownloadNovelTaskCount = "DownloadNovelTaskCount";

  /// 下载漫画最大任务数
  static const String kDownloadComicTaskCount = "DownloadComicTaskCount";

  /// 漫画搜索使用Web接口
  static const String kComicSearchUseWebApi = "ComicSearchUseWebApi";

  /// 显示字体大小跟随系统
  static const String kUseSystemFontSize = "UseSystemFontSize";

  /// 漫画-左手模式
  static const String kComicReaderLeftHandMode = "ComicReaderLeftHandMode";

  /// 小说-左手模式
  static const String kNovelReaderLeftHandMode = "NovelReaderLeftHandMode";

  /// 漫画阅读优先加载高清图
  static const String kComicReaderHD = "ComicReaderHD";

  /// 漫画阅读-翻页动画
  static const String kComicReaderPageAnimation = "ComicReaderPageAnimation";

  /// 漫画阅读器左右翻页触控区宽度（占屏宽百分比，单侧）
  static const String kComicReaderTapZone = "ComicReaderTapZone";

  /// 漫画双页对开模式 0=关闭 1=宽屏自动 2=总是
  static const String kComicReaderDualPage = "ComicReaderDualPage";

  /// 双页模式下首页（封面）单独占一页
  static const String kComicReaderDualPageCover = "ComicReaderDualPageCover";

  /// 订阅更新提醒
  static const String kSubscribeNotify = "SubscribeNotify";

  /// 订阅更新检查间隔（小时）
  static const String kSubscribeNotifyHours = "SubscribeNotifyHours";

  /// 签到结果通知
  static const String kSignInNotify = "SignInNotify";

  /// 最近一次发出签到通知的日期(yyyy-MM-dd)，用来一天只提醒一次
  static const String kSignInNotifyDate = "SignInNotifyDate";

  /// 我的订阅排序 0=订阅顺序 1=更新时间
  static const String kSubscribeSort = "SubscribeSort";

  /// 阅读时保持屏幕常亮
  static const String kReaderKeepScreenOn = "ReaderKeepScreenOn";

  /// 阅读器屏幕亮度（0.05-1.0，-1 表示跟随系统）
  static const String kReaderBrightness = "ReaderBrightness";

  /// 小说阅读-翻页动画
  static const String kNovelReaderPageAnimation = "NovelReaderPageAnimation";

  /// 新闻字体大小
  static const String kNewsFontSize = "NewsFontSize";

  /// 自动添加神隐漫画至收藏夹
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
