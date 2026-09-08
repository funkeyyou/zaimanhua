import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:zai_x/app/app_color.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/modules/comic/detail/comic_detail_controller.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/status/app_error_widget.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:zai_x/app/i18n.dart';

class ComicDetailPage extends StatelessWidget {
  final int id;
  final ComicDetailControler controller;
  ComicDetailPage(this.id, {super.key})
      : controller = Get.put(
          ComicDetailControler(id),
          tag: DateTime.now().millisecondsSinceEpoch.toString(),
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(
            controller.detail.value.title.isEmpty
                ? "漫画详情".i18n
                : controller.detail.value.title.i18n,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: '本机收藏'.i18n,
              onPressed: controller.favorited.value
                  ? controller.cancelFavorite
                  : controller.favorite,
              icon: Icon(controller.favorited.value
                  ? Remix.star_fill
                  : Remix.star_line),
            ),
          ),
          IconButton(
            tooltip: '分享'.i18n,
            onPressed: controller.share,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(
            () => Offstage(
              offstage: controller.detail.value.id == 0,
              child: EasyRefresh(
                header: const MaterialHeader(),
                onRefresh: controller.refreshDetail,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _buildHeader(),
                    _buildResume(context),
                    _buildChapter(),
                  ],
                ),
              ),
            ),
          ),
          Obx(
            () => Visibility(
              visible: controller.pageLoadding.value,
              child: const AppLoaddingWidget(),
            ),
          ),
          Obx(
            () => Offstage(
              offstage: !controller.pageError.value,
              child: AppErrorWidget(
                errorMsg: controller.errorMsg.value,
                onRefresh: () => controller.loadDetail(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActions(context),
    );
  }

  Widget _buildActions(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final ready = !controller.pageLoadding.value &&
          controller.detail.value.volumes
              .any((volume) => volume.chapters.isNotEmpty);
      final continuing = controller.history.value != null;
      final readButton = FilledButton(
        onPressed: ready ? controller.read : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(continuing ? '继续阅读'.i18n : '开始阅读'.i18n),
      );
      final secondary = [
        _detailAction(
            controller.subscribeStatus.value
                ? Remix.heart_fill
                : Remix.heart_line,
            controller.subscribeStatus.value ? '已订阅'.i18n : '订阅'.i18n,
            ready ? controller.subscribe : null,
            selected: controller.subscribeStatus.value),
        _detailAction(
            Remix.chat_2_line, '评论'.i18n, ready ? controller.comment : null),
        _detailAction(
            Remix.download_line, '下载'.i18n, ready ? controller.download : null),
      ];
      return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
              top:
                  BorderSide(color: theme.dividerColor.withValues(alpha: .12))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(builder: (context, constraints) {
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21) {
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  readButton,
                  const SizedBox(height: 4),
                  Row(children: [
                    for (final action in secondary) Expanded(child: action)
                  ]),
                ]);
              }
              return Row(children: [
                for (final action in secondary)
                  SizedBox(width: 56, child: action),
                const SizedBox(width: 12),
                Expanded(child: readButton),
              ]);
            }),
          ),
        ),
      );
    });
  }

  Widget _detailAction(IconData icon, String label, VoidCallback? onTap,
      {bool selected = false}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor:
            selected ? Colors.blue : Get.textTheme.bodyMedium?.color,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        minimumSize: const Size(48, 48),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 21),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11)),
      ]),
    );
  }

  Widget _buildResume(BuildContext context) {
    return Obx(() {
      final history = controller.history.value;
      if (history == null) return const SizedBox(height: 8);
      final primary = Theme.of(context).colorScheme.primary;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Material(
          color: primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            leading: Icon(Icons.bookmark_rounded, color: primary),
            title: Text('上次看到'.i18n,
                style: TextStyle(fontSize: 12, color: primary)),
            subtitle: Text('${history.chapterName} · 第${history.page}页'.i18n,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall),
            trailing: const Icon(Icons.chevron_right),
            onTap: controller.read,
          ),
        ),
      );
    });
  }

  Widget _buildHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //信息
        Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                NetImage(
                  controller.detail.value.cover,
                  width: 120,
                  height: 160,
                  borderRadius: 12,
                  thumbnail: true,
                ),
                AppStyle.hGap12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        controller.detail.value.title.i18n,
                        style: Get.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      AppStyle.vGap8,
                      _buildInfoItems(
                        iconData: Remix.user_smile_line,
                        children: controller.detail.value.authors
                            .map(
                              (e) => GestureDetector(
                                onTap: () => controller.toAuthorDetail(e),
                                child: Text(
                                  e.tagName.i18n,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.2,
                                    decoration: TextDecoration.underline,
                                    color: Get.isDarkMode
                                        ? Colors.white
                                        : AppColor.black333,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      // _buildInfo(
                      //   title: controller.detail.value.types
                      //       .map((e) => e.tagName)
                      //       .join("/"),
                      //   iconData: Remix.hashtag,
                      // ),
                      _buildInfoItems(
                        iconData: Remix.hashtag,
                        children: controller.detail.value.types
                            .map(
                              (e) => GestureDetector(
                                onTap: () => controller.toCategoryDetail(e),
                                child: Text(
                                  e.tagName.i18n,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.2,
                                    decoration: TextDecoration.underline,
                                    color: Get.isDarkMode
                                        ? Colors.white
                                        : AppColor.black333,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      // _buildInfo(
                      //   title: "人气 ${controller.detail.value.hitNum}",
                      //   iconData: Remix.fire_line,
                      // ),
                      // _buildInfo(
                      //   title: "订阅 ${controller.detail.value.subscribeNum}",
                      //   iconData: Remix.heart_line,
                      // ),
                      _buildInfo(
                        title:
                            "${Utils.formatTimestampToDate(controller.detail.value.lastUpdatetime)} ${controller.detail.value.status.map((e) => e.tagName).join("/")}",
                        iconData: Icons.schedule,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Obx(
              () => Positioned(
                right: 0,
                top: 0,
                child: Offstage(
                  offstage: !controller.detail.value.isVip,
                  child: Image.asset(
                    "assets/images/vip_comic.png",
                    width: 36,
                    height: 36,
                  ),
                ),
              ),
            ),
          ],
        ),
        AppStyle.vGap12,
        GestureDetector(
          onTap: () {
            controller.expandDescription.value =
                !controller.expandDescription.value;
          },
          child: Text(
            controller.detail.value.description.i18n,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.6,
            ),
            maxLines: controller.expandDescription.value ? null : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => controller.expandDescription.toggle(),
            icon: Icon(
                controller.expandDescription.value
                    ? Icons.expand_less
                    : Icons.expand_more,
                size: 18),
            label: Text(
                controller.expandDescription.value ? '收起简介'.i18n : '展开简介'.i18n),
          ),
        ),
        Divider(
          color: Colors.grey.withValues(alpha: .2),
          height: 1.0,
        ),
      ],
    );
  }

  Widget _buildChapter() {
    return _buildChapterList();
  }

  /// 章节按钮的文字颜色：上次看到的那一话最显眼，看过的变淡
  Color? _chapterColor(ComicDetailChapterItem chapter) {
    if (chapter.chapterId == controller.history.value?.chapterId) {
      return Colors.blue;
    }
    var normal = Get.textTheme.bodyMedium!.color;
    if (controller.isChapterRead(chapter.chapterId)) {
      return Get.isDarkMode ? Colors.white60 : Colors.black54;
    }
    return normal;
  }

  /// 长按章节的操作选单
  void _showChapterMenu(
    BuildContext context,
    ComicDetailVolume volume,
    ComicDetailChapterItem chapter,
  ) {
    var read = controller.isChapterRead(chapter.chapterId);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      constraints: const BoxConstraints(maxWidth: 500),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(chapter.chapterTitle.i18n),
              subtitle: Text(read ? "已看过".i18n : "还没看过".i18n),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(read ? Remix.eye_off_line : Remix.eye_line),
              title: Text(read ? "标记为未读".i18n : "标记为已读".i18n),
              onTap: () {
                Get.back();
                controller.toggleChapterRead(chapter);
              },
            ),
            ListTile(
              leading: const Icon(Remix.check_double_line),
              title: Text("这一话与之前全部标记为已读".i18n),
              onTap: () {
                Get.back();
                controller.markReadUntil(volume, chapter);
              },
            ),
            ListTile(
              leading: const Icon(Remix.delete_bin_line),
              title: Text("清除本作的已读标记".i18n),
              onTap: () {
                Get.back();
                controller.clearReadChapters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList() {
    return Column(
      children: controller.detail.value.volumes.isEmpty
          ? [
              Padding(
                padding: AppStyle.edgeInsetsA24,
                child: Text(
                  "(～￣▽￣)～\n没有可阅读的章节\n漫画可能已下架或您没有阅读的权限".i18n,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              )
            ]
          : controller.detail.value.volumes
              .map(
                (item) => Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: AppStyle.edgeInsetsV8,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "${item.title} · ${item.chapters.length}话".i18n,
                                style: Get.textTheme.titleMedium,
                              ),
                            ),
                            item.sortType.value == 1
                                ? TextButton.icon(
                                    style: TextButton.styleFrom(
                                      textStyle: const TextStyle(fontSize: 14),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      item.sortType.value = 0;
                                      item.sort();
                                    },
                                    icon: const Icon(
                                      Remix.sort_asc,
                                      size: 20,
                                    ),
                                    label: Text("升序".i18n),
                                  )
                                : TextButton.icon(
                                    style: TextButton.styleFrom(
                                      textStyle: const TextStyle(fontSize: 14),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    onPressed: () {
                                      item.sortType.value = 1;
                                      item.sort();
                                    },
                                    icon: const Icon(
                                      Remix.sort_desc,
                                      size: 20,
                                    ),
                                    label: Text("倒序".i18n),
                                  ),
                          ],
                        ),
                      ),
                      Obx(() {
                        final readCount = item.chapters
                            .where((chapter) =>
                                controller.isChapterRead(chapter.chapterId))
                            .length;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                              '已看过 $readCount / ${item.chapters.length} 话 · 长按可标记'
                                  .i18n,
                              style: Get.textTheme.bodySmall),
                        );
                      }),
                      LayoutBuilder(builder: (ctx, constraints) {
                        var count = constraints.maxWidth ~/ 160;
                        final textScale =
                            MediaQuery.textScalerOf(ctx).scale(14) / 14;
                        count = (constraints.maxWidth / (110 * textScale))
                            .floor()
                            .clamp(1, 12);

                        return Obx(
                          () => MasonryGridView.count(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                (item.showMoreButton && !item.showAll.value)
                                    ? 15
                                    : item.chapters.length,
                            itemBuilder: (_, i) {
                              if (item.showMoreButton &&
                                  !item.showAll.value &&
                                  i == 14) {
                                return Tooltip(
                                  message: "展开全部章节".i18n,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.grey,
                                      textStyle: const TextStyle(fontSize: 14),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    onPressed: () {
                                      item.showAll.value = true;
                                    },
                                    child: const Icon(Icons.arrow_drop_down),
                                  ),
                                );
                              }
                              return Tooltip(
                                message: item.chapters[i].chapterTitle,
                                child: Obx(
                                  () => Stack(
                                    children: [
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _chapterColor(
                                            item.chapters[i],
                                          ),
                                          backgroundColor:
                                              item.chapters[i].chapterId ==
                                                      controller.history.value
                                                          ?.chapterId
                                                  ? Theme.of(ctx)
                                                      .colorScheme
                                                      .primary
                                                      .withValues(alpha: .12)
                                                  : null,
                                          side: BorderSide(
                                              color:
                                                  item.chapters[i].chapterId ==
                                                          controller.history
                                                              .value?.chapterId
                                                      ? Theme.of(ctx)
                                                          .colorScheme
                                                          .primary
                                                      : Colors.grey.withValues(
                                                          alpha: .22)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          textStyle:
                                              const TextStyle(fontSize: 14),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          minimumSize:
                                              const Size.fromHeight(40),
                                        ),
                                        onPressed: () {
                                          controller.readChapter(
                                              item, item.chapters[i]);
                                        },
                                        onLongPress: () => _showChapterMenu(
                                          ctx,
                                          item,
                                          item.chapters[i],
                                        ),
                                        child: Text(
                                          item.chapters[i].chapterTitle.i18n,
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Positioned(
                                        left: -2,
                                        top: 0,
                                        child: Offstage(
                                          offstage: !item.chapters[i].isVip,
                                          child: Image.asset(
                                            "assets/images/vip_chapter.png",
                                            height: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            crossAxisCount: count,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                        );
                      })
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildInfo({
    required String title,
    IconData iconData = Icons.tag,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: Colors.grey,
            size: 16,
          ),
          AppStyle.hGap8,
          Expanded(
            child: Text(
              title.i18n,
              style: TextStyle(
                fontSize: 14,
                color: Get.isDarkMode ? Colors.white : AppColor.black333,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItems({
    required List<Widget> children,
    IconData iconData = Icons.tag,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            color: Colors.grey,
            size: 16,
          ),
          AppStyle.hGap8,
          Expanded(
            child: Wrap(
              spacing: 8,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
