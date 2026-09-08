import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/modules/user/user_home_controller.dart';
import 'package:zai_x/modules/user/user_home_page.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/novel_download_service.dart';
import 'package:zai_x/services/user_service.dart';

void main() {
  testWidgets(
      'account menu remains usable at phone, tablet and large text sizes',
      (tester) async {
    Get.testMode = true;
    Get.put(LocalStorageService());
    Get.put<AppSettingsService>(_Settings());
    final user = Get.put<UserService>(_User());
    Get.put(ComicDownloadService());
    Get.put(NovelDownloadService());
    final menu = Get.put<UserHomeController>(_Menu()) as _Menu;
    addTearDown(() {
      AppI18n.useTraditional = false;
      Get.reset();
      tester.binding.setSurfaceSize(null);
    });
    for (final size in [
      const Size(360, 850),
      const Size(1100, 850),
      const Size(320, 850)
    ]) {
      await tester.binding.setSurfaceSize(size);
      AppI18n.useTraditional = size.width == 320;
      user.logined.value = size.width != 360;
      await tester.pumpWidget(GetMaterialApp(
        theme: AppStyle.lightTheme,
        darkTheme: AppStyle.darkTheme,
        themeMode: size.width == 1100 ? ThemeMode.light : ThemeMode.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(size.width == 320 ? 1.8 : 1)),
          child: child!,
        ),
        home: const UserHomePage(),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('我的订阅'.i18n), findsNothing);
      expect(find.text('浏览记录'.i18n), findsNothing);
      final stats = find.text('阅读统计'.i18n);
      await tester.ensureVisible(stats);
      await tester.tap(stats);
      expect(menu.statsOpened, greaterThan(0));
      await tester.drag(find.byType(ListView), const Offset(0, -2200));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}

class _Settings extends AppSettingsService {
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _User extends UserService {
  @override
  String get nickname => 'Reader with a very long nickname';
  @override
  Future<void> refreshProfile() async {}
}

class _Menu extends UserHomeController {
  int statsOpened = 0;
  @override
  void toReadingStats() => statsOpened++;
}
