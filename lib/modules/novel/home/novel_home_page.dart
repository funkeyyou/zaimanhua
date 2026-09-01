import 'package:flutter/material.dart';
import 'package:zai_x/modules/novel/home/category/novel_category_view.dart';
import 'package:zai_x/modules/novel/home/latest/novel_latest_view.dart';
import 'package:zai_x/modules/novel/home/novel_home_controller.dart';
import 'package:zai_x/modules/novel/home/recommend/novel_recommend_view.dart';
import 'package:zai_x/modules/novel/home/rank/novel_rank_view.dart';
import 'package:zai_x/widgets/tab_appbar.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class NovelHomePage extends GetView<NovelHomeController> {
  NovelHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabAppBar(
        tabs: [
          Tab(text: "推荐".i18n),
          Tab(text: "更新".i18n),
          Tab(text: "分类".i18n),
          Tab(text: "排行".i18n),
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
