import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/routes/app_navigator.dart';

import 'package:zai_x/services/novel_download_service.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/status/app_empty_widget.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class NovelDownloadedView extends StatelessWidget {
  const NovelDownloadedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          EasyRefresh(
            header: const MaterialHeader(),
            onRefresh: () async {
              NovelDownloadService.instance.updateDownlaoded();
            },
            child: ListView.separated(
              itemCount: NovelDownloadService.instance.downloaded.length,
              separatorBuilder: (_, i) => Divider(
                endIndent: 12,
                indent: 12,
                color: Colors.grey.withValues(alpha: .2),
                height: 1,
              ),
              itemBuilder: (_, i) {
                var item = NovelDownloadService.instance.downloaded[i];
                return buildItem(item);
              },
            ),
          ),
          Offstage(
            offstage: NovelDownloadService.instance.downloaded.isNotEmpty,
            child: AppEmptyWidget(
              onRefresh: () {
                NovelDownloadService.instance.updateDownlaoded();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(NovelDownloadedItem item) {
    return InkWell(
      onTap: () {
        AppNavigator.toNovelDownloadDetail(item);
      },
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NetImage(
              item.novelCover,
              width: 60,
              borderRadius: 4,
            ),
            AppStyle.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.novelName.i18n,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap4,
                  Text(
                    "已下载${item.chapterCount}章".i18n,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
