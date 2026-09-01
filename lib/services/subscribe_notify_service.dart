import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/requests/common/api.dart';
import 'package:zai_x/services/notification_service.dart';

/// 訂閱更新提醒。
///
/// 主進程與 Workmanager 背景 isolate 共用同一套檢查邏輯，因此完全不碰 GetX，
/// 也不直接讀寫主進程的 Hive box（多 isolate 同時開同一個 box 並不安全），
/// 改用應用私有目錄下的一份小 JSON 當作交換狀態。
class SubscribeNotifyService {
  SubscribeNotifyService._();

  static const String kStateFileName = 'subscribe_notify.json';
  static const String taskName = 'zaix.subscribeUpdateCheck';
  static const int notificationId = 1001;

  static Future<File> _stateFile() async {
    var dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, kStateFileName));
  }

  static Future<Map<String, dynamic>> readState() async {
    try {
      var file = await _stateFile();
      if (!await file.exists()) {
        return <String, dynamic>{};
      }
      var text = await file.readAsString();
      if (text.isEmpty) {
        return <String, dynamic>{};
      }
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } catch (e) {
      Log.logPrint(e);
      return <String, dynamic>{};
    }
  }

  static Future<void> writeState(Map<String, dynamic> state) async {
    try {
      var file = await _stateFile();
      await file.writeAsString(jsonEncode(state), flush: true);
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 主進程把目前的開關與登入狀態同步給背景任務
  static Future<void> syncState({
    required bool enabled,
    required String token,
  }) async {
    var state = await readState();
    state['enabled'] = enabled;
    state['token'] = token;
    await writeState(state);
  }

  /// 執行一次檢查
  ///
  /// * [force] 為 true 時忽略開關（供設定頁的「立即檢查」使用）
  /// * 回傳這次偵測到的更新項目
  static Future<List<SubscribeUpdateItem>> check({bool force = false}) async {
    var state = await readState();
    if (!force && state['enabled'] != true) {
      return const [];
    }
    var token = (state['token'] ?? '').toString();
    if (token.isEmpty) {
      return const [];
    }

    var items = await _fetchUnread(token);
    if (items.isEmpty) {
      return const [];
    }

    // 只提醒「上次看到之後才更新」的項目，避免每次都重複通知同一話
    var seen = Map<String, dynamic>.from(
      (state['seen'] as Map?) ?? <String, dynamic>{},
    );
    var fresh = <SubscribeUpdateItem>[];
    for (var item in items) {
      var key = item.comicId.toString();
      var lastNotified = int.tryParse('${seen[key] ?? 0}') ?? 0;
      if (item.chapterId > lastNotified) {
        fresh.add(item);
      }
      seen[key] = item.chapterId;
    }
    state['seen'] = seen;
    state['lastCheck'] = DateTime.now().millisecondsSinceEpoch;
    await writeState(state);
    return fresh;
  }

  /// 檢查並在有更新時發出通知
  static Future<List<SubscribeUpdateItem>> checkAndNotify(
      {bool force = false}) async {
    var fresh = await check(force: force);
    if (fresh.isEmpty) {
      return fresh;
    }
    var title = '订阅更新';
    var body = fresh.length == 1
        ? '《${fresh.first.title}》更新至 ${fresh.first.chapterName}'
        : '《${fresh.first.title}》等 ${fresh.length} 部作品有更新';
    await AppNotification.show(
      id: notificationId,
      title: title,
      body: body,
    );
    return fresh;
  }

  /// 讀取未讀的漫畫訂閱
  static Future<List<SubscribeUpdateItem>> _fetchUnread(String token) async {
    try {
      var dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
      ));
      var result = await dio.get(
        '${Api.BASE_URL}/comic/sub/list',
        queryParameters: {
          'status': 2,
          'firstLetter': '',
          'page': 1,
          'size': 30,
          'channel': 'android',
          'timestamp': Api.timeStamp,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.plain,
        ),
      );
      var data = result.data;
      var json = data is String ? jsonDecode(data) : data;
      if (json is! Map) {
        return const [];
      }
      if ('${json['errno']}' != '0') {
        Log.d('订阅更新检查失败：${json['errmsg']}');
        return const [];
      }
      var list = (json['data']?['subList'] as List?) ?? const [];
      var items = <SubscribeUpdateItem>[];
      for (var e in list) {
        if (e is! Map) continue;
        items.add(SubscribeUpdateItem(
          comicId: int.tryParse('${e['id']}') ?? 0,
          title: '${e['title'] ?? ''}',
          chapterId: int.tryParse('${e['last_update_chapter_id']}') ?? 0,
          chapterName: '${e['last_update_chapter_name'] ?? ''}',
        ));
      }
      return items;
    } catch (e) {
      Log.logPrint(e);
      return const [];
    }
  }
}

class SubscribeUpdateItem {
  final int comicId;
  final String title;
  final int chapterId;
  final String chapterName;

  SubscribeUpdateItem({
    required this.comicId,
    required this.title,
    required this.chapterId,
    required this.chapterName,
  });
}

