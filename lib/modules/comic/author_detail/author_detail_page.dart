import 'package:flutter/material.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/models/comic/author_model.dart';
import 'package:zai_x/modules/comic/author_detail/author_detail_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/status/app_error_widget.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:zai_x/app/i18n.dart';

class ComicAuthorDetailPage extends StatelessWidget {
  final int id;
  final ComicAuthorDetailController controller;
  ComicAuthorDetailPage(this.id, {super.key})
      : controller = Get.put(
          ComicAuthorDetailController(id),
          tag: "$id",
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              NetImage(
                controller.detail.value?.cover ?? "",
                borderRadius: 24,
                width: 32,
                height: 32,
              ),
              AppStyle.hGap8,
              Text(controller.detail.value?.nickname ?? "作者".i18n),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: controller.subscribeAll,
            icon: const Icon(Remix.heart_line),
            label: Text("全部订阅".i18n),
          ),
        ],
      ),
      body: Obx(
        () => Stack(
          children: [
            Offstage(
              offstage: controller.detail.value == null,
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: controller.detail.value?.data.length ?? 0,
                separatorBuilder: (context, i) => Divider(
                  endIndent: 12,
                  indent: 12,
                  color: Colors.grey.withValues(alpha: .2),
                  height: 1,
                ),
                itemBuilder: (_, i) {
                  var item = controller.detail.value!.data[i];
                  return buildItem(item);
                },
              ),
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
                  onRefresh: () => controller.loadData(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItem(ComicAuthorComicModel item) {
    return InkWell(
      onTap: () {
        AppNavigator.toComicDetail(item.id);
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
                    item.name.i18n,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap4,
                  Text(item.status.i18n,
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            Center(
              child: Obx(
                () => UserService.instance.subscribedComicIds.contains(item.id)
                    ? IconButton(
                        icon: const Icon(Icons.favorite),
                        onPressed: () {
                          UserService.instance.cancelSubscribe(
                            [item.id],
                            AppConstant.kTypeComic,
                          );
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {
                          UserService.instance.addSubscribe(
                            [item.id],
                            AppConstant.kTypeComic,
                          );
                        },
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
