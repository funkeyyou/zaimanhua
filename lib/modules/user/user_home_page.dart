import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zai_x/app/app_color.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/dialog_utils.dart';
import 'package:zai_x/modules/user/user_home_controller.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/services/novel_download_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/widgets/user_photo.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zai_x/app/i18n.dart';

class UserHomePage extends GetView<UserHomeController> {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.isDarkMode ? Colors.black : AppColor.backgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Get.isDarkMode
            ? SystemUiOverlayStyle.light.copyWith(
                systemNavigationBarColor: Colors.transparent,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                systemNavigationBarColor: Colors.transparent,
              ),
        child: SafeArea(
          child: EasyRefresh(
            header: const MaterialHeader(),
            onRefresh: UserService.instance.refreshProfile,
            child: ListView(
              padding: AppStyle.edgeInsetsA4,
              children: [
                AppStyle.vGap12,
                // 用户名、头像
                Obx(
                  () => Visibility(
                    visible: UserService.instance.logined.value,
                    child: ListTile(
                      leading: UserPhoto(
                        url: UserService.instance.photo,
                        size: 48,
                      ),
                      title: Text.rich(
                        TextSpan(
                          text: UserService
                                  .instance.userProfile.value?.nickname ??
                              UserService.instance.nickname,
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Visibility(
                                visible: (UserService.instance.userProfile.value
                                        ?.userfeeinfo?.isVip ??
                                    false),
                                child: Padding(
                                  padding: AppStyle.edgeInsetsL4,
                                  child: Image.asset(
                                    "assets/images/vip.png",
                                    height: 16,
                                  ),
                                ),
                              ),
                            ),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Builder(builder: (context) {
                                final level = UserService
                                    .instance.userProfile.value?.userLevel;
                                if (level == null) return const SizedBox.shrink();
                                return Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.15),
                                    border: Border.all(
                                        color: Colors.blue, width: 0.8),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Lv.$level",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        UserService.instance.isVip
                            ? UserService.instance.vipInfo
                            : UserService.instance.sign,
                        style: Get.textTheme.bodySmall,
                      ),
                      trailing: IconButton(
                        onPressed: controller.logout,
                        icon: const Icon(Remix.logout_box_r_line),
                      ),
                    ),
                  ),
                ),
                Obx(
                  () => Visibility(
                    visible: !UserService.instance.logined.value,
                    child: ListTile(
                      leading: const UserPhoto(
                        url: "",
                        size: 48,
                      ),
                      title: Text(
                        "未登录".i18n,
                        style: TextStyle(height: 1.0),
                      ),
                      subtitle: Text(
                        "点击前往登录".i18n,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.login,
                    ),
                  ),
                ),
                Obx(
                  () => _buildCard(
                    context,
                    children: [
                      Visibility(
                        visible: UserService.instance.logined.value,
                        child: ListTile(
                          leading: const Icon(Remix.heart_line),
                          title: Text("我的订阅".i18n),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: controller.toUserSubscribe,
                        ),
                      ),
                      Visibility(
                        visible: UserService.instance.logined.value,
                        child: ListTile(
                          leading: const Icon(Remix.history_line),
                          title: Text("浏览记录".i18n),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: controller.toUserHistory,
                        ),
                      ),
                      // Visibility(
                      //   visible: UserService.instance.logined.value,
                      //   child: ListTile(
                      //     leading: const Icon(Remix.chat_smile_2_line),
                      //     title: const Text("我的评论"),
                      //     trailing: const Icon(
                      //       Icons.chevron_right,
                      //       color: Colors.grey,
                      //     ),
                      //     onTap: controller.userComment,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                _buildCard(
                  context,
                  children: [
                    ListTile(
                      leading: const Icon(Remix.star_line),
                      title: Text("本机收藏".i18n),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.toFavorite,
                    ),
                    ListTile(
                      leading: const Icon(Remix.download_line),
                      title: Text("漫画下载".i18n),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(
                            () => Visibility(
                              visible: ComicDownloadService
                                  .instance.taskQueues.isNotEmpty,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: AppStyle.radius24,
                                ),
                                width: 20,
                                height: 20,
                                child: Center(
                                  child: Text(
                                    "${ComicDownloadService.instance.taskQueues.length}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      onTap: controller.comicDownload,
                    ),
                    ListTile(
                      leading: const Icon(Remix.download_line),
                      title: Text("小说下载".i18n),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Obx(
                            () => Visibility(
                              visible: NovelDownloadService
                                  .instance.taskQueues.isNotEmpty,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: AppStyle.radius24,
                                ),
                                width: 20,
                                height: 20,
                                child: Center(
                                  child: Text(
                                    "${NovelDownloadService.instance.taskQueues.length}",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      onTap: controller.novelDownload,
                    ),
                  ],
                ),
                _buildCard(
                  context,
                  children: [
                    ListTile(
                      leading: const Icon(Remix.calendar_check_line),
                      title: Text("每日签到".i18n),
                      subtitle: Text("登录后启动 App 也会自动签到".i18n),
                      trailing: Obx(() {
                        final signed =
                            UserService.instance.userProfile.value?.isSign ==
                                true;
                        return Text(
                          signed ? "已签到".i18n : "去签到".i18n,
                          style: TextStyle(
                            fontSize: 14,
                            color: signed ? Colors.green : Colors.grey,
                          ),
                        );
                      }),
                      onTap: () => UserService.instance.manualSignIn(),
                    ),
                    ListTile(
                      leading: Icon(
                          Get.isDarkMode ? Remix.moon_line : Remix.sun_line),
                      title: Text("显示主题".i18n),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.setTheme,
                    ),
                    ListTile(
                      leading: const Icon(Remix.bar_chart_2_line),
                      title: Text("阅读统计".i18n),
                      subtitle: Text("只在本机累计，不会上传".i18n),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.toReadingStats,
                    ),
                    ListTile(
                      leading: const Icon(Remix.settings_line),
                      title: Text("更多设置".i18n),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.toSettings,
                    ),
                  ],
                ),
                _buildCard(
                  context,
                  children: [
                    ListTile(
                      leading: Icon(Remix.error_warning_line),
                      title: Text("免责声明".i18n),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: DialogUtils.showStatement,
                    ),
                    ListTile(
                      leading: const Icon(Remix.github_fill),
                      title: Text("开源主页".i18n),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        launchUrlString(
                          "https://github.com/funkeyyou/zaimanhua",
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Remix.upload_2_line),
                      title: Text("检查更新".i18n),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.checkUpdate,
                    ),
                    ListTile(
                      leading: const Icon(Remix.information_line),
                      title: Text("关于APP".i18n),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                      ),
                      onTap: controller.about,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: AppStyle.edgeInsetsH12.copyWith(top: 12),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: AppStyle.radius8,
        child: Theme(
          data: Theme.of(context).copyWith(
            listTileTheme: ListTileThemeData(
              shape: RoundedRectangleBorder(borderRadius: AppStyle.radius8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}
