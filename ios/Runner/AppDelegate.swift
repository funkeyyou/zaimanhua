import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// 必須與 lib/services/subscribe_notify_service.dart 的 taskName 一致，
  /// 並列在 Info.plist 的 BGTaskSchedulerPermittedIdentifiers 裡
  static let subscribeTaskId = "zaix.subscribeUpdateCheck"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 背景任務在獨立的 Flutter 引擎裡執行，需要另外註冊外掛（通知、Hive 路徑等）
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // iOS 只允許在啟動完成前登記 BGTaskScheduler 任務；實際排程由 Dart 端決定。
    // 系統會依使用習慣決定何時執行，6 小時只是最早可開始的時間
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: AppDelegate.subscribeTaskId,
      earliestBeginInSeconds: NSNumber(value: 6 * 60 * 60)
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
