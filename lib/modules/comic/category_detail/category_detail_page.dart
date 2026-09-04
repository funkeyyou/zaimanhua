import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/modules/comic/category_detail/category_detail_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_grid_view.dart';
import 'package:zai_x/widgets/shadow_card.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:zai_x/app/i18n.dart';

class CategoryDetailPage extends StatelessWidget {
  final int id;
  final CategoryDetailController controller;
  CategoryDetailPage(this.id, {super.key, String? tagName})
      : controller = Get.put(
          CategoryDetailController(id, entryTagName: tagName),
          tag: DateTime.now().millisecondsSinceEpoch.toString(),
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.getTitle(),
          ),
        ),
        actions: [
          Builder(
            builder: (BuildContext context) => IconButton(
              icon: const Icon(Remix.filter_line),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          )
        ],
      ),
      endDrawer: Drawer(
        child: Obx(
          () => SafeArea(
            child: ListView.builder(
              padding: AppStyle.edgeInsetsA12.copyWith(top: 12),
              itemCount: controller.filters.length + 1,
              itemBuilder: (context, i) {
                if (i == controller.filters.length) {
                  return Padding(
                    padding: AppStyle.edgeInsetsV12,
                    child: OutlinedButton.icon(
                      icon: const Icon(Remix.refresh_line, size: 18),
                      label: Text("重置筛选".i18n),
                      onPressed: controller.hasFilter
                          ? () {
                              Navigator.pop(context);
                              controller.resetFilter();
                            }
                          : null,
                    ),
                  );
                }
                var item = controller.filters[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: AppStyle.edgeInsetsV12,
                      child: Text(
                        item.title.i18n,
                        style: Get.textTheme.titleMedium,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: item.items
                          .map(
                            (x) => OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: x.tagId == item.selectId.value
                                    ? Colors.blue
                                    : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: x.tagId == item.selectId.value
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              child: Text(
                                x.tagName.i18n,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: () async {
                                Navigator.pop(context);
                                controller.select(item, x.tagId);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        var count = constraints.maxWidth ~/ 160;
        if (count < 3) count = 3;
        return PageGridView(
          pageController: controller,
          firstRefresh: true,
          crossAxisCount: count,
          padding: AppStyle.edgeInsetsA12,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemBuilder: (context, i) {
            var item = controller.list[i];
            return ShadowCard(
              onTap: () {
                AppNavigator.toComicDetail(item.id);
              },
              radius: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 27 / 36,
                        child: NetImage(
                          item.cover ?? "",
                          borderRadius: 4,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: item.status == "连载中"
                                ? Colors.blue
                                : Colors.orange,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                          ),
                          padding:
                              AppStyle.edgeInsetsH8.copyWith(top: 2, bottom: 2),
                          child: Text(
                            (item.status ?? "").i18n,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppStyle.vGap4,
                  Padding(
                    padding: AppStyle.edgeInsetsH4,
                    child: Text(
                      item.name.i18n,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        height: 1.2,
                      ),
                    ),
                  ),
                  AppStyle.vGap4,
                  Padding(
                    padding: AppStyle.edgeInsetsH4,
                    child: Text(
                      (item.authors ?? "").i18n,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12.0,
                        height: 1.2,
                      ),
                    ),
                  ),
                  AppStyle.vGap4,
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
