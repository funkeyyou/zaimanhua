import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/app_error.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/comic/chapter_info.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/models/comic/view_point_model.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/reader_volume_key_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:remixicon/remixicon.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ComicReaderController extends BaseController {
  /// 是否為條漫
  final bool isLongComic;
  final int comicId;
  final String comicTitle;
  final String comicCover;
  final ComicDetailChapterItem chapter;
  final List<ComicDetailChapterItem> chapters;
  final FocusNode focusNode = FocusNode();
  final ComicRequest request = ComicRequest();
  ComicReaderController({
    required this.comicId,
    required this.comicTitle,
    required this.chapters,
    required this.chapter,
    required this.comicCover,
    required this.isLongComic,
  }) {
    chapterIndex.value = chapters.indexOf(chapter);
  }

  /// APP設定控制器
  final settings = AppSettingsService.instance;

  /// 預載入控制器
  final PreloadPageController preloadPageController = PreloadPageController();

  /// 上下模式控制器
  final ItemScrollController itemScrollController = ItemScrollController();

  /// 監聽上下滾動
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// 章節詳情
  Rx<ComicChapterDetail> detail =
      Rx<ComicChapterDetail>(ComicChapterDetail.empty());

  /// 連線資訊監聽
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  /// 電量資訊監聽
  StreamSubscription<BatteryState>? batterySubscription;

  /// 當處於放大圖片時，鎖定滑動手勢
  var lockSwipe = false.obs;

  /// 當前章節索引
  var chapterIndex = 0.obs;

  /// 當前頁面
  var currentIndex = 0.obs;

  /// 初始化
  var initialIndex = 0;

  /// 是否顯示控制器
  var showControls = false.obs;

  /// 閱讀方向
  var direction = 0.obs;

  /// 左手模式
  bool get leftHandMode => settings.comicReaderLeftHandMode.value;

  /// 翻頁動畫
  bool get pageAnimation => settings.comicReaderPageAnimation.value;

  /// 觀點、吐槽
  RxList<ComicViewPointModel> viewPoints = RxList<ComicViewPointModel>();

  /// 連線型別
  Rx<ConnectivityResult> connectivityType =
      Rx<ConnectivityResult>(ConnectivityResult.other);

  /// 電量資訊
  Rx<int> batteryLevel = 0.obs;

  /// 顯示電量
  RxBool showBattery = true.obs;

  @override
  void onInit() {
    initConnectivity();
    initBattery();
    if (isLongComic) {
      direction.value = ReaderDirection.kUpToDown;
    } else {
      direction.value = settings.comicReaderDirection.value;
    }

    if (settings.comicReaderFullScreen.value) {
      setFull();
    }

    ReaderVolumeKeyService.instance.start(
      enabled: settings.readerVolumeKeyTurnPage.value,
      onVolumeUp: forwardPageByInput,
      onVolumeDown: nextPageByInput,
    );

    itemPositionsListener.itemPositions.addListener(updateItemPosition);
    loadDetail();
    super.onInit();
  }

  /// 初始化電池資訊
  void initBattery() async {
    try {
      //沒有電池的Mac似乎會閃退,暫時遮蔽Mac
      //https://github.com/xiaoyaocz/zai_x/discussions/146
      if (Platform.isMacOS) {
        showBattery.value = false;
        return;
      }
      var battery = Battery();
      batterySubscription =
          battery.onBatteryStateChanged.listen((BatteryState state) async {
        try {
          var level = await battery.batteryLevel;
          batteryLevel.value = level;
          showBattery.value = true;
        } catch (e) {
          showBattery.value = false;
        }
      });
      batteryLevel.value = await battery.batteryLevel;
      showBattery.value = true;
    } catch (e) {
      showBattery.value = false;
    }
  }

  /// 初始化連線狀態
  void initConnectivity() async {
    var connectivity = Connectivity();
    connectivitySubscription =
        connectivity.onConnectivityChanged.listen((results) {
      final result = _pickConnectivityType(results);
      //提醒
      if (connectivityType.value != result &&
          result == ConnectivityResult.mobile) {
        SmartDialog.showToast("您已切換至資料網路，請注意流量消耗");
      }
      connectivityType.value = result;
    });
    connectivityType.value =
        _pickConnectivityType(await connectivity.checkConnectivity());
  }

  ConnectivityResult _pickConnectivityType(List<ConnectivityResult> results) {
    for (final result in results) {
      if (result != ConnectivityResult.none) {
        return result;
      }
    }
    return ConnectivityResult.none;
  }

  @override
  void onClose() {
    focusNode.dispose();
    connectivitySubscription?.cancel();
    batterySubscription?.cancel();
    ReaderVolumeKeyService.instance.stop();
    exitFull();
    itemPositionsListener.itemPositions.removeListener(updateItemPosition);
    uploadHistory();
    super.onClose();
  }

  void updateItemPosition() {
    var items = itemPositionsListener.itemPositions.value;
    if (items.isEmpty) {
      return;
    }

    var index = items
        .where((ItemPosition position) => position.itemTrailingEdge > 0)
        .reduce((ItemPosition min, ItemPosition position) =>
            position.itemTrailingEdge < min.itemTrailingEdge ? position : min)
        .index;

    currentIndex.value = index;
  }

  /// 載入資訊
  void loadDetail() async {
    try {
      pageLoadding.value = true;
      pageError.value = false;

      detail.value = ComicChapterDetail.empty();
      var chapterId = chapters[chapterIndex.value].chapterId;
      if (chapters[chapterIndex.value].isVip) {
        //禁止觀看VIP章節
        throw AppError("請使用動漫之家官方APP觀看VIP章節");
      }
      loadViewPoints();

      var result = await request.chapterDetail(
        comicId: comicId,
        chapterId: chapterId,
        useHD: AppSettingsService.instance.comicReaderHD.value,
      );
      var his = DBService.instance.getComicHistory(comicId);
      if (his != null && his.chapterId == chapterId && his.page != 0) {
        var hisIndex = (his.page - 1) < 0 ? 0 : his.page - 1;
        if (hisIndex >= result.pageUrls.length - 1) {
          hisIndex = 0;
        }
        initialIndex = hisIndex;
      } else {
        initialIndex = 0;
      }
      currentIndex.value = initialIndex;
      if (settings.comicReaderShowViewPoint.value) {
        result.pageUrls.add("TC");
      }

      detail.value = result;
      Future.delayed(const Duration(milliseconds: 100), () {
        jumpToPage(initialIndex);
      });
      //上傳記錄
      uploadHistory();
    } catch (e) {
      pageError.value = true;
      errorMsg.value = e.toString();
      setShowControls();
    } finally {
      pageLoadding.value = false;
    }
  }

  /// 載入吐槽、觀點
  void loadViewPoints() async {
    try {
      viewPoints.clear();
      var result = await request.viewPoints(
        comicId: comicId,
        chapterId: chapters[chapterIndex.value].chapterId,
      );
      result.sort((a, b) => b.num.value.compareTo(a.num.value));
      viewPoints.value = result;
    } catch (e) {
      //SmartDialog.showToast("讀取吐槽失敗");
      Log.logPrint(e.toString());
    }
  }

  /// 設定顯示/隱藏控制按鈕
  void setShowControls() {
    if (settings.comicReaderFullScreen.value) {
      if (showControls.value) {
        setFull();
      } else {
        setFullEdge();
      }
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      showControls.value = !showControls.value;
    });
  }

  /// 顯示目錄
  void showMenu() async {
    setShowControls();
    showModalBottomSheet(
      context: Get.context!,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      constraints: const BoxConstraints(
        maxWidth: 500,
      ),
      backgroundColor: AppStyle.darkTheme.scaffoldBackgroundColor,
      builder: (context) => Theme(
        data: AppStyle.darkTheme,
        child: Column(
          children: [
            ListTile(
              title: Text("目錄(${chapters.length})"),
              trailing: IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.close),
              ),
              contentPadding: AppStyle.edgeInsetsL12,
            ),
            Divider(
              height: 1.0,
              color: Colors.grey.withValues(alpha: .2),
            ),
            Expanded(
              child: ScrollablePositionedList.separated(
                initialScrollIndex: chapterIndex.value,
                itemCount: chapters.length,
                separatorBuilder: (_, i) => Divider(
                  indent: 12,
                  endIndent: 12,
                  height: 1.0,
                  color: Colors.grey.withValues(alpha: .2),
                ),
                itemBuilder: (_, i) {
                  var item = chapters[i];
                  return ListTile(
                    selected: i == chapterIndex.value,
                    title: Text(item.chapterTitle),
                    subtitle: item.updateTime != 0
                        ? Text(
                            "更新於${Utils.formatTimestampToDate(item.updateTime)}")
                        : null,
                    onTap: () {
                      chapterIndex.value = i;
                      loadDetail();
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      routeSettings: const RouteSettings(name: "/modalBottomSheet"),
    );
  }

  /// 下一章
  void nextChapter() {
    if (chapterIndex.value == chapters.length - 1) {
      SmartDialog.showToast("後面沒有了");
      return;
    }

    chapterIndex.value += 1;
    loadDetail();
  }

  /// 上一章
  void forwardChapter() {
    if (chapterIndex.value == 0) {
      SmartDialog.showToast("前面沒有了");
      return;
    }

    chapterIndex.value -= 1;
    loadDetail();
  }

  /// 下一頁
  void nextPage() {
    var value = currentIndex.value;
    Log.w("下一頁$value");
    var max = detail.value.pageUrls.length;
    if (value >= max - 1) {
      nextChapter();
    } else {
      jumpToPage(value + 1, anime: true);
    }
  }

  /// 上一頁
  void forwardPage() {
    var value = currentIndex.value;
    Log.w("上一頁$value");
    if (value == 0) {
      forwardChapter();
    } else {
      jumpToPage(value - 1, anime: true);
    }
  }

  /// 跳轉頁數
  void jumpToPage(int page, {bool anime = false}) {
    //豎向
    if (direction.value == ReaderDirection.kUpToDown) {
      itemScrollController.jumpTo(index: page);
    } else {
      anime && pageAnimation
          ? preloadPageController.animateToPage(page,
              duration: const Duration(milliseconds: 200), curve: Curves.linear)
          : preloadPageController.jumpToPage(page);
    }
  }

  /// 檢視吐槽
  void showComment() {
    setShowControls();
    TextEditingController tucaoController = TextEditingController();
    showModalBottomSheet(
      context: Get.context!,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      constraints: const BoxConstraints(
        maxWidth: 500,
      ),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppStyle.darkTheme.scaffoldBackgroundColor,
      builder: (context) => Theme(
        data: AppStyle.darkTheme,
        child: Column(
          children: [
            ListTile(
              title: Text("吐槽(${viewPoints.length})"),
              trailing: IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.close),
              ),
              contentPadding: AppStyle.edgeInsetsL12,
            ),
            Divider(
              height: 1.0,
              color: Colors.grey.withValues(alpha: .2),
            ),
            Expanded(
              child: EasyRefresh(
                header: const MaterialHeader(),
                onRefresh: () async {
                  loadViewPoints();
                },
                child: Obx(
                  () => settings.comicReaderOldViewPoint.value
                      ? SingleChildScrollView(
                          child: Padding(
                            padding: AppStyle.edgeInsetsA12,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: viewPoints.map<Widget>((item) {
                                return InkWell(
                                  onTap: () {
                                    // likeViewPoint(item);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: AppStyle.radius8,
                                    ),
                                    child: Text(
                                      item.content,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: viewPoints.length,
                          separatorBuilder: (_, i) => Divider(
                            indent: 12,
                            endIndent: 12,
                            height: 1.0,
                            color: Colors.grey.withValues(alpha: .2),
                          ),
                          itemBuilder: (_, i) {
                            var item = viewPoints[i];
                            return Padding(
                              padding: AppStyle.edgeInsetsA12
                                  .copyWith(top: 8, bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.content,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  AppStyle.hGap12,
                                  // TextButton.icon(
                                  //   style: TextButton.styleFrom(
                                  //     tapTargetSize:
                                  //         MaterialTapTargetSize.shrinkWrap,
                                  //   ),
                                  //   onPressed: () {
                                  //     likeViewPoint(item);
                                  //   },
                                  //   icon: const Icon(
                                  //     Remix.thumb_up_line,
                                  //     size: 16,
                                  //   ),
                                  //   label: Obx(() => Text("${item.num.value}")),
                                  // ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            Container(
              padding: AppStyle.edgeInsetsA8.copyWith(
                bottom: 8 + AppStyle.bottomBarHeight,
              ),
              child: TextField(
                controller: tucaoController,
                onSubmitted: (e) {
                  sendViewPoint(e);
                },
                decoration: InputDecoration(
                  hintText: "發表吐槽",
                  contentPadding: AppStyle.edgeInsetsH12,
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: () {
                      sendViewPoint(tucaoController.text);
                    },
                    child: const Text("釋出"),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      routeSettings: const RouteSettings(name: "/modalBottomSheet"),
    );
  }

  /// 顯示設定
  void showSettings() {
    setShowControls();

    showModalBottomSheet(
      context: Get.context!,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      constraints: const BoxConstraints(
        maxWidth: 500,
      ),
      backgroundColor: AppStyle.darkTheme.scaffoldBackgroundColor,
      builder: (context) => Theme(
        data: AppStyle.darkTheme,
        child: Column(
          children: [
            ListTile(
              title: const Text("設定"),
              trailing: IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.close),
              ),
              contentPadding: AppStyle.edgeInsetsL12,
            ),
            Expanded(
              child: Obx(
                () => ListView(
                  padding: AppStyle.edgeInsetsA12,
                  children: [
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderHD.value,
                        onChanged: (e) {
                          settings.setComicReaderHD(e);
                          loadDetail();
                        },
                        title: const Text("優先載入高畫質圖"),
                        subtitle: const Text("部分單行本可能未分頁"),
                      ),
                    ),
                    //AppStyle.vGap12,
                    Visibility(
                      //條漫不允許修改閱讀方向
                      visible: !isLongComic,
                      child: Padding(
                        padding: AppStyle.edgeInsetsT12,
                        child: buildBGItem(
                          child: ListTile(
                            title: const Text("閱讀方向"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildSelectedButton(
                                  onTap: () {
                                    setDirection(ReaderDirection.kLeftToRight);
                                  },
                                  selected:
                                      settings.comicReaderDirection.value ==
                                          ReaderDirection.kLeftToRight,
                                  child: const Icon(Remix.arrow_right_line),
                                ),
                                AppStyle.hGap8,
                                buildSelectedButton(
                                  onTap: () {
                                    setDirection(ReaderDirection.kRightToLeft);
                                  },
                                  selected:
                                      settings.comicReaderDirection.value ==
                                          ReaderDirection.kRightToLeft,
                                  child: const Icon(Remix.arrow_left_line),
                                ),
                                AppStyle.hGap8,
                                buildSelectedButton(
                                  onTap: () {
                                    setDirection(ReaderDirection.kUpToDown);
                                  },
                                  selected:
                                      settings.comicReaderDirection.value ==
                                          ReaderDirection.kUpToDown,
                                  child: const Icon(Remix.arrow_down_line),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AppStyle.vGap12,
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderLeftHandMode.value,
                        onChanged: (e) {
                          settings.setComicReaderLeftHandMode(e);
                        },
                        title: const Text("操作反轉"),
                        subtitle: const Text("點選左側下一頁，右側上一頁"),
                      ),
                    ),
                    AppStyle.vGap12,
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderFullScreen.value,
                        onChanged: (e) {
                          settings.setComicReaderFullScreen(e);
                          if (e) {
                            setFull();
                          } else {
                            exitFull();
                          }
                        },
                        title: const Text("全屏閱讀"),
                      ),
                    ),
                    AppStyle.vGap12,
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderShowStatus.value,
                        onChanged: (e) {
                          settings.setComicReaderShowStatus(e);
                        },
                        title: const Text("顯示狀態資訊"),
                      ),
                    ),
                    AppStyle.vGap12,
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderShowViewPoint.value,
                        onChanged: (e) {
                          settings.setComicReaderShowViewPoint(e);
                          setShowViewPoint(e);
                        },
                        title: const Text("顯示吐槽"),
                      ),
                    ),
                    // AppStyle.vGap12,
                    // buildBGItem(
                    //   child: SwitchListTile(
                    //     value: settings.comicReaderOldViewPoint.value,
                    //     onChanged: (e) {
                    //       settings.setComicReaderOldViewPoint(e);
                    //     },
                    //     title: const Text("舊板吐槽"),
                    //   ),
                    // ),
                    AppStyle.vGap12,
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderPageAnimation.value,
                        onChanged: (e) {
                          settings.setComicReaderPageAnimation(e);
                        },
                        title: const Text("翻頁動畫"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBGItem({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppStyle.radius8,
        color: AppStyle.darkTheme.cardColor,
      ),
      child: child,
    );
  }

  Widget buildSelectedButton(
      {required Widget child, bool selected = false, Function()? onTap}) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.blue : Colors.grey,
        side: BorderSide(
          color: selected ? Colors.blue : Colors.grey,
        ),
      ),
      onPressed: onTap,
      child: child,
    );
  }

  void setDirection(int value) {
    initialIndex = currentIndex.value;
    settings.setComicReaderDirection(value);
    direction.value = value;
    if (initialIndex != 0) {
      Future.delayed(const Duration(milliseconds: 200), () {
        jumpToPage(initialIndex);
      });
    }
  }

  void setShowViewPoint(bool value) {
    if (value) {
      if (!detail.value.pageUrls.contains("TC")) {
        detail.update((val) {
          val!.pageUrls.add("TC");
        });
      }
    } else {
      if (detail.value.pageUrls.contains("TC")) {
        detail.update((val) {
          val!.pageUrls.remove("TC");
        });
      }
    }
  }

  void uploadHistory() {
    var chapter = chapters[chapterIndex.value];
    UserService.instance.updateComicHistory(
      comicId: comicId,
      chapterId: chapter.chapterId,
      page: currentIndex.value + 1,
      comicName: comicTitle,
      comicCover: comicCover,
      chapterName: chapter.chapterTitle,
    );
  }

  /// 進入全屏
  void setFull() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );
  }

  /// 進入全屏edgeToEdge模式
  void setFullEdge() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  /// 退出全屏
  void exitFull() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  void likeViewPoint(ComicViewPointModel item) async {
    try {
      await request.likeViewPoint(comicId: comicId, id: item.id);

      item.num.value += 1;
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  void sendViewPoint(String content) async {
    if (!await UserService.instance.login()) {
      SmartDialog.showToast("請先登入");
      return;
    }
    if (content.isEmpty) {
      SmartDialog.showToast("內容不能為空");
      return;
    }
    Get.back();
    try {
      SmartDialog.showLoading();
      await request.sendViewPoint(
        comicId: comicId,
        chapterId: chapters[chapterIndex.value].chapterId,
        content: content,
        page: currentIndex.value + 1,
      );
      loadViewPoints();
    } catch (e) {
      SmartDialog.showToast(e.toString());
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  void keyDown(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.pageUp ||
        (!Platform.isAndroid &&
            settings.readerVolumeKeyTurnPage.value &&
            key == LogicalKeyboardKey.audioVolumeUp)) {
      forwardPageByInput();
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.pageDown ||
        (!Platform.isAndroid &&
            settings.readerVolumeKeyTurnPage.value &&
            key == LogicalKeyboardKey.audioVolumeDown)) {
      nextPageByInput();
    }
  }

  void forwardPageByInput() {
    if (leftHandMode) {
      nextPage();
    } else {
      forwardPage();
    }
  }

  void nextPageByInput() {
    if (leftHandMode) {
      forwardPage();
    } else {
      nextPage();
    }
  }
}
