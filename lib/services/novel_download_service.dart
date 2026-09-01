import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/db/novel_download_info.dart';
import 'package:zai_x/models/db/download_status.dart';
import 'package:zai_x/models/novel/novel_detail_model.dart';

import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/download_task/novel_downloader.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

/// 小說下載管理
// TODO 整理程式碼
class NovelDownloadService extends GetxService {
  static NovelDownloadService get instance => Get.find<NovelDownloadService>();

  AppSettingsService settings = AppSettingsService.instance;

  late Box<NovelDownloadInfo> box;
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
      "NovelDownload",
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
  RxList<NovelDownloader> taskQueues = RxList<NovelDownloader>();

  /// 已下載完成的
  RxList<NovelDownloadedItem> downloaded = RxList<NovelDownloadedItem>();

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
        NovelDownloader(item, onUpdateTask: onUpdateTask),
      );
    }
    updateQueue();
  }

  /// 更新佇列
  void updateQueue() {
    //如果下載中任務數小於設定值，新增一個任務
    //如果任務取消或完成，移除佇列
    for (var task in List<NovelDownloader>.from(taskQueues)) {
      //下載完成或取消，移除佇列
      if (task.status == DownloadStatus.complete ||
          task.status == DownloadStatus.cancel) {
        taskQueues.remove(task);
        updateDownlaoded();
        continue;
      }
    }
    var taskNum = settings.downloadNovelTaskCount.value;
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
            .take(taskNum - count)
            .toList();
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
  List<NovelDownloadInfo> getDownloadingTask() {
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
    var novelMap = groupBy(downlaodedList, (NovelDownloadInfo x) => x.novelId);
    List<NovelDownloadedItem> novelList = [];
    for (var novelId in novelMap.keys) {
      var items = novelMap[novelId]!;
      var novelName = items.first.novelName;
      var novelCover = items.first.novelCover;

      List<NovelDetailVolume> volumes = [];
      var volumeMap = groupBy(items, (NovelDownloadInfo x) => x.volumeID);
      for (var volumeID in volumeMap.keys) {
        var chapters = volumeMap[volumeID]!
            .map(
              (e) => NovelDetailChapter(
                chapterId: e.chapterId,
                chapterName: e.chapterName,
                volumeId: e.volumeID,
                volumeName: e.volumeName,
                volumeOrder: e.volumeOrder,
                chapterOrder: e.chapterSort,
              ),
            )
            .toList();
        chapters.sort((a, b) => a.chapterOrder.compareTo(b.chapterOrder));
        volumes.add(
          NovelDetailVolume(
            volumeName: chapters.first.volumeName,
            volumeId: chapters.first.volumeId,
            volumeOrder: chapters.first.volumeOrder,
            chapters: chapters,
          ),
        );
      }
      volumes.sort((a, b) => a.volumeOrder.compareTo(b.volumeOrder));
      novelList.add(
        NovelDownloadedItem(
          novelName: novelName,
          novelCover: novelCover,
          novelId: novelId,
          chapterCount: items.length,
          volumes: volumes,
        ),
      );
    }
    downloaded.value = novelList;
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

  /// 新增一個任務
  void addTask({
    required int novelId,
    required int chapterId,
    required String chapterName,
    required int chapterSort,
    required int volumeId,
    required int volumeOrder,
    required String volumeName,
    required String novelTitle,
    required String novelCover,
    required bool isVip,
  }) async {
    var taskId = "${novelId}_${volumeId}_$chapterId";
    if (box.containsKey(taskId)) {
      return;
    }
    var info = NovelDownloadInfo(
      addTime: DateTime.now(),
      chapterId: chapterId,
      chapterSort: chapterSort,
      novelCover: novelCover,
      novelId: novelId,
      novelName: novelTitle,
      savePath: p.join(savePath, taskId),
      status: DownloadStatus.wait,
      taskId: taskId,
      volumeName: volumeName,
      chapterName: chapterName,
      isVip: isVip,
      progress: 0,
      fileName: '',
      imageFiles: [],
      isImage: false,
      volumeID: volumeId,
      volumeOrder: volumeOrder,
      imageUrls: [],
    );
    await box.put(
      taskId,
      info,
    );
    taskQueues.add(NovelDownloader(info, onUpdateTask: onUpdateTask));
    updateQueue();
  }

  void onUpdateTask() {
    updateQueue();
  }

  /// 讀取儲存目錄
  Future<String> getSavePath() async {
    var dir = await getApplicationSupportDirectory();

    var novelDir = Directory(p.join(dir.path, "novel"));
    if (!await novelDir.exists()) {
      novelDir = await novelDir.create(recursive: true);
    }
    return novelDir.path;
  }

  ///刪除
  void delete(NovelDownloadInfo info) async {
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
  void deleteChapter(int novelId, int volumeId, int chapterId) async {
    var info = box.get("${novelId}_${volumeId}_$chapterId");
    if (info != null) {
      delete(info);
    }
  }
}

class NovelDownloadedItem {
  final String novelName;
  final int novelId;
  final String novelCover;
  final List<NovelDetailVolume> volumes;
  final int chapterCount;
  NovelDownloadedItem({
    required this.novelName,
    required this.novelCover,
    required this.novelId,
    required this.chapterCount,
    required this.volumes,
  });
}
