import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/modules/bookshelf/recent_comics.dart';
import 'package:zai_x/modules/user/subscribe/comic/comic_subscribe_view.dart';
import 'package:zai_x/modules/user/subscribe/novel/novel_subscribe_view.dart';
import 'package:zai_x/modules/user/subscribe/user_subscribe_controller.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/widgets/tab_appbar.dart';

/// 阅读与订阅的统一入口。
class BookshelfPage extends StatelessWidget {
  final UserSubscribeController controller;
  BookshelfPage({super.key})
      : controller = Get.put(
          UserSubscribeController(0),
          tag: 'bookshelf',
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabAppBar(
        tabs: [
          Tab(text: "漫画".i18n),
          Tab(text: "小说".i18n),
        ],
        controller: controller.tabController,
        action: TextButton.icon(
          onPressed: () {
            final type = controller.tabController.index;
            AppNavigator.toLocalHistory(type: type);
          },
          icon: const Icon(Icons.history_rounded, size: 21),
          label: Text('浏览记录'.i18n),
        ),
      ),
      body: Obx(
        () => UserService.instance.logined.value
            ? TabBarView(
                controller: controller.tabController,
                children: [
                  ComicSubscribeView(controllerTag: 'bookshelf-comics'),
                  NovelSubscribeView(),
                ],
              )
            : ListView(
                children: [
                  const RecentComics(),
                  const SizedBox(height: 32),
                  buildNotLogin(),
                ],
              ),
      ),
    );
  }

  Widget buildNotLogin() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("登录后查看订阅".i18n),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              UserService.instance.login();
            },
            child: Text("登录".i18n),
          ),
        ],
      ),
    );
  }
}
