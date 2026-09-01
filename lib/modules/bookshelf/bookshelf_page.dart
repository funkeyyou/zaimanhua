import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/modules/user/subscribe/comic/comic_subscribe_view.dart';
import 'package:zai_x/modules/user/subscribe/novel/novel_subscribe_view.dart';
import 'package:zai_x/modules/user/subscribe/user_subscribe_controller.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/widgets/tab_appbar.dart';

/// 書架：底部分頁的「我的訂閱」入口
/// 與「我的 → 我的订阅」共用同一組列表 View，只是改成常駐分頁。
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
      ),
      body: Obx(
        () => UserService.instance.logined.value
            ? TabBarView(
                controller: controller.tabController,
                children: [
                  ComicSubscribeView(),
                  NovelSubscribeView(),
                ],
              )
            : buildNotLogin(),
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

