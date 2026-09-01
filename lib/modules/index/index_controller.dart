import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/app/dialog_utils.dart';
import 'package:zai_x/app/event_bus.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/modules/comic/home/comic_home_page.dart';
import 'package:zai_x/modules/news/home/news_home_controller.dart';
import 'package:zai_x/modules/news/home/news_home_page.dart';
import 'package:zai_x/modules/novel/home/novel_home_controller.dart';
import 'package:zai_x/modules/novel/home/novel_home_page.dart';
import 'package:zai_x/modules/user/user_home_page.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:multi_split_view/multi_split_view.dart';

class IndexController extends GetxController {
  final index = 0.obs;
  final showContent = false.obs;
  final GlobalKey indexKey = GlobalKey();
  final GlobalKey subRouterKey = GlobalKey();

  final MultiSplitViewController multiSplitViewController =
      MultiSplitViewController(areas: [
    Area(min: 400, size: 500),
  ]);

  /// 雙擊退出Flag
  bool doubleClickExit = false;

  /// 雙擊退出Timer
  Timer? doubleClickTimer;

  final List<Widget> pages = [
    const ComicHomePage(),
    const SizedBox(),
    const SizedBox(),
    const UserHomePage(),
  ];
  @override
  void onInit() {
    Future.delayed(Duration.zero, showFirstRun);
    super.onInit();
  }

  @override
  void onClose() {}

  void setIndex(int i) {
    if (i == 1 && pages[i] is SizedBox) {
      Get.put(NewsHomeController());
      pages[i] = const NewsHomePage();
    } else if (i == 2 && pages[i] is SizedBox) {
      Get.put(NovelHomeController());
      pages[i] = const NovelHomePage();
    }
    if (index.value == i) {
      EventBus.instance.emit<int>(EventBus.kBottomNavigationBarClicked, i);
    }
    index.value = i;
  }

  void showFirstRun() async {
    if (AppSettingsService.instance.firstRun) {
      AppSettingsService.instance.setNoFirstRun();
      DialogUtils.showStatement();
      Utils.checkUpdate();
    } else {
      Utils.checkUpdate();
    }
  }

  void setDoubleExitFlag() {
    if (doubleClickExit) {
      doubleClickTimer?.cancel();
      Get.back();
      return;
    }
    doubleClickExit = true;
    SmartDialog.showToast("再按一次退出應用");
    doubleClickTimer = Timer(const Duration(seconds: 2), () {
      doubleClickExit = false;
      doubleClickTimer!.cancel();
    });
  }
}
