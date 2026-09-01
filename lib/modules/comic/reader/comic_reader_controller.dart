import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:extended_image/extended_image.dart';
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
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zai_x/app/i18n.dart';

class ComicReaderController extends BaseController {
  /// 是否为条漫
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

  /// APP设置控制器
  final settings = AppSettingsService.instance;

  /// 预加载控制器
  final PreloadPageController preloadPageController = PreloadPageController();

  /// 上下模式控制器
  final ItemScrollController itemScrollController = ItemScrollController();

  /// 监听上下滚动
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// 章节详情
  Rx<ComicChapterDetail> detail =
      Rx<ComicChapterDetail>(ComicChapterDetail.empty());

  /// 连接信息监听
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  /// 电量信息监听
  StreamSubscription<BatteryState>? batterySubscription;

  /// 当处于放大图片时，锁定滑动手势
  var lockSwipe = false.obs;

  /// 当前章节索引
  var chapterIndex = 0.obs;

  /// 当前页面
  var currentIndex = 0.obs;

  /// 初始化
  var initialIndex = 0;

  /// 進入章節後直接跳到最後一頁（由「上一頁」翻進上一話時使用）
  var openAtLastPage = false;

  /// 雙頁對開目前是否生效（由畫面寬度與設定共同決定）
  var dualPageActive = false.obs;

  /// 頁面分組：雙頁時每組最多 2 頁，單頁時每組 1 頁
  var pageGroups = <List<int>>[].obs;

  /// 是否显示控制器
  var showControls = false.obs;

  /// 阅读方向
  var direction = 0.obs;

  /// 左手模式
  bool get leftHandMode => settings.comicReaderLeftHandMode.value;

  /// 翻页动画
  bool get pageAnimation => settings.comicReaderPageAnimation.value;

  /// 观点、吐槽
  RxList<ComicViewPointModel> viewPoints = RxList<ComicViewPointModel>();

  /// 连接类型
  Rx<ConnectivityResult> connectivityType =
      Rx<ConnectivityResult>(ConnectivityResult.other);

  /// 电量信息
  Rx<int> batteryLevel = 0.obs;

  /// 显示电量
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

    // 翻到接近本话结尾时先把下一话准备好
    ever(currentIndex, (_) => maybePrefetchNextChapter());

    itemPositionsListener.itemPositions.addListener(updateItemPosition);
    if (settings.readerKeepScreenOn.value) {
      WakelockPlus.enable().catchError((e) => Log.logPrint(e));
    }
    settings.applyReaderBrightness();
    loadDetail();
    super.onInit();
  }

  /// 初始化电池信息
  void initBattery() async {
    try {
      //没有电池的Mac似乎会闪退,暂时屏蔽Mac
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

  /// 初始化连接状态
  void initConnectivity() async {
    var connectivity = Connectivity();
    connectivitySubscription =
        connectivity.onConnectivityChanged.listen((results) {
      final result = _pickConnectivityType(results);
      //提醒
      if (connectivityType.value != result &&
          result == ConnectivityResult.mobile) {
        SmartDialog.showToast("您已切换至数据网络，请注意流量消耗".i18n);
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
    WakelockPlus.disable().catchError((e) => Log.logPrint(e));
    settings.restoreSystemBrightness();
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

  /// 加载信息
  void loadDetail() async {
    try {
      var chapterId = chapters[chapterIndex.value].chapterId;
      // 预先抓好的下一话可以直接用，省掉整屏 loading
      var cached = _prefetchedChapters.remove(chapterId);
      pageLoadding.value = cached == null;
      pageError.value = false;
      if (cached == null) {
        detail.value = ComicChapterDetail.empty();
      }
      if (chapters[chapterIndex.value].isVip) {
        //禁止观看VIP章节
        throw AppError("请使用动漫之家官方APP观看VIP章节".i18n);
      }
      loadViewPoints();

      var result = cached ??
          await request.chapterDetail(
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
      if (openAtLastPage) {
        openAtLastPage = false;
        initialIndex = result.pageUrls.isEmpty ? 0 : result.pageUrls.length - 1;
      }
      currentIndex.value = initialIndex;
      if (settings.comicReaderShowViewPoint.value) {
        result.pageUrls.add("TC");
      }

      detail.value = result;
      buildPageGroups();
      Future.delayed(const Duration(milliseconds: 100), () {
        jumpToPage(initialIndex);
      });
      //上传记录
      uploadHistory();
    } catch (e) {
      pageError.value = true;
      errorMsg.value = e.toString();
      setShowControls();
    } finally {
      pageLoadding.value = false;
    }
  }

  /// 预先抓好的章节内容（章节id -> 内容）
  final Map<int, ComicChapterDetail> _prefetchedChapters = {};

  /// 正在预抓的章节id
  int? _prefetchingChapterId;

  /// 快翻到本话结尾时，先把下一话抓回来
  ///
  /// 只抓内容与前两页图片；换话时就不必再等接口和首图，
  /// 整屏 loading 也可以跳过。
  void prefetchNextChapter() async {
    var next = chapterIndex.value + 1;
    if (next >= chapters.length) {
      return;
    }
    var item = chapters[next];
    if (item.isVip ||
        _prefetchingChapterId == item.chapterId ||
        _prefetchedChapters.containsKey(item.chapterId)) {
      return;
    }
    _prefetchingChapterId = item.chapterId;
    try {
      var result = await request.chapterDetail(
        comicId: comicId,
        chapterId: item.chapterId,
        useHD: AppSettingsService.instance.comicReaderHD.value,
      );
      _prefetchedChapters[item.chapterId] = result;
      for (var url in result.pageUrls.take(2)) {
        if (url.isEmpty || url == "TC") {
          continue;
        }
        try {
          await ExtendedNetworkImageProvider(
            url,
            cache: true,
            headers: const {'Referer': "http://www.zaimanhua.com/"},
          ).getNetworkImageData();
        } catch (_) {}
      }
    } catch (e) {
      Log.logPrint(e);
    } finally {
      _prefetchingChapterId = null;
    }
  }

  /// 距离本话结尾还有几页时开始预抓
  static const int kPrefetchAheadPages = 3;

  void maybePrefetchNextChapter() {
    var urls = detail.value.pageUrls;
    if (urls.isEmpty || pageLoadding.value) {
      return;
    }
    if (currentIndex.value < urls.length - kPrefetchAheadPages) {
      return;
    }
    prefetchNextChapter();
  }

  /// 加载吐槽、观点
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
      //SmartDialog.showToast("读取吐槽失败");
      Log.logPrint(e.toString());
    }
  }

  /// 设置显示/隐藏控制按钮
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

  /// 显示目录
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
              title: Text("目录(${chapters.length})".i18n),
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
                    title: Text(item.chapterTitle.i18n),
                    subtitle: item.updateTime != 0
                        ? Text(
                            "更新于${Utils.formatTimestampToDate(item.updateTime)}"
                                .i18n)
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
      SmartDialog.showToast("后面没有了".i18n);
      return;
    }

    chapterIndex.value += 1;
    loadDetail();
  }

  /// 上一章
  void forwardChapter({bool toLastPage = false}) {
    if (chapterIndex.value == 0) {
      SmartDialog.showToast("前面没有了".i18n);
      return;
    }

    openAtLastPage = toLastPage;
    chapterIndex.value -= 1;
    loadDetail();
  }

  /// 下一页
  void nextPage() {
    if (isDualPaging) {
      var group = currentGroupIndex;
      if (group >= pageGroups.length - 1) {
        nextChapter();
      } else {
        jumpToGroup(group + 1, anime: true);
      }
      return;
    }
    var value = currentIndex.value;
    Log.w("下一页$value".i18n);
    var max = detail.value.pageUrls.length;
    if (value >= max - 1) {
      nextChapter();
    } else {
      jumpToPage(value + 1, anime: true);
    }
  }

  /// 上一页
  void forwardPage() {
    if (isDualPaging) {
      var group = currentGroupIndex;
      if (group <= 0) {
        forwardChapter(toLastPage: true);
      } else {
        jumpToGroup(group - 1, anime: true);
      }
      return;
    }
    var value = currentIndex.value;
    Log.w("上一页$value".i18n);
    if (value == 0) {
      forwardChapter(toLastPage: true);
    } else {
      jumpToPage(value - 1, anime: true);
    }
  }

  /// 雙頁對開是否正在生效（僅橫向翻頁時可能為真）
  bool get isDualPaging =>
      dualPageActive.value && direction.value != ReaderDirection.kUpToDown;

  /// 依目前模式重建頁面分組
  void buildPageGroups() {
    var urls = detail.value.pageUrls;
    var groups = <List<int>>[];
    if (urls.isEmpty) {
      pageGroups.value = groups;
      return;
    }
    if (!isDualPaging) {
      for (var i = 0; i < urls.length; i++) {
        groups.add([i]);
      }
      pageGroups.value = groups;
      return;
    }
    // 吐槽頁固定單獨成組
    var hasViewPoint = urls.last == "TC";
    var imageCount = hasViewPoint ? urls.length - 1 : urls.length;
    var i = 0;
    if (settings.comicReaderDualPageCover.value && imageCount > 0) {
      groups.add([0]);
      i = 1;
    }
    while (i < imageCount) {
      if (i + 1 < imageCount) {
        groups.add([i, i + 1]);
        i += 2;
      } else {
        groups.add([i]);
        i += 1;
      }
    }
    if (hasViewPoint) {
      groups.add([urls.length - 1]);
    }
    pageGroups.value = groups;
  }

  /// 頁碼所屬的分組索引
  int groupIndexOf(int page) {
    for (var i = 0; i < pageGroups.length; i++) {
      if (pageGroups[i].contains(page)) {
        return i;
      }
    }
    return 0;
  }

  int get currentGroupIndex => groupIndexOf(currentIndex.value);

  /// 切換雙頁生效狀態，並保持目前頁面位置
  void setDualPageActive(bool value) {
    if (dualPageActive.value == value) {
      return;
    }
    var page = currentIndex.value;
    dualPageActive.value = value;
    buildPageGroups();
    Future.delayed(const Duration(milliseconds: 50), () {
      jumpToPage(page);
    });
  }

  /// 跳轉到指定分組
  void jumpToGroup(int group, {bool anime = false}) {
    if (group < 0 || group >= pageGroups.length) {
      return;
    }
    currentIndex.value = pageGroups[group].first;
    anime && pageAnimation
        ? preloadPageController.animateToPage(group,
            duration: const Duration(milliseconds: 200), curve: Curves.linear)
        : preloadPageController.jumpToPage(group);
  }

  /// 跳转页数
  void jumpToPage(int page, {bool anime = false}) {
    //竖向
    if (direction.value == ReaderDirection.kUpToDown) {
      itemScrollController.jumpTo(index: page);
      return;
    }
    if (isDualPaging) {
      jumpToGroup(groupIndexOf(page), anime: anime);
      return;
    }
    anime && pageAnimation
        ? preloadPageController.animateToPage(page,
            duration: const Duration(milliseconds: 200), curve: Curves.linear)
        : preloadPageController.jumpToPage(page);
  }

  /// 查看吐槽
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
              title: Text("吐槽(${viewPoints.length})".i18n),
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
                                      item.content.i18n,
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
                                      item.content.i18n,
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
                  hintText: "发表吐槽".i18n,
                  contentPadding: AppStyle.edgeInsetsH12,
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: () {
                      sendViewPoint(tucaoController.text);
                    },
                    child: Text("发布".i18n),
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

  /// 显示设置
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
              title: Text("设置".i18n),
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
                    if (settings.brightnessSupported) ...[
                      buildBGItem(
                        child: ListTile(
                          title: Row(
                            children: [
                              Text("屏幕亮度".i18n),
                              const Spacer(),
                              IconButton(
                                tooltip: "跟随系统".i18n,
                                onPressed:
                                    settings.resetReaderBrightnessSetting,
                                icon: const Icon(Remix.refresh_line, size: 18),
                              ),
                            ],
                          ),
                          subtitle: Slider(
                            value: settings.readerBrightness.value < 0
                                ? 0.5
                                : settings.readerBrightness.value,
                            min: 0.05,
                            max: 1.0,
                            onChanged: (e) {
                              settings.setReaderBrightness(e);
                            },
                          ),
                        ),
                      ),
                      AppStyle.vGap12,
                    ],
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderHD.value,
                        onChanged: (e) {
                          settings.setComicReaderHD(e);
                          loadDetail();
                        },
                        title: Text("优先加载高清图".i18n),
                        subtitle: Text("部分单行本可能未分页".i18n),
                      ),
                    ),
                    //AppStyle.vGap12,
                    Visibility(
                      //条漫不允许修改阅读方向
                      visible: !isLongComic,
                      child: Padding(
                        padding: AppStyle.edgeInsetsT12,
                        child: buildBGItem(
                          child: ListTile(
                            title: Text("阅读方向".i18n),
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
                    Visibility(
                      //条漫、上下滚动不适用双页对开
                      visible: !isLongComic &&
                          direction.value != ReaderDirection.kUpToDown,
                      child: Padding(
                        padding: AppStyle.edgeInsetsT12,
                        child: buildBGItem(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                title: Text("双页对开".i18n),
                                subtitle: Text(
                                  dualPageActive.value
                                      ? "当前：双页".i18n
                                      : "当前：单页".i18n,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    buildSelectedButton(
                                      onTap: () {
                                        settings.setComicReaderDualPage(0);
                                      },
                                      selected:
                                          settings.comicReaderDualPage.value ==
                                              0,
                                      child: Text("关闭".i18n),
                                    ),
                                    AppStyle.hGap8,
                                    buildSelectedButton(
                                      onTap: () {
                                        settings.setComicReaderDualPage(1);
                                      },
                                      selected:
                                          settings.comicReaderDualPage.value ==
                                              1,
                                      child: Text("宽屏".i18n),
                                    ),
                                    AppStyle.hGap8,
                                    buildSelectedButton(
                                      onTap: () {
                                        settings.setComicReaderDualPage(2);
                                      },
                                      selected:
                                          settings.comicReaderDualPage.value ==
                                              2,
                                      child: Text("总是".i18n),
                                    ),
                                  ],
                                ),
                              ),
                              if (settings.comicReaderDualPage.value != 0)
                                SwitchListTile(
                                  value:
                                      settings.comicReaderDualPageCover.value,
                                  onChanged: (e) {
                                    settings.setComicReaderDualPageCover(e);
                                    var page = currentIndex.value;
                                    buildPageGroups();
                                    Future.delayed(
                                      const Duration(milliseconds: 50),
                                      () => jumpToPage(page),
                                    );
                                  },
                                  title: Text("封面单独一页".i18n),
                                  subtitle: Text(
                                    "第一页不与第二页并排显示".i18n,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
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
                        title: Text("操作反转".i18n),
                        subtitle: Text("点击左侧下一页，右侧上一页".i18n),
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
                        title: Text("全屏阅读".i18n),
                      ),
                    ),
                    AppStyle.vGap12,
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderShowStatus.value,
                        onChanged: (e) {
                          settings.setComicReaderShowStatus(e);
                        },
                        title: Text("显示状态信息".i18n),
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
                        title: Text("显示吐槽".i18n),
                      ),
                    ),
                    // AppStyle.vGap12,
                    // buildBGItem(
                    //   child: SwitchListTile(
                    //     value: settings.comicReaderOldViewPoint.value,
                    //     onChanged: (e) {
                    //       settings.setComicReaderOldViewPoint(e);
                    //     },
                    //     title: const Text("旧板吐槽"),
                    //   ),
                    // ),
                    AppStyle.vGap12,
                    buildBGItem(
                      child: SwitchListTile(
                        value: settings.comicReaderPageAnimation.value,
                        onChanged: (e) {
                          settings.setComicReaderPageAnimation(e);
                        },
                        title: Text("翻页动画".i18n),
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
    buildPageGroups();
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
    buildPageGroups();
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

  /// 进入全屏
  void setFull() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );
  }

  /// 进入全屏edgeToEdge模式
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
      SmartDialog.showToast("请先登录".i18n);
      return;
    }
    if (content.isEmpty) {
      SmartDialog.showToast("内容不能为空".i18n);
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

  /// 阅读器自己消化的翻页键（不再往下传给滚动动作）
  static bool isTurnPageKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.arrowLeft ||
      key == LogicalKeyboardKey.arrowRight ||
      key == LogicalKeyboardKey.pageUp ||
      key == LogicalKeyboardKey.pageDown;

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
