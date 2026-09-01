import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/models/db/download_status.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/services/download_task/comic_downloader.dart';
import 'package:zai_x/widgets/status/app_empty_widget.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:zai_x/app/i18n.dart';

class ComicDownloadingView extends StatelessWidget {
  const ComicDownloadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(
            () => Stack(
              children: [
                ListView.separated(
                  itemCount: ComicDownloadService.instance.taskQueues.length,
                  separatorBuilder: (_, i) => const Divider(
                    height: 1,
                  ),
                  itemBuilder: (_, i) {
                    var task = ComicDownloadService.instance.taskQueues[i];
                    return buildItem(task);
                  },
                ),
                Offstage(
                  offstage: ComicDownloadService.instance.taskQueues.isNotEmpty,
                  child: const AppEmptyWidget(),
                ),
              ],
            ),
          ),
        ),
        BottomAppBar(
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: ComicDownloadService.instance.pauseAll,
                    icon: const Icon(
                      Remix.pause_line,
                      size: 20,
                    ),
                    label: Text("暂停全部".i18n),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    onPressed: ComicDownloadService.instance.resumeAll,
                    icon: const Icon(
                      Remix.download_line,
                      size: 20,
                    ),
                    label: Text("开始全部".i18n),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildItem(ComicDownloader task) {
    return Obx(
      () => Padding(
        padding: AppStyle.edgeInsetsA12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "${task.info.value.volumeName} - ${task.info.value.chapterName}",
            ),
            Text(
              task.info.value.comicName,
              style: Get.textTheme.bodySmall,
            ),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: AppStyle.radius4,
                    child: LinearProgressIndicator(
                      value: task.info.value.total > 0
                          ? (task.info.value.index + 1) / task.info.value.total
                          : 0,
                    ),
                  ),
                ),
                AppStyle.hGap8,
                Text(
                  "${task.info.value.index + 1}/${task.info.value.total}",
                  style: Get.textTheme.bodySmall,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    parseStatus(task.info.value.status),
                    style: Get.textTheme.bodySmall,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildButton(
                      icon: Icons.refresh_rounded,
                      text: "重试".i18n,
                      visible: task.status == DownloadStatus.error ||
                          task.status == DownloadStatus.errorLoad,
                      onPressed: () {
                        task.retry();
                      },
                    ),
                    buildButton(
                      icon: Icons.play_arrow_rounded,
                      visible: task.status == DownloadStatus.wait ||
                          task.status == DownloadStatus.pauseCellular,
                      text: "开始".i18n,
                      onPressed: () {
                        task.start();
                      },
                    ),
                    buildButton(
                      icon: Icons.play_arrow_rounded,
                      visible: task.status == DownloadStatus.pause,
                      text: "继续".i18n,
                      onPressed: () {
                        task.resume();
                      },
                    ),
                    buildButton(
                      icon: Icons.pause_rounded,
                      visible: task.status == DownloadStatus.downloading,
                      text: "暂停".i18n,
                      onPressed: () {
                        task.pause();
                      },
                    ),
                    buildButton(
                      icon: Icons.cancel_outlined,
                      text: "取消".i18n,
                      onPressed: () {
                        task.cancel();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String parseStatus(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.cancel:
        return "已取消".i18n;
      case DownloadStatus.complete:
        return "已完成".i18n;
      case DownloadStatus.downloading:
        return "下载中".i18n;
      case DownloadStatus.error:
        return "下载失败".i18n;
      case DownloadStatus.errorLoad:
        return "无法读取信息".i18n;
      case DownloadStatus.loadding:
        return "读取信息中".i18n;
      case DownloadStatus.pause:
        return "暂停中".i18n;
      case DownloadStatus.pauseCellular:
        return "等待Wi-Fi".i18n;
      case DownloadStatus.wait:
        return "等待下载".i18n;
      case DownloadStatus.waitNetwork:
        return "等待网络连接".i18n;
      default:
        return status.toString();
    }
  }

  Widget buildButton({
    required String text,
    required IconData icon,
    Function()? onPressed,
    bool visible = true,
  }) {
    return Visibility(
      visible: visible,
      child: Padding(
        padding: AppStyle.edgeInsetsL4,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 14),
          ),
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 16,
          ),
          label: Text(text),
        ),
      ),
    );
  }
}
