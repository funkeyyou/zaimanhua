import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zai_x/app/event_bus.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/models/db/comic_download_info.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/cbz_export_service.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicDownloadedDetailController extends GetxController {
  final ComicDownloadedItem info;
  ComicDownloadedDetailController(this.info);

  /// 阅读记录
  Rx<ComicHistory?> history = Rx<ComicHistory?>(null);

  /// 更新漫画记录
  StreamSubscription<dynamic>? updateComicSubscription;

  /// 编辑模式
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

  /// 开始/继续阅读
  void read() {
    if (info.volumes.isEmpty) {
      SmartDialog.showToast("没有可阅读的章节".i18n);
      return;
    }
    if (info.volumes.first.chapters.isEmpty) {
      SmartDialog.showToast("没有可阅读的章节".i18n);
      return;
    }
    //查找记录
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
        SmartDialog.showToast("未找到历史记录对应章节，将从头开始阅读".i18n);
        readStart();
      }
    } else {
      readStart();
    }
  }

  void readStart() {
    //从头开始
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
    SmartDialog.showToast("删除成功".i18n);
    AppNavigator.closePage();
  }

  void selectItem(ComicDetailChapterItem item) {
    if (selectItems.contains(item)) {
      selectItems.remove(item);
    } else {
      selectItems.add(item);
    }
  }

  /// 匯出選取章節為 cbz
  ///
  /// 下載檔案放在 App 私有目錄，桌面版讓使用者選資料夾直接寫出去，
  /// 行動版先產生在 App 目錄再走系統分享，讓使用者自己決定存哪。
  void exportCbz() async {
    if (selectItems.isEmpty) {
      SmartDialog.showToast('请先选择章节'.i18n);
      return;
    }
    var chapters = <ComicDownloadInfo>[];
    for (var item in selectItems) {
      var download = ComicDownloadService.instance
          .getDownloadInfo(info.comicId, item.chapterId);
      if (download != null) {
        chapters.add(download);
      }
    }
    if (chapters.isEmpty) {
      SmartDialog.showToast('没有可导出的章节'.i18n);
      return;
    }
    var mobile = Platform.isAndroid || Platform.isIOS;
    String outputDir;
    if (mobile) {
      var dir = await getApplicationDocumentsDirectory();
      outputDir = p.join(dir.path, 'cbz');
    } else {
      var picked = await getDirectoryPath();
      if (picked == null) {
        return;
      }
      outputDir = picked;
    }
    try {
      SmartDialog.showLoading(msg: '导出中...'.i18n);
      var files = await CbzExportService.exportChapters(
        chapters: chapters,
        outputDir: outputDir,
      );
      SmartDialog.dismiss(status: SmartStatus.loading);
      if (files.isEmpty) {
        SmartDialog.showToast('没有可导出的章节'.i18n);
        return;
      }
      exitEditMode();
      if (mobile) {
        await SharePlus.instance.share(
          ShareParams(files: files.map((e) => XFile(e)).toList()),
        );
      } else {
        SmartDialog.showToast('已导出到：$outputDir'.i18n);
      }
    } catch (e) {
      SmartDialog.dismiss(status: SmartStatus.loading);
      SmartDialog.showToast(e.toString());
    }
  }
}
