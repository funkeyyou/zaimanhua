import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/routes/app_navigator.dart';

import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/status/app_empty_widget.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicDownloadedView extends StatelessWidget {
  const ComicDownloadedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Stack(
        children: [
          EasyRefresh(
            header: const MaterialHeader(),
            onRefresh: () async {
              ComicDownloadService.instance.updateDownlaoded();
            },
            child: ListView.separated(
              itemCount: ComicDownloadService.instance.downloaded.length,
              separatorBuilder: (_, i) => Divider(
                endIndent: 12,
                indent: 12,
                color: Colors.grey.withValues(alpha: .2),
                height: 1,
              ),
              itemBuilder: (_, i) {
                var item = ComicDownloadService.instance.downloaded[i];
                return buildItem(item);
              },
            ),
          ),
          Offstage(
            offstage: ComicDownloadService.instance.downloaded.isNotEmpty,
            child: AppEmptyWidget(
              onRefresh: () {
                ComicDownloadService.instance.updateDownlaoded();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(ComicDownloadedItem item) {
    return InkWell(
      onTap: () {
        AppNavigator.toComicDownloadDetail(item);
      },
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NetImage(
              item.comicCover,
              width: 60,
              borderRadius: 4,
            ),
            AppStyle.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.comicName.i18n,
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
