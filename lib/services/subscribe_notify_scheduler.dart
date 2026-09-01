import 'dart:io';

import 'package:workmanager/workmanager.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/notification_service.dart';
import 'package:zai_x/services/subscribe_notify_service.dart';
import 'package:zai_x/services/user_service.dart';

/// 訂閱更新提醒的排程與狀態同步（主進程專用）
class SubscribeNotifyScheduler {
  SubscribeNotifyScheduler._();

  static bool get platformSupported => Platform.isAndroid || Platform.isIOS;

  /// 依目前設定與登入狀態，同步狀態檔並註冊／取消背景任務
  static Future<void> apply() async {
    if (!platformSupported) {
      return;
    }
    var settings = AppSettingsService.instance;
    var enabled = settings.subscribeNotify.value;
    var token = UserService.instance.dmzjToken;
    await SubscribeNotifyService.syncState(
      enabled: enabled && token.isNotEmpty,
      token: token,
    );
    try {
      if (enabled && token.isNotEmpty) {
        await Workmanager().registerPeriodicTask(
          SubscribeNotifyService.taskName,
          SubscribeNotifyService.taskName,
          frequency: Duration(hours: settings.subscribeNotifyHours.value),
          initialDelay: const Duration(minutes: 15),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        );
      } else {
        await Workmanager()
            .cancelByUniqueName(SubscribeNotifyService.taskName);
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// App 啟動後在前景跑一次檢查。
  /// 背景排程會被各家 ROM 省電策略延後甚至擋掉，前景這一次可確保開啟 App 時
  /// 至少能拿到提醒。
  static Future<void> checkOnStart() async {
    if (!platformSupported) {
      return;
    }
    if (!AppSettingsService.instance.subscribeNotify.value) {
      return;
    }
    await Future.delayed(const Duration(seconds: 8));
    try {
      await SubscribeNotifyService.checkAndNotify();
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 開關切換：需要時要求通知權限
  static Future<bool> setEnabled(bool value) async {
    if (value && !await AppNotification.requestPermission()) {
      return false;
    }
    AppSettingsService.instance.setSubscribeNotify(value);
    await apply();
    return true;
  }
}

