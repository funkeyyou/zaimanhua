import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/app/dialog_utils.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/user_service.dart';

import 'package:get/get.dart';

class UserHomeController extends GetxController {
  final AppSettingsService settings = AppSettingsService.instance;

  @override
  void onInit() {
    UserService.instance.refreshProfile();
    super.onInit();
  }

  /// 登入
  void login() {
    UserService.instance.login();
  }

  /// 退出登入
  void logout() async {
    var result = await DialogUtils.showAlertDialog(
      "確定要退出登入嗎？",
      title: "退出登入",
    );
    if (result) {
      UserService.instance.logout();
    }
  }

  /// 主題設定
  void setTheme() {
    settings.changeTheme();
  }

  /// 關於我們
  void about() {
    Get.dialog(AboutDialog(
      applicationIcon: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withValues(alpha: .2),
          ),
          borderRadius: AppStyle.radius12,
        ),
        child: ClipRRect(
          borderRadius: AppStyle.radius12,
          child: Image.asset(
            'assets/images/logo.png',
            width: 48,
            height: 48,
          ),
        ),
      ),
      applicationName: "ZAI-X",
      applicationVersion: "Ver ${Utils.packageInfo.version}",
      applicationLegalese: "@xiaoyaocz",
    ));
  }

  /// 檢查更新
  void checkUpdate() {
    Utils.checkUpdate(showMsg: true);
  }

  /// 訂閱
  void toUserSubscribe() async {
    if (!await UserService.instance.login()) {
      return;
    }
    AppNavigator.toUserSubscribe();
  }

  /// 歷史
  void toUserHistory() async {
    if (!await UserService.instance.login()) {
      return;
    }
    AppNavigator.toUserHistory();
  }

  /// 本機歷史
  void toLocalHistory() async {
    if (!await UserService.instance.login()) {
      return;
    }
    AppNavigator.toUserHistory();
  }

  void toSettings() async {
    AppNavigator.toSettings();
  }

  void comicDownload() {
    AppNavigator.toComicDownloadManage(0);
  }

  void novelDownload() {
    AppNavigator.toNovelDownloadManage(0);
  }

  void userComment() {
    AppNavigator.toUserComment(int.tryParse(UserService.instance.userId) ?? 0);
  }

  void toFavorite() {
    AppNavigator.tolocalFavorite();
  }
}
