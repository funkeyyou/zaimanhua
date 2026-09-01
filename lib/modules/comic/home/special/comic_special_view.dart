import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/modules/comic/home/special/comic_special_controller.dart';
import 'package:zai_x/widgets/keep_alive_wrapper.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_list_view.dart';
import 'package:zai_x/widgets/shadow_card.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicSpecialView extends StatelessWidget {
  final ComicSpecialController controller;
  ComicSpecialView({super.key})
      : controller = Get.put(ComicSpecialController());

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: PageListView(
        pageController: controller,
        firstRefresh: true,
        showPageLoadding: false,
        padding: AppStyle.edgeInsetsA12.copyWith(top: 0),
        separatorBuilder: (context, i) => AppStyle.vGap12,
        itemBuilder: (context, i) {
          var item = controller.list[i];
          return ShadowCard(
            onTap: () {
              controller.toDetail(item);
            },
            radius: 8,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 710 / 284,
                  child: NetImage(
                    item.smallCover,
                    width: 710,
                    height: 354,
                  ),
                ),
                Padding(
                  padding: AppStyle.edgeInsetsA8,
                  child: Row(
                    children: [
                      Expanded(child: Text(item.title.i18n)),
                      Text(
                        Utils.formatTimestampToDate(item.createTime),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
