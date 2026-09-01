import 'dart:async';

import 'package:zai_x/app/event_bus.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class ComicDownloadedDetailController extends GetxController {
  final ComicDownloadedItem info;
  ComicDownloadedDetailController(this.info);

  /// 閱讀記錄
  Rx<ComicHistory?> history = Rx<ComicHistory?>(null);

  /// 更新漫畫記錄
  StreamSubscription<dynamic>? updateComicSubscription;

  /// 編輯模式
  var editMode = false.obs;

  RxSet<ComicDetailChapterItem> selectItems = RxSet<ComicDetailChapterItem>();

  @override
  void onInit() {
    updateComicSubscription = EventBus.instance.listen(
      EventBus.kUpdatedComicHistory,
      (id) {
        if (id == info.comicId) {
          getHistory();
        }
      },
    );

    getHistory();

    super.onInit();
  }

  @override
  void onClose() {
    updateComicSubscription?.cancel();
    super.onClose();
  }

  void getHistory() {
    var comicHistory = DBService.instance.getComicHistory(info.comicId);
    if (comicHistory != null) {
      history.value = comicHistory;
      history.update((val) {});
    }
  }

  /// 開始/繼續閱讀
  void read() {
    if (info.volumes.isEmpty) {
      SmartDialog.showToast("沒有可閱讀的章節");
      return;
    }
    if (info.volumes.first.chapters.isEmpty) {
      SmartDialog.showToast("沒有可閱讀的章節");
      return;
    }
    //查詢記錄
    if (history.value != null && history.value!.chapterId != 0) {
      ComicDetailVolume? volume;
      ComicDetailChapterItem? chapter;
      for (var volumeItem in info.volumes) {
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
          comicId: info.comicId,
          comicTitle: info.comicName,
          comicCover: info.comicCover,
          chapters: chapters,
          chapter: chapter,
          isLongComic: info.isLongComic,
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
    var volume = info.volumes.first;
    var chapters = List<ComicDetailChapterItem>.from(volume.chapters);
    //正序
    chapters.sort((a, b) => a.chapterOrder.compareTo(b.chapterOrder));
    var chapter = chapters.first;
    AppNavigator.toComicReader(
      comicId: info.comicId,
      comicCover: info.comicCover,
      comicTitle: info.comicName,
      chapters: chapters,
      chapter: chapter,
      isLongComic: info.isLongComic,
    );
  }

  void readChapter(ComicDetailVolume volume, ComicDetailChapterItem item) {
    var chapters = List<ComicDetailChapterItem>.from(volume.chapters);
    //正序
    chapters.sort((a, b) => a.chapterOrder.compareTo(b.chapterOrder));
    AppNavigator.toComicReader(
      comicId: info.comicId,
      comicCover: info.comicCover,
      comicTitle: info.comicName,
      chapters: chapters,
      chapter: item,
      isLongComic: info.isLongComic,
    );
  }

  void toDetail() {
    AppNavigator.toComicDetail(info.comicId);
  }

  void toAddDownload() {
    AppNavigator.toComicDownloadSelect(info.comicId);
  }

  void setEditMode() {
    selectItems.clear();
    editMode.value = true;
  }

  void exitEditMode() {
    selectItems.clear();
    editMode.value = false;
  }

  var isSelectAll = false;
  void selectAll() {
    if (isSelectAll) {
      selectItems.clear();
      isSelectAll = false;
      return;
    }
    for (var volume in info.volumes) {
      for (var chapter in volume.chapters) {
        selectItems.add(chapter);
      }
    }
    isSelectAll = true;
  }

  void delete() {
    for (var item in selectItems) {
      ComicDownloadService.instance.deleteChapter(info.comicId, item.chapterId);
    }
    exitEditMode();
    SmartDialog.showToast("刪除成功");
    AppNavigator.closePage();
  }

  void selectItem(ComicDetailChapterItem item) {
    if (selectItems.contains(item)) {
      selectItems.remove(item);
    } else {
      selectItems.add(item);
    }
  }
}
