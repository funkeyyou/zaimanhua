import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zai_x/app/dialog_utils.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/modules/user/user_home_controller.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/services/novel_download_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/widgets/user_photo.dart';

class UserHomePage extends GetView<UserHomeController> {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.black
          : const Color(0xfff5f7fa),
      body: SafeArea(
        child: EasyRefresh(
          header: const MaterialHeader(),
          onRefresh: UserService.instance.refreshProfile,
          child: LayoutBuilder(builder: (context, constraints) {
            final inset = constraints.maxWidth > 860
                ? (constraints.maxWidth - 820) / 2
                : 16.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(inset, 16, inset, 32),
              children: [
                Text('我的'.i18n,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                _profile(context),
                const SizedBox(height: 20),
                _quickActions(context),
                _section(context, '账号与福利'.i18n, [
                  Obx(() => _tile(
                        context,
                        icon: Remix.calendar_check_line,
                        title: '每日签到'.i18n,
                        subtitle: '登录后自动签到'.i18n,
                        trailing: Text(
                            UserService.instance.userProfile.value?.isSign ==
                                    true
                                ? '已签到'.i18n
                                : '去签到'.i18n,
                            style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 13)),
                        onTap: () => UserService.instance.manualSignIn(),
                      )),
                  _tile(context,
                      icon: Remix.task_line,
                      title: '任务中心'.i18n,
                      subtitle: '达成后自动领取奖励'.i18n,
                      onTap: controller.toTaskCenter),
                  _tile(context,
                      icon: Remix.user_settings_line,
                      title: '个人资料'.i18n,
                      subtitle: '管理昵称、签名与个人信息'.i18n,
                      onTap: controller.toProfileEdit),
                ]),
                _section(context, '偏好设置'.i18n, [
                  _tile(context,
                      icon: theme.brightness == Brightness.dark
                          ? Remix.moon_line
                          : Remix.sun_line,
                      title: '显示主题'.i18n,
                      onTap: controller.setTheme),
                  _tile(context,
                      icon: Remix.settings_line,
                      title: '更多设置'.i18n,
                      subtitle: '语言、阅读、通知与下载'.i18n,
                      onTap: controller.toSettings),
                ]),
                _section(context, '关于再漫画X'.i18n, [
                  _tile(context,
                      icon: Remix.upload_2_line,
                      title: '检查更新'.i18n,
                      onTap: controller.checkUpdate),
                  _tile(context,
                      icon: Remix.github_fill,
                      title: '开源主页'.i18n,
                      onTap: () => launchUrlString(
                          'https://github.com/funkeyyou/zaimanhua',
                          mode: LaunchMode.externalApplication)),
                  _tile(context,
                      icon: Remix.information_line,
                      title: '关于APP'.i18n,
                      onTap: controller.about),
                  _tile(context,
                      icon: Remix.error_warning_line,
                      title: '免责声明'.i18n,
                      onTap: DialogUtils.showStatement),
                ]),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _profile(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final user = UserService.instance;
      final loggedIn = user.logined.value;
      final profile = user.userProfile.value;
      return Material(
        color: theme.colorScheme.primary.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: loggedIn ? controller.toProfileEdit : controller.login,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              UserPhoto(url: loggedIn ? user.photo : '', size: 56),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      loggedIn
                          ? profile?.nickname ?? user.nickname
                          : '登录账号'.i18n,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                      loggedIn
                          ? (user.isVip ? user.vipInfo : user.sign)
                          : '同步书架，继续喜欢的故事'.i18n,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall),
                  if (loggedIn &&
                      (profile?.userLevel != null || user.isVip)) ...[
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, children: [
                      if (profile?.userLevel != null)
                        Text('Lv.${profile!.userLevel}',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary)),
                      if (user.isVip)
                        const Text('VIP',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xffad782c))),
                    ]),
                  ],
                ],
              )),
              if (loggedIn)
                PopupMenuButton<String>(
                  tooltip: '账号操作'.i18n,
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) {
                    if (value == 'logout') controller.logout();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'logout', child: Text('退出登录'.i18n))
                  ],
                )
              else
                const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      );
    });
  }

  Widget _quickActions(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = constraints.maxWidth >= 560 * scale ? 4 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Obx(() => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _quickAction(context, width, Remix.star_line, '本机收藏'.i18n,
                  '收藏喜欢的作品'.i18n, controller.toFavorite),
              _quickAction(context, width, Remix.bar_chart_2_line, '阅读统计'.i18n,
                  '记录阅读时光'.i18n, controller.toReadingStats),
              _quickAction(
                  context,
                  width,
                  Remix.download_line,
                  '漫画下载'.i18n,
                  _downloadLabel(
                      ComicDownloadService.instance.taskQueues.length),
                  controller.comicDownload),
              _quickAction(
                  context,
                  width,
                  Remix.book_open_line,
                  '小说下载'.i18n,
                  _downloadLabel(
                      NovelDownloadService.instance.taskQueues.length),
                  controller.novelDownload),
            ],
          ));
    });
  }

  String _downloadLabel(int count) =>
      count > 0 ? '$count 个任务进行中'.i18n : '离线也能阅读'.i18n;

  Widget _quickAction(BuildContext context, double width, IconData icon,
      String title, String subtitle, VoidCallback onTap) {
    final theme = Theme.of(context);
    return SizedBox(
        width: width,
        child: Material(
          color: _surface(context),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 25, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
                  ],
                )),
          ),
        ));
  }

  Color _surface(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff151a21)
          : Colors.white;

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
        Material(
          color: _surface(context),
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: Column(children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 1,
                    indent: 54,
                    endIndent: 16,
                    color:
                        Theme.of(context).dividerColor.withValues(alpha: .08)),
              children[i],
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, size: 22),
      title: Text(title),
      subtitle: subtitle == null
          ? null
          : Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
