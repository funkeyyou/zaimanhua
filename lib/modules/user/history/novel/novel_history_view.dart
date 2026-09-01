import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/user/novel_history_model.dart';
import 'package:zai_x/modules/user/history/novel/novel_history_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/widgets/keep_alive_wrapper.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_list_view.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class NovelHistoryView extends StatelessWidget {
  final NovelHistoryController controller;
  NovelHistoryView({super.key})
      : controller = Get.put(NovelHistoryController());

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: PageListView(
        pageController: controller,
        firstRefresh: true,
        loadMore: true,
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

  Widget buildItem(UserNovelHistoryModel item) {
    return InkWell(
      onTap: () {
        AppNavigator.toNovelDetail(item.lnovelId);
      },
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NetImage(
              item.cover,
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
                    item.novelName.i18n,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap4,
                  Text(
                      "看到${item.volumeName} ${item.chapterName} ${item.record}页".i18n,
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  AppStyle.vGap4,
                  Text("观看于${Utils.formatTimestamp(item.viewingTime ?? 0)}".i18n,
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
