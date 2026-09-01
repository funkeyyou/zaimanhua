import 'package:flutter/material.dart';
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
    firstRun = LocalStorageService.instance
        .getValue(LocalStorageService.kFirstRun, true);
    //漫畫
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
    //小說
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
    //下載
    downloadAllowCellular.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDownloadAllowCellular, true);
    downloadComicTaskCount.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDownloadComicTaskCount, 5);
    downloadNovelTaskCount.value = LocalStorageService.instance
        .getValue(LocalStorageService.kDownloadNovelTaskCount, 5);
    //搜尋API
    comicSearchUseWebApi.value = LocalStorageService.instance
        .getValue(LocalStorageService.kComicSearchUseWebApi, false);
    //字型大小
    useSystemFontSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kUseSystemFontSize, false);
    //新聞字型
    newsFontSize.value = LocalStorageService.instance
        .getValue(LocalStorageService.kNewsFontSize, 15);
    //自動新增神隱漫畫至收藏夾
    collectHideComic.value = LocalStorageService.instance
        .getValue(LocalStorageService.kCollectHideComic, false);
    readerVolumeKeyTurnPage.value = LocalStorageService.instance
        .getValue(LocalStorageService.kReaderVolumeKeyTurnPage, false);
    eInkMode.value =
        LocalStorageService.instance.getValue(LocalStorageService.kEInkMode, false);
    if (eInkMode.value) {
      applyEInkModeSettings();
    }
    super.onInit();
  }

  void changeTheme() {
    Get.dialog(
      SimpleDialog(
        title: const Text("設定主題"),
        children: [
          RadioGroup<int>(
            groupValue: themeMode.value,
            onChanged: (e) {
              Get.back();
              setTheme(e ?? 0);
            },
            child: const Column(
              children: [
                RadioListTile<int>(
                  title: Text("跟隨系統"),
                  value: 0,
                ),
                RadioListTile<int>(
                  title: Text("淺色模式"),
                  value: 1,
                ),
                RadioListTile<int>(
                  title: Text("深色模式"),
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

  /// 漫畫閱讀方向
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

  /// 漫畫全屏閱讀
  RxBool comicReaderFullScreen = true.obs;
  void setComicReaderFullScreen(bool value) {
    comicReaderFullScreen.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderFullScreen, value);
  }

  /// 漫畫閱讀顯示狀態資訊
  RxBool comicReaderShowStatus = true.obs;
  void setComicReaderShowStatus(bool value) {
    comicReaderShowStatus.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderShowStatus, value);
  }

  /// 漫畫閱讀尾頁顯示觀點/吐槽
  RxBool comicReaderShowViewPoint = true.obs;
  void setComicReaderShowViewPoint(bool value) {
    comicReaderShowViewPoint.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderShowViewPoint, value);
  }

  /// 啟用舊板吐槽
  RxBool comicReaderOldViewPoint = false.obs;
  void setComicReaderOldViewPoint(bool value) {
    comicReaderOldViewPoint.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderOldViewPoint, value);
  }

  /// 小說閱讀方向
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

  /// 小說字型
  var novelReaderFontSize = 16.obs;
  void setNovelReaderFontSize(int size) {
    if (size < 5) {
      size = 5;
    }
    //應該沒人需要這麼大的字型吧...
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
        throw Exception('已新增同名字型：$fontName');
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

  /// 小說行距
  var novelReaderLineSpacing = 1.5.obs;
  void setNovelReaderLineSpacing(double spacing) {
    if (spacing < 1) {
      spacing = 1;
    }
    //應該沒人需要這麼大的字型吧...
    if (spacing > 5) {
      spacing = 5;
    }
    novelReaderLineSpacing.value = spacing;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderLineSpacing, spacing);
  }

  /// 小說閱讀主題
  var novelReaderTheme = 0.obs;
  void setNovelReaderTheme(int theme) {
    novelReaderTheme.value = theme;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderTheme, theme);
  }

  /// 漫畫全屏閱讀
  RxBool novelReaderFullScreen = true.obs;
  void setNovelReaderFullScreen(bool value) {
    novelReaderFullScreen.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderFullScreen, value);
  }

  /// 漫畫閱讀顯示狀態資訊
  RxBool novelReaderShowStatus = true.obs;
  void setNovelReaderShowStatus(bool value) {
    novelReaderShowStatus.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderShowStatus, value);
  }

  /// 下載是否允許使用流量
  RxBool downloadAllowCellular = true.obs;
  void setDownloadAllowCellular(bool value) {
    downloadAllowCellular.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDownloadAllowCellular, value);
  }

  /// 下載漫畫最大任務數
  var downloadComicTaskCount = 5.obs;
  void setDownloadComicTaskCount(int task) {
    downloadComicTaskCount.value = task;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDownloadComicTaskCount, task);
  }

  /// 下載漫畫最大任務數
  var downloadNovelTaskCount = 5.obs;
  void setDownloadNovelTaskCount(int task) {
    downloadNovelTaskCount.value = task;
    LocalStorageService.instance
        .setValue(LocalStorageService.kDownloadNovelTaskCount, task);
  }

  /// 漫畫搜尋使用Web介面
  var comicSearchUseWebApi = false.obs;
  void setComicSearchUseWebApi(bool e) {
    comicSearchUseWebApi.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicSearchUseWebApi, e);
  }

  /// 顯示字型大小跟隨系統
  var useSystemFontSize = false.obs;
  void setUseSystemFontSize(bool e) {
    useSystemFontSize.value = e;
    LocalStorageService.instance
        .setValue(LocalStorageService.kUseSystemFontSize, e);
  }

  /// 漫畫閱讀左手模式
  RxBool comicReaderLeftHandMode = false.obs;
  void setComicReaderLeftHandMode(bool value) {
    comicReaderLeftHandMode.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderLeftHandMode, value);
  }

  /// 小說閱讀左手模式
  RxBool novelReaderLeftHandMode = false.obs;
  void setNovelReaderLeftHandMode(bool value) {
    novelReaderLeftHandMode.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderLeftHandMode, value);
  }

  /// 漫畫閱讀優先載入高畫質圖
  RxBool comicReaderHD = false.obs;
  void setComicReaderHD(bool value) {
    comicReaderHD.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderHD, value);
  }

  /// 漫畫閱讀翻頁動畫
  RxBool comicReaderPageAnimation = true.obs;
  void setComicReaderPageAnimation(bool value) {
    if (eInkMode.value && value) {
      value = false;
    }
    comicReaderPageAnimation.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kComicReaderPageAnimation, value);
  }

  /// 小說閱讀翻頁動畫
  RxBool novelReaderPageAnimation = true.obs;
  void setNovelReaderPageAnimation(bool value) {
    if (eInkMode.value && value) {
      value = false;
    }
    novelReaderPageAnimation.value = value;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNovelReaderPageAnimation, value);
  }

  /// 下載漫畫最大任務數
  var newsFontSize = 15.obs;
  void setNewsFontSize(int size) {
    newsFontSize.value = size;
    LocalStorageService.instance
        .setValue(LocalStorageService.kNewsFontSize, size);
  }

  /// 自動新增神隱漫畫至收藏夾
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
