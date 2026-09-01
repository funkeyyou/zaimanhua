import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/modules/user/subscribe/comic/comic_subscribe_view.dart';
import 'package:zai_x/modules/user/subscribe/novel/novel_subscribe_view.dart';
import 'package:zai_x/modules/user/subscribe/user_subscribe_controller.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class UserSubscribePage extends StatelessWidget {
  final UserSubscribeController controller;
  final int type;
  UserSubscribePage({this.type = 0, super.key})
      : controller = Get.put(
          UserSubscribeController(type),
          tag: DateTime.now().millisecondsSinceEpoch.toString(),
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.only(right: 56),
          child: TabBar(
            controller: controller.tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: AppStyle.edgeInsetsH24,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Get.isDarkMode ? Colors.white70 : Colors.black87,
            tabs: [
              Tab(text: "漫画".i18n),
              Tab(text: "小说".i18n),
              // Tab(text: "新闻"),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [
          ComicSubscribeView(),
          NovelSubscribeView(),
          // NewsSubscribeView(),
        ],
      ),
    );
  }
}
