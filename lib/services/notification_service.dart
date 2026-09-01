import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zai_x/app/log.dart';

/// 本地通知（目前用於訂閱更新提醒）
/// 主進程與 Workmanager 背景 isolate 都會用到，因此不依賴任何 GetX 服務。
class AppNotification {
  AppNotification._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  /// 订阅更新通知渠道
  static const String channelId = 'subscribe_update';
  static const String channelName = '订阅更新';
  static const String channelDescription = '订阅的漫画有新话时通知';

  /// 目前僅行動平台提供通知
  static bool get supported => Platform.isAndroid || Platform.isIOS;

  static Future<void> init() async {
    if (_inited || !supported) {
      return;
    }
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);
      _inited = true;
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 請求通知權限（Android 13+ / iOS 需要）
  static Future<bool> requestPermission() async {
    if (!supported) {
      return false;
    }
    await init();
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        return await android?.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    } catch (e) {
      Log.logPrint(e);
      return false;
    }
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!supported) {
      return;
    }
    await init();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            styleInformation: BigTextStyleInformation(''),
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      Log.logPrint(e);
    }
  }
}

