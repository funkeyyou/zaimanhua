import 'package:flutter/material.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/comic/update_item_model.dart';
import 'package:zai_x/modules/comic/home/latest/comic_latest_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/widgets/keep_alive_wrapper.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_list_view.dart';
import 'package:get/get.dart';

class ComicLatestView extends StatelessWidget {
  final ComicLatestController controller;
  ComicLatestView({super.key}) : controller = Get.put(ComicLatestController());

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: PageListView(
        pageController: controller,
        firstRefresh: true,
        showPageLoadding: false,
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

  Widget buildItem(ComicUpdateItemModel item) {
    return InkWell(
      onTap: () {
        AppNavigator.toComicDetail(item.comicId.toInt());
      },
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NetImage(
              item.cover ?? '',
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
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(children: [
                      const WidgetSpan(
                          child: Icon(
                        Icons.account_circle,
                        color: Colors.grey,
                        size: 18,
                      )),
                      const TextSpan(
                        text: " ",
                      ),
                      TextSpan(
                          text: item.authors,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14))
                    ]),
                  ),
                  const SizedBox(height: 2),
                  Text(item.types ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(item.lastUpdateChapterName ?? '',
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text("更新於${Utils.formatTimestamp(item.lastUpdatetime ?? 0)}",
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            Center(
              child: Obx(
                () => UserService.instance.subscribedComicIds
                        .contains(item.comicId.toInt())
                    ? IconButton(
                        icon: const Icon(Icons.favorite),
                        onPressed: () {
                          UserService.instance.cancelSubscribe(
                            [item.comicId.toInt()],
                            AppConstant.kTypeComic,
                          );
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {
                          UserService.instance.addSubscribe(
                            [item.comicId.toInt()],
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
