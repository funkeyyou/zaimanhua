import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';
import 'package:zai_x/modules/user/subscribe/comic/comic_subscribe_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/widgets/keep_alive_wrapper.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_grid_view.dart';
import 'package:zai_x/widgets/shadow_card.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicSubscribeView extends StatelessWidget {
  final ComicSubscribeController controller;
  ComicSubscribeView({super.key})
      : controller = Get.put(ComicSubscribeController());

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: Column(
        children: [
          Obx(
            () => Row(
              children: [
                buildFilter(
                  // 題材標籤（由漫畫詳情補抓後快取）
                  types: controller.tagOptions,
                  value: controller.tag.value,
                  onSelected: (e) {
                    controller.setTag(e.toString());
                  },
                  loading: controller.tagLoading.value,
                ),
                buildFilter(
                  types: controller.types,
                  value: controller.type.value,
                  onSelected: (e) {
                    controller.type.value = e;
                    controller.refreshData();
                  },
                ),
                buildFilter(
                  types: controller.sorts,
                  value: controller.sort.value,
                  onSelected: (e) {
                    controller.setSort(e);
                  },
                ),
              ],
            ),
          ),
          Divider(
            color: Colors.grey.withValues(alpha: .2),
            height: 1.0,
          ),
          Expanded(
            child: Stack(
              children: [
                LayoutBuilder(builder: (context, constraints) {
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
                      return buildItem(item);
                    },
                  );
                }),
                // 補分頁與排序期間蓋住中間狀態，排好再顯示
                Obx(
                  () => Offstage(
                    offstage: !controller.preparing.value,
                    child: Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: const AppLoaddingWidget(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Offstage(
              offstage: !controller.editMode.value,
              child: SizedBox(
                height: 48,
                child: BottomAppBar(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: controller.addFavorite,
                        icon: const Icon(Icons.star_border),
                        label: Text("添加收藏".i18n),
                      ),
                      AppStyle.hGap8,
                      TextButton.icon(
                        onPressed: controller.cancelSub,
                        icon: const Icon(Icons.favorite_border),
                        label: Text("取消订阅".i18n),
                      ),
                      AppStyle.hGap8,
                      TextButton.icon(
                        onPressed: controller.cancelEdit,
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text("取消".i18n),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(UserSubscribeComicItemModel item) {
    return ShadowCard(
      onTap: () {
        if (controller.editMode.value) {
          item.isChecked.value = !item.isChecked.value;
          return;
        }
        item.hasNew.value = false;
        AppNavigator.toComicDetail(item.id);
      },
      onLongPress: () {
        if (controller.editMode.value) {
          return;
        }

        item.isChecked.value = true;
        controller.editMode.value = true;
      },
      radius: 4,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 27 / 36,
                    child: NetImage(
                      item.cover,
                      borderRadius: 4,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            item.status == "连载中" ? Colors.blue : Colors.orange,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                      padding:
                          AppStyle.edgeInsetsH8.copyWith(top: 2, bottom: 2),
                      child: Text(
                        item.status.i18n,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Obx(
                      () => Visibility(
                        visible: item.hasNew.value,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.deepOrange,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                          padding:
                              AppStyle.edgeInsetsH8.copyWith(top: 2, bottom: 2),
                          child: Text(
                            "新".i18n,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
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
                  item.title.i18n,
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
                  "更新 ${item.lastUpdateChapterName}".i18n,
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
          Obx(
            () => Positioned(
              right: 0,
              top: 0,
              child: Offstage(
                offstage: !controller.editMode.value,
                child: Checkbox(
                  value: item.isChecked.value,
                  onChanged: (e) {
                    item.isChecked.value = e!;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFilter({
    required Map types,
    required dynamic value,
    required Function(dynamic) onSelected,
    bool loading = false,
  }) {
    return Expanded(
      child: PopupMenuButton(
        onSelected: onSelected,
        itemBuilder: (c) => types.keys
            .map(
              (k) => CheckedPopupMenuItem(
                value: k,
                checked: k == value,
                child: Text((types[k] ?? "").toString().i18n),
              ),
            )
            .toList(),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                (types[value] ?? "").toString().i18n,
              ),
              loading
                  ? const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                    )
            ],
          ),
        ),
      ),
    );
  }
}
