import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';
import 'package:zai_x/modules/user/subscribe/comic/comic_subscribe_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/comic_completion_service.dart';
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
                    controller.setType(e);
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
          Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: AppStyle.edgeInsetsH12,
                child: Row(
                  children: controller.readFilters.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(entry.value),
                              selected:
                                  controller.readFilter.value == entry.key,
                              onSelected: (_) =>
                                  controller.setReadFilter(entry.key),
                            ),
                          ))
                      .toList(),
                ),
              )),
          Obx(() {
            final saved = controller.savedAt.value;
            return SizedBox(
              height: 36,
              child: Padding(
                padding: AppStyle.edgeInsetsH12,
                child: Row(children: [
                  if (controller.refreshing.value) ...[
                    const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    AppStyle.hGap8,
                  ],
                  Expanded(
                      child: Text(
                    controller.refreshFailed.value
                        ? '刷新失败，保留上次的书架'.i18n
                        : controller.refreshing.value
                            ? '正在检查更新…'.i18n
                            : saved == null
                                ? ''
                                : '上次同步：${Utils.friendlyTimestamp(saved.millisecondsSinceEpoch ~/ 1000)}'
                                    .i18n,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  )),
                  if (controller.hasPendingUpdate.value)
                    TextButton(
                      onPressed: controller.editMode.value
                          ? null
                          : controller.showPendingUpdate,
                      child: Text('查看更新'.i18n),
                    )
                  else if (controller.refreshFailed.value)
                    TextButton(
                        onPressed: controller.refreshData,
                        child: Text('重试'.i18n)),
                ]),
              ),
            );
          }),
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
                    firstRefresh: false,
                    loadMore: false,
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
    final state = controller.stateOf(item);
    return ShadowCard(
      key: ValueKey(item.id),
      onTap: () {
        if (controller.editMode.value) {
          item.isChecked.value = !item.isChecked.value;
          return;
        }
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
                      thumbnail: true,
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
                    child: Visibility(
                      visible: state != ComicUpdateState.unknown,
                      child: Container(
                        decoration: BoxDecoration(
                          color: state == ComicUpdateState.caughtUp
                              ? Colors.teal
                              : Colors.deepOrange,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        padding:
                            AppStyle.edgeInsetsH8.copyWith(top: 2, bottom: 2),
                        child: Text(
                          state == ComicUpdateState.caughtUp
                              ? '已追平'.i18n
                              : '未读更新'.i18n,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
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
              // 上次更新時間（如：6小时前），跟官方书架一致
              if (item.lastUpdateTime > 0)
                Padding(
                  padding: AppStyle.edgeInsetsH4.copyWith(top: 2),
                  child: Text(
                    Utils.friendlyTimestamp(item.lastUpdateTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.withValues(alpha: .8),
                      fontSize: 11.0,
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
