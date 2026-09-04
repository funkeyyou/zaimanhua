import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/models/comic/comic_tag_cover.dart';
import 'package:zai_x/modules/comic/home/category/comic_category_controller.dart';
import 'package:zai_x/widgets/keep_alive_wrapper.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_grid_view.dart';
import 'package:zai_x/widgets/shadow_card.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:zai_x/app/i18n.dart';

class ComicCategoryView extends StatelessWidget {
  final ComicCategoryController controller;
  ComicCategoryView({super.key})
      : controller = Get.put(ComicCategoryController());

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      var count = constraints.maxWidth ~/ 160;
      if (count < 3) count = 3;
      return KeepAliveWrapper(
        child: PageGridView(
          pageController: controller,
          firstRefresh: true,
          loadMore: false,
          crossAxisCount: count,
          padding: AppStyle.edgeInsetsH12.copyWith(bottom: 12),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemBuilder: (context, i) {
            var item = controller.list[i];
            return ShadowCard(
              onTap: () {
                controller.toDetail(item);
              },
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    // 被服务端隐藏的标签没有封面图，用本仓库自制的封面顶上
                    child: item.cover.isEmpty
                        ? _LocalTagCover(tagId: item.tagId)
                        : NetImage(
                            item.cover,
                            borderRadius: 8,
                          ),
                  ),
                  Padding(
                    padding: AppStyle.edgeInsetsA8,
                    child: Text(
                      item.title.i18n,
                      textAlign: TextAlign.center,
                      style: const TextStyle(height: 1),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

/// 无封面标签的本地封面
class _LocalTagCover extends StatelessWidget {
  const _LocalTagCover({required this.tagId});

  final int tagId;

  static const List<List<Color>> _palettes = [
    [Color(0xFF6A82FB), Color(0xFF4A55C7)],
    [Color(0xFFFF7E5F), Color(0xFFD65A44)],
    [Color(0xFF11998E), Color(0xFF0C6B64)],
    [Color(0xFFB06AB3), Color(0xFF7C4A80)],
    [Color(0xFFF7971E), Color(0xFFC5761A)],
    [Color(0xFF2193B0), Color(0xFF176B81)],
  ];

  @override
  Widget build(BuildContext context) {
    var asset = kComicTagCoverAsset[tagId];
    if (asset != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      );
    }
    // 连本地图都没有的新标签，退回配色块
    var colors = _palettes[tagId.abs() % _palettes.length];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Remix.price_tag_3_line,
        size: 36,
        color: Colors.white.withValues(alpha: .75),
      ),
    );
  }
}
