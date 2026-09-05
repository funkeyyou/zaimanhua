import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/models/db/comic_download_info.dart';
import 'package:zai_x/models/db/download_status.dart';
import 'package:zai_x/models/db/local_favorite.dart';
import 'package:zai_x/models/db/novel_download_info.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/models/db/novel_history.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/services/novel_download_service.dart';
import 'package:zai_x/services/novel_font_service.dart';
import 'package:zai_x/services/reading_stats_service.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:zai_x/routes/app_pages.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'package:workmanager/workmanager.dart';
import 'package:zai_x/services/subscribe_notify_service.dart';
import 'package:zai_x/services/subscribe_notify_scheduler.dart';

/// Workmanager 背景任務進入點（獨立 isolate，不可依賴主進程的 GetX 服務）
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await SubscribeNotifyService.checkAndNotify();
    } catch (e) {
      Log.logPrint(e);
    }
    // 一律回報成功：訂閱檢查失敗不值得讓系統反覆重試而耗電
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await WindowsSingleInstance.ensureSingleInstance(
      [],
      "com.xycz.zmhx",
      onSecondWindow: (args) {
        Log.logPrint(args);
      },
    );
  }
  await Hive.initFlutter();
  //初始化服务
  await initServices();
  //设置状态栏为透明
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemUiOverlayStyle systemUiOverlayStyle = const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
  );
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await Workmanager().initialize(callbackDispatcher);
    } catch (e) {
      Log.logPrint(e);
    }
    unawaited(SubscribeNotifyScheduler.apply());
    unawaited(SubscribeNotifyScheduler.checkOnStart());
    // 登入狀態改變後，背景任務用的 token 也要跟著更新
    UserService.loginedStream.listen((_) => SubscribeNotifyScheduler.apply());
    UserService.logoutStream.listen((_) => SubscribeNotifyScheduler.apply());
  }

  runApp(const DMZJApp());
}

Future initServices() async {
  //包信息
  Utils.packageInfo = await PackageInfo.fromPlatform();
  //本地存储
  Log.d("Init LocalStorage Service");
  await Get.put(LocalStorageService()).init();

  //用户信息
  Log.d("Init User Service");
  Get.put(UserService()).init();

  //注册Hive适配器
  Hive.registerAdapter(ComicHistoryAdapter());
  Hive.registerAdapter(NovelHistoryAdapter());
  Hive.registerAdapter(DownloadStatusAdapter());
  Hive.registerAdapter(ComicDownloadInfoAdapter());
  Hive.registerAdapter(NovelDownloadInfoAdapter());
  Hive.registerAdapter(LocalFavoriteAdapter());
  await Get.put(DBService()).init();

  //DB 就绪后再拉一次远端阅读记录：登录状态是上一步 UserService.init() 读出来的，
  //这里同步可以让换设备后的进度在启动时就合并进本地
  UserService.instance.syncRemoteHistory();

  //初始化设置服务
  await Get.put(NovelFontService()).init();

  //阅读统计（纯本机累计）
  await Get.put(ReadingStatsService()).init();

  Get.put(AppSettingsService());

  //初始化漫画下载服务
  Get.put(ComicDownloadService()).init();
  //初始化小说下载服务
  Get.put(NovelDownloadService()).init();
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();
}

class DMZJApp extends StatelessWidget {
  const DMZJApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ZAI-X',
      scrollBehavior: AppScrollBehavior(),
      theme: AppStyle.lightTheme,
      darkTheme: AppStyle.darkTheme,
      themeMode:
          ThemeMode.values[Get.find<AppSettingsService>().themeMode.value],
      initialRoute: AppPages.kIndex,
      // 内容页跑在子路由、叠在首页之上；Material 预设转场会在动画期间铺一层
      // 不透明底色，返回时就会闪一下空白。改用滑动转场避免这个填色。
      // E-Ink 模式下墨水屏重绘慢，直接不做转场动画。
      defaultTransition: AppSettingsService.instance.eInkMode.value
          ? Transition.noTransition
          : Transition.cupertino,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Material/Cupertino 内建文案(如「查看许可」「关闭」)跟随界面语言设置
      locale: AppI18n.useTraditional
          ? const Locale("zh", "TW")
          : const Locale("zh", "CN"),
      supportedLocales: const [Locale("zh", "CN"), Locale("zh", "TW")],
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      navigatorObservers: [FlutterSmartDialog.observer],
      builder: FlutterSmartDialog.init(
        loadingBuilder: ((msg) => const AppLoaddingWidget()),
        //字体大小不跟随系统变化
        builder: (context, child) => Obx(
          () => MediaQuery(
            data: AppSettingsService.instance.useSystemFontSize.value
                ? MediaQuery.of(context)
                : MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          ),
        ),
      ),
    );
  }
}
