import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class ComicSelectChapterController extends BaseController {
  final int comicId;
  ComicSelectChapterController(this.comicId);
  final ComicRequest request = ComicRequest();

  RxList<ComicDetailVolume> volumes = RxList<ComicDetailVolume>();

  RxSet<int> chapterIds = RxSet<int>();

  String comicTitle = "";
  String comicCover = "";
  bool islong = false;

  @override
  void onInit() {
    loadDetail();

    super.onInit();
  }

  void refreshV1() async {
    try {
      var result =
          await request.comicDetail(comicId: comicId, priorityV1: true);
      if (result.volumes.isEmpty) {
        SmartDialog.showToast("沒有找到任何章節");
        return;
      }
      comicTitle = result.title;
      comicCover = result.cover;
      islong = result.isLong;
      for (var volume in result.volumes) {
        volume.sortType.value = 1;
        volume.sort();
      }
      volumes.value = result.volumes;
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
      comicTitle = result.title;
      comicCover = result.cover;
      islong = result.isLong;
      if (result.volumes.isEmpty && !result.isHide) {
        refreshV1();
      } else {
        for (var volume in result.volumes) {
          volume.sortType.value = 1;
          volume.sort();
        }
        volumes.value = result.volumes;
      }
    } catch (e) {
      pageError.value = true;
      errorMsg.value = e.toString();
    } finally {
      pageLoadding.value = false;
    }
  }

  void selectItem(ComicDetailChapterItem item) {
    //禁止下載VIP章節
    if (item.isVip) {
      SmartDialog.showToast("請使用動漫之家官方APP下載VIP章節");
      return;
    }
    if (chapterIds.contains(item.chapterId)) {
      chapterIds.remove(item.chapterId);
    } else {
      chapterIds.add(item.chapterId);
    }
  }

  void selectAll() {
    for (var volume in volumes) {
      for (var chapter in volume.chapters) {
        if (chapter.isVip) {
          continue;
        }
        var id = "${comicId}_${chapter.chapterId}";
        if (!ComicDownloadService.instance.downloadIds.contains(id)) {
          chapterIds.add(chapter.chapterId);
        }
      }
    }
  }

  void cleanAll() {
    chapterIds.clear();
  }

  void toDownloadManage() {
    AppNavigator.toComicDownloadManage(1);
  }

  void startDownload() {
    if (chapterIds.isEmpty) {
      SmartDialog.showToast("請選擇需要下載的章節");
      return;
    }
    for (var id in chapterIds) {
      //搜尋章節
      ComicDetailVolume? volume;
      ComicDetailChapterItem? chapter;
      for (var item in volumes) {
        var chapterItem =
            item.chapters.firstWhereOrNull((y) => y.chapterId == id);
        if (chapterItem != null) {
          volume = item;
          chapter = chapterItem;
          break;
        }
      }
      if (volume == null || chapter == null) {
        continue;
      }
      ComicDownloadService.instance.addTask(
        comicId: comicId,
        chapterId: chapter.chapterId,
        chapterSort: chapter.chapterOrder,
        volumeName: volume.title,
        comicTitle: comicTitle,
        comicCover: comicCover,
        chapterName: chapter.chapterTitle,
        isVip: chapter.isVip,
        isLongComic: islong,
      );
    }
    chapterIds.clear();
    SmartDialog.showToast("已新增到下載列表，下載過程中請保持APP在前臺執行");
  }
}
