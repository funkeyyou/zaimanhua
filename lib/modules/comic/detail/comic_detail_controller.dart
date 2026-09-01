import 'dart:async';

import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/event_bus.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/modules/comic/detail/comic_detail_related_page.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class ComicDetailControler extends BaseController {
  final int comicId;
  ComicDetailControler(this.comicId);

  final ComicRequest request = ComicRequest();
  final UserRequest userRequest = UserRequest();

  Rx<ComicDetailInfo> detail = Rx<ComicDetailInfo>(ComicDetailInfo.empty());

  var expandDescription = false.obs;

  /// 是否已訂閱
  var subscribeStatus = false.obs;

  /// 是否已收藏
  /// 收藏是收藏到本地的，訂閱是同步到動漫之家伺服器的
  var favorited = false.obs;

  /// 閱讀記錄
  Rx<ComicHistory?> history = Rx<ComicHistory?>(null);

  /// 更新漫畫記錄
  StreamSubscription<dynamic>? updateComicSubscription;

  @override
  void onInit() {
    updateComicSubscription = EventBus.instance.listen(
      EventBus.kUpdatedComicHistory,
      (id) {
        if (id == comicId) {
          getHistory();
        }
      },
    );
    favorited.value = DBService.instance.hasComicFavorited(comicId: comicId);
    // 從本地讀取訂閱狀態
    subscribeStatus.value =
        UserService.instance.subscribedComicIds.contains(comicId);
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
      userRequest.subscribeRead(id: comicId, type: AppConstant.kTypeComic);
    } catch (e) {
      Log.logPrint(e);
    }
  }

  @override
  void onClose() {
    updateComicSubscription?.cancel();
    super.onClose();
  }

  void getHistory() {
    var comicHistory = DBService.instance.getComicHistory(comicId);
    if (comicHistory != null) {
      history.value = comicHistory;
      history.update((val) {});
    }
  }

  void refreshV1() async {
    try {
      var result =
          await request.comicDetail(comicId: comicId, priorityV1: true);
      if (result.volumes.isEmpty) {
        return;
      }
      if (result.isHide && AppSettingsService.instance.collectHideComic.value) {
        favorite();
      }
      detail.update((val) {
        val!.volumes = result.volumes;
      });
    } catch (e) {
      SmartDialog.showToast("無法獲取章節");
    }
  }

  /// 載入資訊
  void loadDetail() async {
    try {
      pageLoadding.value = true;
      pageError.value = false;
      var result = await request.comicDetail(comicId: comicId);
      detail.value = result;
      if (result.volumes.isEmpty && !result.isHide) {
        refreshV1();
      }
      if (result.isHide && AppSettingsService.instance.collectHideComic.value) {
        favorite();
      }
    } catch (e) {
      pageError.value = true;
      errorMsg.value = e.toString();
    } finally {
      pageLoadding.value = false;
    }
  }

  /// 檢查訂閱狀態
  void loadSubscribeStatus() async {
    try {
      var result = await userRequest.checkSubscribeStatus(
        objId: comicId,
        type: AppConstant.kTypeComic,
      );
      subscribeStatus.value = result;
      if (subscribeStatus.value) {
        UserService.instance.subscribedComicIds.add(comicId);
      } else {
        UserService.instance.subscribedComicIds.remove(comicId);
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 檢視評論
  void comment() {
    AppNavigator.toComment(objId: comicId, type: AppConstant.kTypeComic);
  }

  /// 分享
  void share() {
    if (detail.value.id == 0) {
      return;
    }
    Utils.share(
      "http://m.idmzj.com/info/${detail.value.comicPy}.html",
      content: detail.value.title,
    );
  }

  /// 訂閱
  void subscribe() async {
    var result = await (subscribeStatus.value
        ? UserService.instance
            .cancelSubscribe([comicId], AppConstant.kTypeComic)
        : UserService.instance.addSubscribe([comicId], AppConstant.kTypeComic));
    if (result) {
      subscribeStatus.value = !subscribeStatus.value;
    }
  }

  /// 下載
  void download() {
    AppNavigator.toComicDownloadSelect(comicId);
  }

  /// 開始/繼續閱讀
  void read() {
    if (detail.value.volumes.isEmpty) {
      SmartDialog.showToast("沒有可閱讀的章節");
      return;
    }
    if (detail.value.volumes.first.chapters.isEmpty) {
      SmartDialog.showToast("沒有可閱讀的章節");
      return;
    }
    //查詢記錄
    if (history.value != null && history.value!.chapterId != 0) {
      ComicDetailVolume? volume;
      ComicDetailChapterItem? chapter;
      for (var volumeItem in detail.value.volumes) {
        var chapterItem = volumeItem.chapters.firstWhereOrNull(
          (x) => x.chapterId == history.value!.chapterId,
        );
        if (chapterItem != null) {
          volume = volumeItem;
          chapter = chapterItem;
          break;
        }
      }
      if (volume != null && chapter != null) {
        var chapters = List<ComicDetailChapterItem>.from(volume.chapters);
        //正序
        chapters.sort((a, b) => a.chapterOrder.compareTo(b.chapterOrder));
        AppNavigator.toComicReader(
          comicId: comicId,
          comicTitle: detail.value.title,
          comicCover: detail.value.cover,
          chapters: chapters,
          chapter: chapter,
          isLongComic: detail.value.isLong,
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
    var volume = detail.value.volumes.first;
    var chapters = List<ComicDetailChapterItem>.from(volume.chapters);
    //正序
    chapters.sort((a, b) => a.chapterOrder.compareTo(b.chapterOrder));
    var chapter = chapters.first;
    AppNavigator.toComicReader(
      comicId: comicId,
      comicCover: detail.value.cover,
      comicTitle: detail.value.title,
      chapters: chapters,
      chapter: chapter,
      isLongComic: detail.value.isLong,
    );
  }

  void readChapter(ComicDetailVolume volume, ComicDetailChapterItem item) {
    //禁止觀看VIP章節
    if (item.isVip) {
      SmartDialog.showToast("請使用動漫之家官方APP觀看VIP章節");
      return;
    }
    var chapters = List<ComicDetailChapterItem>.from(volume.chapters);
    //正序
    chapters.sort((a, b) => a.chapterOrder.compareTo(b.chapterOrder));
    AppNavigator.toComicReader(
      comicId: comicId,
      comicCover: detail.value.cover,
      comicTitle: detail.value.title,
      chapters: chapters,
      chapter: item,
      isLongComic: detail.value.isLong,
    );
  }

  void related() async {
    try {
      SmartDialog.showLoading();
      var data = await request.related(id: comicId);
      SmartDialog.dismiss(status: SmartStatus.loading);
      AppNavigator.showBottomSheet(
        ComicDetailRelatedPage(data),
        isScrollControlled: true,
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }

  void toAuthorDetail(ComicDetailTag e) {
    if (e.tagId == 0) {
      //神隱漫畫沒有ID，直接跳轉搜尋
      AppNavigator.toComicSearch(keyword: e.tagName);
    } else {
      AppNavigator.toComicAuthorDetail(e.tagId);
    }
  }

  void toCategoryDetail(ComicDetailTag e) {
    if (e.tagId == 0) {
      //神隱漫畫沒有ID，直接跳轉搜尋
      AppNavigator.toComicSearch(keyword: e.tagName);
    } else {
      AppNavigator.toComicCategoryDetail(e.tagId);
    }
  }

  void favorite() {
    if (detail.value.id == 0) {
      return;
    }
    if (!DBService.instance.hasComicFavorited(comicId: comicId)) {
      DBService.instance.putComicFavorite(
        comicId: comicId,
        title: detail.value.title,
        cover: detail.value.cover,
      );
      favorited.value = true;
      SmartDialog.showToast("已將漫畫新增至本地收藏");
    }
  }

  void cancelFavorite() {
    DBService.instance.removeComicFavorite(comicId: comicId);
    favorited.value = false;
    SmartDialog.showToast("已從本地收藏刪除漫畫");
  }
}
