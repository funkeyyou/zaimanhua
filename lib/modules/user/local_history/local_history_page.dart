import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/modules/user/local_history/comic/comic_history_view.dart';
import 'package:zai_x/modules/user/local_history/novel/novel_history_view.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/modules/user/local_history/local_history_controller.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class LocalHistoryPage extends StatelessWidget {
  final LocalHistoryController controller;
  final int type;
  LocalHistoryPage({this.type = 0, super.key})
      : controller = Get.put(
          LocalHistoryController(type),
          tag: DateTime.now().millisecondsSinceEpoch.toString(),
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Obx(() => Visibility(
                visible: UserService.instance.logined.value,
                child: IconButton(
                  tooltip: '云端记录'.i18n,
                  icon: const Icon(Icons.cloud_outlined),
                  onPressed: () => AppNavigator.toUserHistory(
                      type: controller.tabController.index),
                ),
              )),
        ],
        title: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.zero,
          child: TabBar(
            controller: controller.tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: AppStyle.edgeInsetsH12,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor:
                Get.isDarkMode ? Colors.white70 : Colors.black87,
            tabs: [
              Tab(text: "漫画记录".i18n),
              Tab(text: "小说记录".i18n),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [
          LocalComicHistoryView(),
          LocalNovelHistoryView(),
        ],
      ),
    );
  }
}
