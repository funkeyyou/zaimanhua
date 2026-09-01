import 'package:flutter/material.dart';
import 'package:zai_x/modules/common/download/comic/comic_downloaded_view.dart';
import 'package:zai_x/modules/common/download/comic/comic_downloading_view.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicDownloadPage extends StatelessWidget {
  final int type;
  const ComicDownloadPage(this.type, {super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: type,
      child: Scaffold(
        appBar: AppBar(
          title: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(right: 56),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorSize: TabBarIndicatorSize.label,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor:
                  Get.isDarkMode ? Colors.white70 : Colors.black87,
              tabs: [
                Tab(text: "已完成".i18n),
                Obx(
                  () => Tab(
                      text: ComicDownloadService.instance.taskQueues.isEmpty
                          ? "下载中".i18n
                          : "下载中(${ComicDownloadService.instance.taskQueues.length})".i18n),
                )
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            ComicDownloadedView(),
            ComicDownloadingView(),
          ],
        ),
      ),
    );
  }
}
