import 'dart:async';

import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/event_bus.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/db/novel_history.dart';
import 'package:zai_x/models/novel/novel_detail_model.dart';
import 'package:zai_x/requests/novel_request.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class NovelDetailControler extends BaseController {
  final int novelId;
  NovelDetailControler(this.novelId);

  final NovelRequest request = NovelRequest();
  final UserRequest userRequest = UserRequest();

  Rx<NovelDetailInfo> detail = Rx<NovelDetailInfo>(NovelDetailInfo.empty());

  var expandDescription = false.obs;

  /// 是否已訂閱
  var subscribeStatus = false.obs;

  /// 閱讀記錄
  Rx<NovelHistory?> history = Rx<NovelHistory?>(null);

  /// 更新小說記錄
  StreamSubscription<dynamic>? updateNovelSubscription;

  @override
  void onInit() {
    updateNovelSubscription = EventBus.instance.listen(
      EventBus.kUpdatedNovelHistory,
      (id) {
        if (id == novelId) {
          getHistory();
        }
      },
    );
    // 從本地讀取訂閱狀態
    subscribeStatus.value =
        UserService.instance.subscribedNovelIds.contains(novelId);
    getHistory();
    loadDetail();
    loadSubscribeStatus();
    //updateSubscribeRead();
    super.onInit();
  }

  void refreshDetail() {
    getHistory();
    loadDetail();
    loadSubscribeStatus();
  }

  /// 更新訂閱的閱讀狀態
  void updateSubscribeRead() {
    try {
      userRequest.subscribeRead(id: novelId, type: AppConstant.kTypeNovel);
    } catch (e) {
      Log.logPrint(e);
    }
  }

  @override
  void onClose() {
    updateNovelSubscription?.cancel();
    super.onClose();
  }

  void getHistory() {
    var novelHistory = DBService.instance.getNovelHistory(novelId);
    if (novelHistory != null) {
      history.value = novelHistory;
      history.update((val) {});
    }
  }

  /// 載入資訊
  void loadDetail() async {
    try {
      pageLoadding.value = true;
      pageError.value = false;
      var result = await request.novelDetail(novelId: novelId);

      detail.value = NovelDetailInfo.fromJson(result.data);
      await loadChapter();
    } catch (e) {
      pageError.value = true;
      errorMsg.value = e.toString();
    } finally {
      pageLoadding.value = false;
    }
  }

  Future loadChapter() async {
    try {
      var result = await request.novelChapter(novelId: novelId);
      detail.value.volume.value =
          result.map((e) => NovelDetailVolume.fromJson(e)).toList();
    } catch (e) {
      SmartDialog.showToast("無法讀取小說章節:$e");
    }
  }

  /// 檢查訂閱狀態
  void loadSubscribeStatus() async {
    try {
      var result = await userRequest.checkSubscribeStatus(
        objId: novelId,
        type: AppConstant.kTypeNovel,
      );
      subscribeStatus.value = result;
      if (subscribeStatus.value) {
        UserService.instance.subscribedNovelIds.add(novelId);
      } else {
        UserService.instance.subscribedNovelIds.remove(novelId);
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 檢視評論
  void comment() {
    AppNavigator.toComment(objId: novelId, type: AppConstant.kTypeNovel);
  }

  ///  分享
  void share() {
    Utils.share(
      "http://q.idmzj.com/$novelId/index.shtml",
      content: detail.value.name,
    );
  }

  /// 訂閱
  void subscribe() async {
    var result = await (subscribeStatus.value
        ? UserService.instance
            .cancelSubscribe([novelId], AppConstant.kTypeNovel)
        : UserService.instance.addSubscribe([novelId], AppConstant.kTypeNovel));
    if (result) {
      subscribeStatus.value = !subscribeStatus.value;
    }
  }

  /// 下載
  void download() {
    AppNavigator.toNovelDownloadSelect(novelId);
  }

  /// 開始/繼續閱讀
  void read() {
    if (detail.value.volume.isEmpty) {
      SmartDialog.showToast("沒有可閱讀的章節");
      return;
    }
    if (detail.value.volume.first.chapters.isEmpty) {
      SmartDialog.showToast("沒有可閱讀的章節");
      return;
    }
    //查詢記錄
    if (history.value != null && history.value!.chapterId != 0) {
      NovelDetailChapter? chapter;
      for (var volumeItem in detail.value.volume) {
        var chapterItem = volumeItem.chapters.firstWhereOrNull(
          (x) => x.chapterId == history.value!.chapterId,
        );
        if (chapterItem != null) {
          chapter = chapterItem;
          break;
        }
      }
      if (chapter != null) {
        List<NovelDetailChapter> chapters = [];
        for (var volume in detail.value.volume) {
          chapters.addAll(volume.chapters);
        }

        AppNavigator.toNovelReader(
          novelId: novelId,
          novelCover: detail.value.cover,
          novelTitle: detail.value.name,
          chapter: chapter,
          chapters: chapters,
        );
      } else {
        SmartDialog.showToast("未找到歷史記錄對應章節，將從頭開始閱讀");
        readStart();
      }
    } else {
      readStart();
    }
  }

  void readStart() {
    //從頭開始
    List<NovelDetailChapter> chapters = [];
    for (var volume in detail.value.volume) {
      chapters.addAll(volume.chapters);
    }
    var chapter = chapters.first;
    AppNavigator.toNovelReader(
      novelId: novelId,
      novelCover: detail.value.cover,
      novelTitle: detail.value.name,
      chapter: chapter,
      chapters: chapters,
    );
  }

  void readChapter(NovelDetailVolume volume, NovelDetailChapter item) {
    List<NovelDetailChapter> chapters = [];
    for (var volume in detail.value.volume) {
      chapters.addAll(volume.chapters);
    }

    AppNavigator.toNovelReader(
      novelId: novelId,
      novelCover: detail.value.cover,
      novelTitle: detail.value.name,
      chapters: chapters,
      chapter: item,
    );
  }

  void toAuthorDetail(String e) {
    AppNavigator.toNovelSearch(keyword: e);
  }

  void toCategoryDetail(String e) {
    AppNavigator.toNovelSearch(keyword: e);
  }
}
