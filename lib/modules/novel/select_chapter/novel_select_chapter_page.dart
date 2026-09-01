import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:zai_x/models/novel/novel_detail_model.dart';

import 'package:zai_x/modules/novel/select_chapter/novel_select_chapter_controller.dart';
import 'package:zai_x/services/novel_download_service.dart';
import 'package:zai_x/widgets/status/app_error_widget.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:zai_x/app/i18n.dart';

class NovelSelectChapterPage extends StatelessWidget {
  final int novelId;
  final NovelSelectChapterController controller;
  NovelSelectChapterPage(this.novelId, {super.key})
      : controller = Get.put(
          NovelSelectChapterController(novelId),
          tag: DateTime.now().millisecondsSinceEpoch.toString(),
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("选择下载章节".i18n),
        actions: [
          TextButton(
            onPressed: controller.toDownloadManage,
            child: Text("下载管理".i18n),
          ),
        ],
      ),
      body: Stack(
        children: [
          EasyRefresh(
            header: const MaterialHeader(),
            onRefresh: controller.loadDetail,
            child: _buildVolumes(),
          ),
          Obx(
            () => Offstage(
              offstage: !controller.pageLoadding.value,
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
      bottomNavigationBar: BottomAppBar(
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  onPressed: controller.selectAll,
                  icon: const Icon(
                    Remix.checkbox_line,
                    size: 20,
                  ),
                  label: Text("全选".i18n),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  onPressed: controller.cleanAll,
                  icon: const Icon(
                    Remix.checkbox_blank_line,
                    size: 20,
                  ),
                  label: Text("取消选中".i18n),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  onPressed: controller.startDownload,
                  icon: const Icon(
                    Remix.download_line,
                    size: 20,
                  ),
                  label: Text("下载选中".i18n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVolumes() {
    return Obx(
      () => ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: controller.volumes.length,
        itemBuilder: (_, i) {
          var item = controller.volumes[i];
          return _buildChapters(item);
        },
      ),
    );
  }

  Widget _buildChapters(NovelDetailVolume item) {
    return Obx(
      () {
        var volume = controller.selectIds[item.volumeId]!;
        return ExpansionTile(
          title: Text("${item.volumeName}(共${item.chapters.length}话)".i18n),
          leading: SizedBox(
            width: 40,
            child: Checkbox(
              value: volume.length == item.chapters.length,
              onChanged: (e) {
                if (e!) {
                  volume.addAll(
                    item.chapters
                        .where((x) => !NovelDownloadService.instance.downloadIds
                            .contains(
                                "${novelId}_${x.volumeId}_${x.chapterId}"))
                        .map((e) => e.chapterId),
                  );
                } else {
                  volume.clear();
                }
              },
            ),
          ),
          children: item.chapters
              .map(
                (chapter) => CheckboxListTile(
                  value: volume.contains(chapter.chapterId),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    chapter.chapterName,
                    style: Get.textTheme.titleSmall,
                  ),
                  enabled: !NovelDownloadService.instance.downloadIds.contains(
                      "${novelId}_${chapter.volumeId}_${chapter.chapterId}"),
                  subtitle: NovelDownloadService.instance.downloadIds.contains(
                          "${novelId}_${chapter.volumeId}_${chapter.chapterId}")
                      ? Text("已下载".i18n)
                      : null,
                  onChanged: (e) {
                    if (e!) {
                      volume.add(chapter.chapterId);
                    } else {
                      volume.remove(chapter.chapterId);
                    }
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }
}
