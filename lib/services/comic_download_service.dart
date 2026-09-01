import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/models/db/comic_download_info.dart';
import 'package:zai_x/models/db/download_status.dart';

import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/download_task/comic_downloader.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

/// 漫畫下載管理
// TODO 整理程式碼
class ComicDownloadService extends GetxService {
  static ComicDownloadService get instance => Get.find<ComicDownloadService>();

  AppSettingsService settings = AppSettingsService.instance;

  late Box<ComicDownloadInfo> box;
  String savePath = "";

  /// 連線資訊監聽
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  /// 當前連線型別
  ConnectivityResult? connectivityType;

  /// 當前正在下載的數量
  var currentNum = 0;

  Future init() async {
    var dir = await getApplicationSupportDirectory();
    box = await Hive.openBox(
      "ZaiComicDownload",
      path: dir.path,
    );
    savePath = await getSavePath();
    //監聽網路狀態
    initConnectivity();
    //更新ID
    updateAllIds();

    updateDownlaoded();
  }

  /// 初始化連線狀態
  void initConnectivity() async {
    try {
      var connectivity = Connectivity();
      connectivitySubscription =
          connectivity.onConnectivityChanged.listen((results) {
        networkChanged(_pickConnectivityType(results));
      });
      connectivityType =
          _pickConnectivityType(await connectivity.checkConnectivity());
      initTasks();
    } catch (e) {
      Log.logPrint(e);
      initTasks();
    }
  }

  /// 網路變更
  void networkChanged(ConnectivityResult type) {
    if (connectivityType != type && type == ConnectivityResult.mobile) {
      //切換至流量
      switchCellular();
    } else if (connectivityType != type && type == ConnectivityResult.none) {
      //網路斷開
      switchNoNetwork();
    } else {
      switchToWiFi();
    }
    connectivityType = type;
  }

  ConnectivityResult _pickConnectivityType(List<ConnectivityResult> results) {
    for (final result in results) {
      if (result != ConnectivityResult.none) {
        return result;
      }
    }
    return ConnectivityResult.none;
  }

  /// 切換至流量
  void switchCellular() {
    if (settings.downloadAllowCellular.value) {
      //允許使用流量,當成WiFi處理
      switchToWiFi();
      return;
    }
    //把任務狀態改為pauseCellular
    for (var item in taskQueues) {
      if (item.status == DownloadStatus.wait ||
          item.status == DownloadStatus.loadding ||
          item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.waitNetwork) {
        item.stopTask();
        item.updateStatus(DownloadStatus.pauseCellular, updateTask: false);
      }
    }
    updateQueue();
  }

  /// 無網路
  void switchNoNetwork() {
    //把任務狀態改為pauseCellular
    for (var item in taskQueues) {
      if (item.status == DownloadStatus.wait ||
          item.status == DownloadStatus.loadding ||
          item.status == DownloadStatus.downloading ||
          item.status == DownloadStatus.pauseCellular) {
        item.stopTask();
        item.updateStatus(DownloadStatus.waitNetwork, updateTask: false);
      }
    }
    updateQueue();
  }

  void switchToWiFi() {
    for (var item in taskQueues) {
      if (item.status == DownloadStatus.pauseCellular ||
          item.status == DownloadStatus.waitNetwork) {
        item.updateStatus(DownloadStatus.wait, updateTask: false);
      }
    }
    updateQueue();
  }

  /// 任務列表
  RxList<ComicDownloader> taskQueues = RxList<ComicDownloader>();

  /// 已下載完成的
  RxList<ComicDownloadedItem> downloaded = RxList<ComicDownloadedItem>();

  /// 已下載、下載中的ID
  RxSet<String> downloadIds = RxSet<String>();

  /// 開始下載任務
  void initTasks() async {
    var tasks = getDownloadingTask();
    for (var item in tasks) {
      //任務已被取消
      if (item.status == DownloadStatus.cancel) {
        box.delete(item.taskId);
        continue;
      }
      //無網路
      if (connectivityType == ConnectivityResult.none) {
        if (item.status != DownloadStatus.pause) {
          item.status = DownloadStatus.waitNetwork;
        }
      } else if (connectivityType == ConnectivityResult.mobile) {
        //不允許使用資料下載
        if (!settings.downloadAllowCellular.value) {
          if (item.status != DownloadStatus.pause) {
            item.status = DownloadStatus.pauseCellular;
          }
        }
      } else {
        //只要不是手動暫停的，全部改為等待，新增到下載佇列
        if (item.status != DownloadStatus.pause) {
          item.status = DownloadStatus.wait;
        }
      }

      taskQueues.add(
        ComicDownloader(item, onUpdateTask: onUpdateTask),
      );
    }
    updateQueue();
  }

  /// 更新佇列
  void updateQueue() {
    //如果下載中任務數小於設定值，新增一個任務
    //如果任務取消或完成，移除佇列
    for (var task in List<ComicDownloader>.from(taskQueues)) {
      //下載完成或取消，移除佇列
      if (task.status == DownloadStatus.complete ||
          task.status == DownloadStatus.cancel) {
        taskQueues.remove(task);
        updateDownlaoded();
        continue;
      }
    }
    var taskNum = settings.downloadComicTaskCount.value;
    var count = taskQueues
        .where((x) =>
            x.status == DownloadStatus.downloading ||
            x.status == DownloadStatus.loadding)
        .length;

    currentNum = count;
    if (taskNum == 0) {
      var ls = taskQueues.where((x) => x.status == DownloadStatus.wait);
      for (var item in ls) {
        item.start();
      }
    } else {
      if (count < taskNum) {
        var ls = taskQueues
            .where((x) => x.status == DownloadStatus.wait)
            .take(taskNum - count);
        for (var item in ls) {
          item.start();
        }
      }
    }
    updateAllIds();
  }

  void updateAllIds() {
    downloadIds.clear();
    downloadIds.addAll(box.keys.map((e) => e.toString()));
  }

  ///讀取未完成的任務
  List<ComicDownloadInfo> getDownloadingTask() {
    return box.values
        .toList()
        .where((x) => x.status != DownloadStatus.complete)
        .toList();
  }

  /// 更新下載完成
  void updateDownlaoded() {
    var downlaodedList = box.values
        .toList()
        .where((x) => x.status == DownloadStatus.complete)
        .toList();
    var comicMap = groupBy(downlaodedList, (ComicDownloadInfo x) => x.comicId);
    List<ComicDownloadedItem> comicList = [];
    for (var comicId in comicMap.keys) {
      var items = comicMap[comicId]!;
      var comicName = items.first.comicName;
      var comicCover = items.first.comicCover;
      var isLongComic = items.first.isLongComic;
      List<ComicDetailVolume> volumes = [];
      var volumeMap = groupBy(items, (ComicDownloadInfo x) => x.volumeName);
      for (var volumeName in volumeMap.keys) {
        var chapters = volumeMap[volumeName]!
            .map(
              (e) => ComicDetailChapterItem(
                chapterId: e.chapterId,
                chapterTitle: e.chapterName,
                updateTime: 0,
                fileSize: 0,
                chapterOrder: e.chapterSort,
              ),
            )
            .toList();
        volumes.add(
          ComicDetailVolume(
            title: volumeName,
            chapters: RxList<ComicDetailChapterItem>(chapters),
          ),
        );
      }
      for (var item in volumes) {
        item.sortType.value = 1;
        item.sort();
      }
      comicList.add(
        ComicDownloadedItem(
          comicName: comicName,
          comicCover: comicCover,
          comicId: comicId,
          chapterCount: items.length,
          volumes: volumes,
          isLongComic: isLongComic,
        ),
      );
    }
    downloaded.value = comicList;
  }

  /// 繼續
  void resumeAll() {
    //更新狀態至等待
    for (var task in taskQueues) {
      if (task.status == DownloadStatus.pause) {
        task.stopTask();
        task.updateStatus(DownloadStatus.wait, updateTask: false);
      }
    }
    updateQueue();
  }

  /// 暫停
  void pauseAll() {
    for (var task in taskQueues) {
      if (task.status != DownloadStatus.pause &&
          task.status != DownloadStatus.error &&
          task.status != DownloadStatus.errorLoad) {
        task.stopTask();
        task.updateStatus(DownloadStatus.pause, updateTask: false);
      }
    }
    updateQueue();
  }

  /// 取消任務
  void cancelTask(ComicDownloader task) {
    // 移除列表
    // 移除資料庫
    // 取消任務
    // 刪除檔案
  }

  /// 新增一個任務
  void addTask({
    required int comicId,
    required int chapterId,
    required String chapterName,
    required int chapterSort,
    required String volumeName,
    required String comicTitle,
    required String comicCover,
    required bool isVip,
    required bool isLongComic,
  }) async {
    var taskId = "${comicId}_$chapterId";
    if (box.containsKey(taskId)) {
      return;
    }
    var info = ComicDownloadInfo(
      addTime: DateTime.now(),
      chapterId: chapterId,
      chapterSort: chapterSort,
      comicCover: comicCover,
      comicId: comicId,
      comicName: comicTitle,
      files: [],
      index: 0,
      savePath: p.join(savePath, taskId),
      status: DownloadStatus.wait,
      taskId: taskId,
      total: 0,
      volumeName: volumeName,
      chapterName: chapterName,
      urls: [],
      isVip: isVip,
      isLongComic: isLongComic,
    );
    await box.put(
      taskId,
      info,
    );
    taskQueues.add(ComicDownloader(info, onUpdateTask: onUpdateTask));
    updateQueue();
  }

  void onUpdateTask() {
    updateQueue();
  }

  /// 讀取儲存目錄
  Future<String> getSavePath() async {
    var dir = await getApplicationSupportDirectory();

    var comicDir = Directory(p.join(dir.path, "comic"));
    if (!await comicDir.exists()) {
      comicDir = await comicDir.create(recursive: true);
    }
    return comicDir.path;
  }

  ///刪除
  void delete(ComicDownloadInfo info) async {
    try {
      var dir = Directory(p.join(savePath, info.taskId));
      await dir.delete(recursive: true);
    } catch (e) {
      Log.logPrint(e);
    } finally {
      await box.delete(info.taskId);
      updateDownlaoded();
    }
    updateAllIds();
  }

  ///刪除
  void deleteChapter(int comicId, int chapterId) async {
    var info = box.get("${comicId}_$chapterId");
    if (info != null) {
      delete(info);
    }
  }
}

class ComicDownloadedItem {
  final String comicName;
  final int comicId;
  final String comicCover;
  final List<ComicDetailVolume> volumes;
  final int chapterCount;
  final bool isLongComic;
  ComicDownloadedItem({
    required this.comicName,
    required this.comicCover,
    required this.comicId,
    required this.chapterCount,
    required this.volumes,
    required this.isLongComic,
  });
}
