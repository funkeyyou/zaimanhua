import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zai_x/app/log.dart';

/// 通知渠道
class NotifyChannel {
  const NotifyChannel(this.id, this.name, this.description);

  final String id;
  final String name;
  final String description;

  /// 订阅更新
  static const NotifyChannel subscribe =
      NotifyChannel('subscribe_update', '订阅更新', '订阅的漫画有新话时通知');

  /// 签到结果
  static const NotifyChannel signIn =
      NotifyChannel('sign_in_result', '签到结果', '每日自动签到的结果通知');
}

/// 本地通知（訂閱更新提醒、簽到結果）
/// 主進程與 Workmanager 背景 isolate 都會用到，因此不依賴任何 GetX 服務。
class AppNotification {
  AppNotification._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _inited = false;

  /// 支援通知的平台（Windows 走系統快顯通知）
  static bool get supported =>
      Platform.isAndroid || Platform.isIOS || Platform.isWindows;

  /// 签到结果通知的固定 id（同一天只会有一条）
  static const int kSignInNotifyId = 90001;

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
        windows: WindowsInitializationSettings(
          appName: 'ZAI-X',
          appUserModelId: 'ZAIX.Client.Desktop',
          guid: '6f6b7b0e-6f2f-4a54-9a1c-2b9f8f9d51c7',
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
      if (Platform.isWindows) {
        // Windows 不需要额外授权
        return true;
      }
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
    NotifyChannel channel = NotifyChannel.subscribe,
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
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            styleInformation: const BigTextStyleInformation(''),
          ),
          iOS: const DarwinNotificationDetails(),
          windows: const WindowsNotificationDetails(),
        ),
      );
    } catch (e) {
      Log.logPrint(e);
    }
  }
}
