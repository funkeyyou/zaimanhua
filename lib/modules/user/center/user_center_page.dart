import 'package:flutter/material.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/user/user_center_model.dart';
import 'package:zai_x/modules/user/center/user_center_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_list_view.dart';
import 'package:zai_x/widgets/user_photo.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:zai_x/app/i18n.dart';

class UserCenterPage extends StatelessWidget {
  final int userId;
  final UserCenterController controller;
  UserCenterPage(this.userId, {super.key})
      : controller = Get.put(
          UserCenterController(userId),
          tag: "$userId",
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
              UserPhoto(
                url: controller.info.value?.photo ?? "",
                size: 32,
              ),
              AppStyle.hGap8,
              Flexible(
                child: Text(
                  controller.info.value?.nickname ?? "用户评论".i18n,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Obx(
            () => TextButton.icon(
              onPressed: controller.focusLoadding.value
                  ? null
                  : controller.toggleFocus,
              icon: Icon(
                controller.isFocus.value
                    ? Icons.check
                    : Icons.person_add_alt_1_outlined,
              ),
              label: Text(controller.isFocus.value ? "已关注".i18n : "关注".i18n),
            ),
          ),
        ],
      ),
      body: PageListView(
        pageController: controller,
        firstRefresh: true,
        showPageLoadding: true,
        separatorBuilder: (context, i) => Divider(
          endIndent: 12,
          indent: 12,
          color: Colors.grey.withValues(alpha: .2),
          height: 1,
        ),
        itemBuilder: (context, i) => _buildItem(context, controller.list[i]),
      ),
    );
  }

  Widget _buildItem(BuildContext context, UserCenterCommentItem item) {
    return InkWell(
      onTap: () => _openDetail(item),
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NetImage(
              item.entity.cover,
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
                    item.entity.name.i18n,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppStyle.vGap8,
                  Container(
                    width: double.infinity,
                    padding: AppStyle.edgeInsetsA8,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: .1),
                      borderRadius: AppStyle.radius4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.content.i18n,
                          style: Get.theme.textTheme.bodyMedium,
                        ),
                        if (item.toCommentInfo != null &&
                            item.toCommentInfo!.content.isNotEmpty)
                          Container(
                            width: double.infinity,
                            margin: AppStyle.edgeInsetsT8,
                            padding: AppStyle.edgeInsetsA8,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: .1),
                              borderRadius: AppStyle.radius4,
                            ),
                            child: Text(
                              "${item.toCommentInfo!.authorNickname}: ${item.toCommentInfo!.content}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        AppStyle.vGap8,
                        Row(
                          children: [
                            const Icon(
                              Remix.thumb_up_line,
                              color: Colors.grey,
                              size: 14,
                            ),
                            AppStyle.hGap4,
                            Text(
                              "${item.likeAmount}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            AppStyle.hGap12,
                            const Icon(
                              Remix.message_2_line,
                              color: Colors.grey,
                              size: 14,
                            ),
                            AppStyle.hGap4,
                            Text(
                              "${item.replyAmount}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              Utils.formatTimestamp(item.createTime),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(UserCenterCommentItem item) {
    if (item.entity.source == AppConstant.kTypeComic) {
      AppNavigator.toComicDetail(item.entity.id);
    } else if (item.entity.source == AppConstant.kTypeNovel) {
      AppNavigator.toNovelDetail(item.entity.id);
    }
  }
}
