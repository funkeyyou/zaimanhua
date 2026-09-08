import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';
import 'package:zai_x/modules/user/subscribe/comic/comic_subscribe_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/comic_completion_service.dart';
import 'package:zai_x/widgets/keep_alive_wrapper.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:zai_x/modules/bookshelf/recent_comics.dart';
import 'package:zai_x/widgets/status/app_error_widget.dart';
import 'package:zai_x/widgets/shadow_card.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicSubscribeView extends StatelessWidget {
  final ComicSubscribeController controller;
  ComicSubscribeView({super.key, String? controllerTag})
      : controller = Get.put(ComicSubscribeController(), tag: controllerTag);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return KeepAliveWrapper(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final count = ((constraints.maxWidth - 20) / (100 * scale + 12))
                  .floor()
                  .clamp(1, 24);
              return Obx(() => EasyRefresh(
                    header: const MaterialHeader(),
                    controller: controller.easyRefreshController,
                    onRefresh: controller.refreshData,
                    child: CustomScrollView(
                      controller: controller.scrollController,
                      slivers: [
                        const SliverToBoxAdapter(child: RecentComics()),
                        SliverToBoxAdapter(child: _buildFilters(context)),
                        if (controller.preparing.value)
                          const SliverToBoxAdapter(
                            child: SizedBox(
                                height: 220, child: AppLoaddingWidget()),
                          )
                        else if (controller.pageError.value)
                          SliverToBoxAdapter(
                            child: SizedBox(
                                height: 260,
                                child: AppErrorWidget(
                                  errorMsg: controller.errorMsg.value,
                                  onRefresh: controller.refreshData,
                                )),
                          )
                        else if (controller.list.isEmpty)
                          SliverToBoxAdapter(
                              child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(children: [
                              Icon(Icons.auto_stories_outlined,
                                  size: 40, color: theme.disabledColor),
                              const SizedBox(height: 12),
                              Text('这里还没有作品'.i18n,
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 6),
                              Text('试试其他筛选，或订阅喜欢的漫画'.i18n,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall),
                              if (controller.tag.value.isNotEmpty ||
                                  controller.type.value != 1 ||
                                  controller.readFilter.value != 0)
                                TextButton(
                                    onPressed: controller.resetFilters,
                                    child: Text('清除筛选'.i18n)),
                            ]),
                          ))
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverMasonryGrid.count(
                              crossAxisCount: count,
                              mainAxisSpacing: 18,
                              crossAxisSpacing: 12,
                              itemBuilder: (context, i) =>
                                  buildItem(controller.list[i]),
                              childCount: controller.list.length,
                            ),
                          ),
                      ],
                    ),
                  ));
            }),
          ),
          Obx(() => Visibility(
                visible: controller.editMode.value,
                child: SafeArea(
                  top: false,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: theme.colorScheme.primary.withValues(alpha: .08),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      children: [
                        TextButton.icon(
                            onPressed: controller.addFavorite,
                            icon: const Icon(Icons.star_border),
                            label: Text('添加收藏'.i18n)),
                        TextButton.icon(
                            onPressed: controller.cancelSub,
                            icon: const Icon(Icons.favorite_border),
                            label: Text('取消订阅'.i18n)),
                        TextButton(
                            onPressed: controller.cancelEdit,
                            child: Text('完成'.i18n)),
                      ],
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('订阅作品'.i18n,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('${controller.list.length}',
                    style: theme.textTheme.bodySmall),
                const Spacer(),
                TextButton(
                  onPressed: controller.list.isEmpty
                      ? null
                      : () {
                          if (controller.editMode.value) {
                            controller.cancelEdit();
                          } else {
                            controller.editMode.value = true;
                          }
                        },
                  child:
                      Text(controller.editMode.value ? '完成'.i18n : '管理'.i18n),
                ),
              ]),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  buildFilter(
                      types: controller.tagOptions,
                      value: controller.tag.value,
                      onSelected: (e) => controller.setTag(e.toString()),
                      loading: controller.tagLoading.value),
                  buildFilter(
                      types: controller.types,
                      value: controller.type.value,
                      onSelected: (e) => controller.setType(e)),
                  buildFilter(
                      types: controller.sorts,
                      value: controller.sort.value,
                      onSelected: (e) => controller.setSort(e)),
                ]),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final entry in controller.readFilters.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: controller.readFilter.value == entry.key,
                        showCheckmark: true,
                        checkmarkColor: theme.colorScheme.primary,
                        selectedColor:
                            theme.colorScheme.primary.withValues(alpha: .16),
                        side: BorderSide(
                            color: controller.readFilter.value == entry.key
                                ? theme.colorScheme.primary
                                : Colors.transparent),
                        onSelected: (_) => controller.setReadFilter(entry.key),
                      ),
                    ),
                ]),
              ),
              _buildSyncStatus(),
            ],
          ),
        ));
  }

  Widget _buildSyncStatus() {
    final saved = controller.savedAt.value;
    return Row(children: [
      if (controller.refreshing.value) ...[
        const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
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
            onPressed:
                controller.editMode.value ? null : controller.showPendingUpdate,
            child: Text('查看更新'.i18n))
      else if (controller.refreshFailed.value)
        TextButton(onPressed: controller.refreshData, child: Text('重试'.i18n)),
    ]);
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
      radius: 10,
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
                      borderRadius: 10,
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
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                  child: Text(
                (types[value] ?? "").toString().i18n,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              )),
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
