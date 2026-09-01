import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/db/novel_history.dart';
import 'package:zai_x/modules/user/local_history/novel/novel_history_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/widgets/keep_alive_wrapper.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_list_view.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class LocalNovelHistoryView extends StatelessWidget {
  final LocalNovelHistoryController controller;
  LocalNovelHistoryView({super.key})
      : controller = Get.put(LocalNovelHistoryController());

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: PageListView(
        pageController: controller,
        firstRefresh: true,
        loadMore: false,
        separatorBuilder: (context, i) => Divider(
          endIndent: 12,
          indent: 12,
          color: Colors.grey.withValues(alpha: .2),
          height: 1,
        ),
        itemBuilder: (context, i) {
          var item = controller.list[i];
          return buildItem(item);
        },
      ),
    );
  }

  Widget buildItem(NovelHistory item) {
    return InkWell(
      onTap: () {
        AppNavigator.toNovelDetail(item.novelId);
      },
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NetImage(
              item.novelCover,
              width: 80,
              height: 110,
              borderRadius: 4,
            ),
            AppStyle.hGap12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.novelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap4,
                  Text("看到${item.volumeName} ${item.chapterName}".i18n,
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  AppStyle.vGap4,
                  Text(
                      "观看于${Utils.formatTimestampMS(item.updateTime.millisecondsSinceEpoch)}".i18n,
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
