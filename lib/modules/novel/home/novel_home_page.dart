import 'package:flutter/material.dart';
import 'package:zai_x/modules/novel/home/category/novel_category_view.dart';
import 'package:zai_x/modules/novel/home/latest/novel_latest_view.dart';
import 'package:zai_x/modules/novel/home/novel_home_controller.dart';
import 'package:zai_x/modules/novel/home/recommend/novel_recommend_view.dart';
import 'package:zai_x/modules/novel/home/rank/novel_rank_view.dart';
import 'package:zai_x/widgets/tab_appbar.dart';
import 'package:get/get.dart';

class NovelHomePage extends GetView<NovelHomeController> {
  const NovelHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabAppBar(
        tabs: const [
          Tab(text: "推薦"),
          Tab(text: "更新"),
          Tab(text: "分類"),
          Tab(text: "排行"),
        ],
        controller: controller.tabController,
        action: IconButton(
          onPressed: controller.search,
          icon: const Icon(
            Icons.search,
          ),
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: [
          NovelRecommendView(),
          NovelLatestView(),
          NovelCategoryView(),
          NovelRankView(),
        ],
      ),
    );
  }
}
