import 'package:flutter/material.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/novel_font_service.dart';
import 'package:zai_x/services/reader_volume_key_service.dart';
import 'package:get/get.dart';

class AppSettingsService extends GetxController {
  static AppSettingsService get instance => Get.find<AppSettingsService>();
  var themeMode = 0.obs;
  var firstRun = false;
  @override
  void onInit() {
    themeMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kThemeMode, 0);
    appLanguage.value = LocalStorageService.instance
        .getValue(LocalStorageService.kAppLanguage, 0);
    AppI18n.apply(appLanguage.value);
    firstRun = LocalStorageService.instance
        .getValue(LocalStorageService.kFirstRun, true);
    //漫画
    comicReaderDirection.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderDirection, 0);
    comicReaderFullScreen.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderFullScreen, true);
    comicReaderShowStatus.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderShowStatus, true);
    comicReaderShowStatus.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderShowStatus, true);
    comicReaderShowViewPoint.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderShowViewPoint, true);
    comicReaderLeftHandMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderLeftHandMode, false);
    comicReaderHD.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderHD, false);
    comicReaderPageAnimation.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderPageAnimation, true);
    comicReaderOldViewPoint.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderOldViewPoint, false);
    comicReaderTapZone.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicReaderTapZone, 10);
    //小说
    novelReaderDirection.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderDirection, 0);
    novelReaderFontSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderFontSize, 16);
    novelReaderFontPath.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderFontPath, '');
    novelReaderFontPaths.value = List<String>.from(
      LocalStorageService.instance.getValue(
        LocalStorageService.kNovelReaderFontPaths,
        <String>[],
      ),
    );
    if (novelReaderFontPath.value.isNotEmpty &&
        !novelReaderFontPaths.contains(novelReaderFontPath.value)) {
      novelReaderFontPaths.add(novelReaderFontPath.value);
    }
    final selectedFontKey = novelReaderFontPath.value.isEmpty
        ? ''
        : NovelFontService.instance.getFontKey(novelReaderFontPath.value);
    novelReaderFontPaths.value = NovelFontService.instance
        .filterAvailableFontPaths(novelReaderFontPaths);
    if (novelReaderFontPath.value.isNotEmpty &&
        !novelReaderFontPaths.contains(novelReaderFontPath.value)) {
      novelReaderFontPath.value = novelReaderFontPaths.firstWhere(
        (path) => NovelFontService.instance.getFontKey(path) == selectedFontKey,
        orElse: () => '',
      );
      LocalStorageService.instance
          .setValue(LocalStorageService.kNovelReaderFontPath, novelReaderFontPath.value);
    }
    _saveNovelReaderFontPaths();
    for (final fontPath in novelReaderFontPaths) {
      NovelFontService.instance.loadFont(fontPath);
    }
    novelReaderLineSpacing.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderLineSpacing, 1.5);
    novelReaderTheme.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderTheme, 0);
    novelReaderFullScreen.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderFullScreen, true);
    novelReaderShowStatus.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderShowStatus, true);
    novelReaderLeftHandMode.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderLeftHandMode, false);
    novelReaderPageAnimation.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNovelReaderPageAnimation, true);
    //下载
    downloadAllowCellular.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDownloadAllowCellular, true);
    downloadComicTaskCount.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDownloadComicTaskCount, 5);
    downloadNovelTaskCount.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDownloadNovelTaskCount, 5);
    //搜索API
    comicSearchUseWebApi.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicSearchUseWebApi, false);
    //字体大小
    useSystemFontSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kUseSystemFontSize, false);
    //新闻字体
    newsFontSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNewsFontSize, 15);
    //自动添加神隐漫画至收藏夹
    collectHideComic.value = LocalStorageService.instance
        .getValue(LocalStorageService.kCollectHideComic, false);
    readerVolumeKeyTurnPage.value = LocalStorageService.instance
        .getValue(LocalStorageService.kReaderVolumeKeyTurnPage, false);
    readerKeepScreenOn.value = LocalStorageService.instance
        .getValue(LocalStorageService.kReaderKeepScreenOn, true);
    eInkMode.value =
        LocalStorageService.instance.getValue(LocalStorageService.kEInkMode, false);
    if (eInkMode.value) {
      applyEInkModeSettings();
    }
    super.onInit();
  }

  /// 界面语言
  /// * [0] 跟随系统
  /// * [1] 简体中文
  /// * [2] 繁体中文
  var appLanguage = 0.obs;

  String get languageName {
    switch (appLanguage.value) {
      case 1:
        return "简体中文".i18n;
      case 2:
        return "繁体中文".i18n;
      default:
        return "跟随系统".i18n;
    }
  }

  void changeLanguage() {
    Get.dialog(
      SimpleDialog(
        title: Text("界面语言".i18n),
        children: [
          RadioGroup<int>(
            groupValue: appLanguage.value,
            onChanged: (e) {
              Get.back();
              setLanguage(e ?? 0);
            },
            child: Column(
              children: [
                RadioListTile<int>(
                  title: Text("跟随系统".i18n),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: Text("简体中文".i18n),
                  value: 1,
                ),
                RadioListTile<int>(
                  title: Text("繁体中文".i18n),
                  value: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void setLanguage(int i) {
    if (appLanguage.value == i) {
      return;
    }
    appLanguage.value = i;
    LocalStorageService.instance.setValue(LocalStorageService.kAppLanguage, i);
    AppI18n.apply(i);
    Get.forceAppUpdate();
  }

  void changeTheme() {
    Get.dialog(
      SimpleDialog(
        title: Text("设置主题".i18n),
        children: [
          RadioGroup<int>(
            groupValue: themeMode.value,
            onChanged: (e) {
              Get.back();
              setTheme(e ?? 0);
            },
            child: Column(
              children: [
                RadioListTile<int>(
                  title: Text("跟随系统".i18n),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: Text("浅色模式".i18n),
                  value: 1,
                ),
                RadioListTile<int>(
                  title: Text("深色模式".i18n),
                  value: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void setTheme(int i) {
    themeMode.value = i;
    var mode = ThemeMode.values[i];

    LocalStorageService.instance.setValue(LocalStorageService.kThemeMode, i);
    Get.changeThemeMode(mode);
  }

  /// 漫画阅读方向
  /// * [0] 左右
  /// * [1] 上下
  /// * [2] 右左
  var comicReaderDirection = 0.obs;
  void setComicReaderDirection(int direction) {
    if (comicReaderDirection.value == direction) {
      return;
    }
    comicReaderDirection.value = direction;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderDirection, direction);
  }

  /// 漫画全屏阅读
  RxBool comicReaderFullScreen = true.obs;
  void setComicReaderFullScreen(bool value) {
    comicReaderFullScreen.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderFullScreen, value);
  }

  /// 漫画阅读显示状态信息
  RxBool comicReaderShowStatus = true.obs;
  void setComicReaderShowStatus(bool value) {
    comicReaderShowStatus.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderShowStatus, value);
  }

  /// 漫画阅读尾页显示观点/吐槽
  RxBool comicReaderShowViewPoint = true.obs;
  void setComicReaderShowViewPoint(bool value) {
    comicReaderShowViewPoint.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderShowViewPoint, value);
  }

  /// 启用旧板吐槽
  RxBool comicReaderOldViewPoint = false.obs;
  void setComicReaderOldViewPoint(bool value) {
    comicReaderOldViewPoint.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderOldViewPoint, value);
  }

  /// 小说阅读方向
  /// * [0] 左右
  /// * [1] 上下
  /// * [2] 右左
  var novelReaderDirection = 0.obs;
  void setNovelReaderDirection(int direction) {
    if (novelReaderDirection.value == direction) {
      return;
    }
    novelReaderDirection.value = direction;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderDirection, direction);
  }

  /// 小说字体
  var novelReaderFontSize = 16.obs;
  void setNovelReaderFontSize(int size) {
    if (size < 5) {
      size = 5;
    }
    //应该没人需要这么大的字体吧...
    if (size > 56) {
      size = 56;
    }
    novelReaderFontSize.value = size;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderFontSize, size);
  }

  /// Novel reader font path. Empty means system default.
  var novelReaderFontPath = ''.obs;
  RxList<String> novelReaderFontPaths = RxList<String>();
  String? get novelReaderFontFamily => novelReaderFontPath.value.isEmpty
      ? null
      : NovelFontService.instance.getFontFamily(novelReaderFontPath.value);
  String get novelReaderFontName =>
      NovelFontService.instance.getFontName(novelReaderFontPath.value);
  Future<void> setNovelReaderFontPath(String path) async {
    if (path.isNotEmpty) {
      final fontName = NovelFontService.instance.getFontName(path);
      if (!novelReaderFontPaths.contains(path) &&
          NovelFontService.instance.hasSameFontName(
            fontName,
            novelReaderFontPaths,
          )) {
        throw Exception('已添加同名字体：$fontName'.i18n);
      }
      await NovelFontService.instance.loadFont(path);
      if (!novelReaderFontPaths.contains(path)) {
        novelReaderFontPaths.add(path);
        await _saveNovelReaderFontPaths();
      }
    }
    novelReaderFontPath.value = path;
    await LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderFontPath, path);
  }

  Future<void> addNovelReaderFontPath(String path) async {
    await setNovelReaderFontPath(path);
  }

  Future<void> deleteNovelReaderFontPath(String path) async {
    if (path.isEmpty) {
      return;
    }
    novelReaderFontPaths.remove(path);
    if (novelReaderFontPath.value == path) {
      novelReaderFontPath.value = '';
      await LocalStorageService.instance
          .setValue(LocalStorageService.kNovelReaderFontPath, '');
    }
    await _saveNovelReaderFontPaths();
    await NovelFontService.instance.deleteFont(path);
  }

  Future<void> _saveNovelReaderFontPaths() async {
    await LocalStorageService.instance.setValue(
      LocalStorageService.kNovelReaderFontPaths,
      novelReaderFontPaths.toList(),
    );
  }

  /// 小说行距
  var novelReaderLineSpacing = 1.5.obs;
  void setNovelReaderLineSpacing(double spacing) {
    if (spacing < 1) {
      spacing = 1;
    }
    //应该没人需要这么大的字体吧...
    if (spacing > 5) {
      spacing = 5;
    }
    novelReaderLineSpacing.value = spacing;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderLineSpacing, spacing);
  }

  /// 小说阅读主题
  var novelReaderTheme = 0.obs;
  void setNovelReaderTheme(int theme) {
    novelReaderTheme.value = theme;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderTheme, theme);
  }

  /// 漫画全屏阅读
  RxBool novelReaderFullScreen = true.obs;
  void setNovelReaderFullScreen(bool value) {
    novelReaderFullScreen.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderFullScreen, value);
  }

  /// 漫画阅读显示状态信息
  RxBool novelReaderShowStatus = true.obs;
  void setNovelReaderShowStatus(bool value) {
    novelReaderShowStatus.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderShowStatus, value);
  }

  /// 下载是否允许使用流量
  RxBool downloadAllowCellular = true.obs;
  void setDownloadAllowCellular(bool value) {
    downloadAllowCellular.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDownloadAllowCellular, value);
  }

  /// 下载漫画最大任务数
  var downloadComicTaskCount = 5.obs;
  void setDownloadComicTaskCount(int task) {
    downloadComicTaskCount.value = task;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDownloadComicTaskCount, task);
  }

  /// 下载漫画最大任务数
  var downloadNovelTaskCount = 5.obs;
  void setDownloadNovelTaskCount(int task) {
    downloadNovelTaskCount.value = task;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDownloadNovelTaskCount, task);
  }

  /// 漫画搜索使用Web接口
  var comicSearchUseWebApi = false.obs;
  void setComicSearchUseWebApi(bool e) {
    comicSearchUseWebApi.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicSearchUseWebApi, e);
  }

  /// 显示字体大小跟随系统
  var useSystemFontSize = false.obs;
  void setUseSystemFontSize(bool e) {
    useSystemFontSize.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kUseSystemFontSize, e);
  }

  /// 漫画阅读左手模式
  RxBool comicReaderLeftHandMode = false.obs;
  void setComicReaderLeftHandMode(bool value) {
    comicReaderLeftHandMode.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderLeftHandMode, value);
  }

  /// 小说阅读左手模式
  RxBool novelReaderLeftHandMode = false.obs;
  void setNovelReaderLeftHandMode(bool value) {
    novelReaderLeftHandMode.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderLeftHandMode, value);
  }

  /// 漫画阅读优先加载高清图
  RxBool comicReaderHD = false.obs;
  void setComicReaderHD(bool value) {
    comicReaderHD.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderHD, value);
  }

  /// 漫画阅读翻页动画
  RxBool comicReaderPageAnimation = true.obs;
  void setComicReaderPageAnimation(bool value) {
    if (eInkMode.value && value) {
      value = false;
    }
    comicReaderPageAnimation.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderPageAnimation, value);
  }

  /// 阅读时保持屏幕常亮
  RxBool readerKeepScreenOn = true.obs;
  void setReaderKeepScreenOn(bool value) {
    readerKeepScreenOn.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kReaderKeepScreenOn, value);
  }

  /// 漫画阅读器左右翻页触控区宽度（占屏宽百分比，单侧，5-40）
  RxInt comicReaderTapZone = 10.obs;
  void setComicReaderTapZone(int value) {
    if (value < 5) value = 5;
    if (value > 40) value = 40;
    comicReaderTapZone.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderTapZone, value);
  }

  /// 小说阅读翻页动画
  RxBool novelReaderPageAnimation = true.obs;
  void setNovelReaderPageAnimation(bool value) {
    if (eInkMode.value && value) {
      value = false;
    }
    novelReaderPageAnimation.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderPageAnimation, value);
  }

  /// 下载漫画最大任务数
  var newsFontSize = 15.obs;
  void setNewsFontSize(int size) {
    newsFontSize.value = size;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNewsFontSize, size);
  }

  /// 自动添加神隐漫画至收藏夹
  RxBool collectHideComic = false.obs;
  void setCollectHideComic(bool value) {
    collectHideComic.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kCollectHideComic, value);
  }

  /// Reader volume key page turning
  RxBool readerVolumeKeyTurnPage = false.obs;
  void setReaderVolumeKeyTurnPage(bool value) {
    if (eInkMode.value && !value) {
      value = true;
    }
    readerVolumeKeyTurnPage.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kReaderVolumeKeyTurnPage, value);
    ReaderVolumeKeyService.instance.setEnabled(value);
  }

  /// E-ink display mode
  RxBool eInkMode = false.obs;
  void setEInkMode(bool value) {
    eInkMode.value = value;
    LocalStorageService.instance.setValue(LocalStorageService.kEInkMode, value);
    if (value) {
      applyEInkModeSettings();
    }
  }

  void applyEInkModeSettings() {
    setComicReaderPageAnimation(false);
    setNovelReaderPageAnimation(false);
    setReaderVolumeKeyTurnPage(true);
  }

  void setNoFirstRun() {
    LocalStorageService.instance.setValue(LocalStorageService.kFirstRun, false);
  }
}
