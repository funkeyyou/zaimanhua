import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/models/novel/search_model.dart';
import 'package:zai_x/modules/novel/search/novel_search_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/widgets/net_image.dart';
import 'package:zai_x/widgets/page_list_view.dart';
import 'package:zai_x/widgets/search_suggestion_view.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class NovelSearchPage extends StatelessWidget {
  final String keyword;
  final NovelSearchController controller;
  NovelSearchPage({this.keyword = "", super.key})
      : controller = Get.put(NovelSearchController(keyword));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: SizedBox(
          height: 40,
          child: TextField(
            controller: controller.searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "搜索轻小说".i18n,
              contentPadding: AppStyle.edgeInsetsH12,
              border: const OutlineInputBorder(),
              prefixIcon: SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: () {
                    AppNavigator.closePage();
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              suffixIcon: SizedBox(
                width: 48,
                child: IconButton(
                  onPressed: controller.submit,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            onSubmitted: (e) {
              controller.submit();
            },
            onChanged: controller.onKeywordChanged,
          ),
        ),
      ),
      body: Stack(
        children: [
          PageListView(
            pageController: controller,
            firstRefresh: false,
            showPageLoadding: true,
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
          Positioned.fill(
            child: Obx(
              () => Offstage(
                offstage: !controller.showHotWord.value &&
                    controller.suggestions.isEmpty,
                child: Container(
                  color: Get.theme.scaffoldBackgroundColor,
                  child: SearchSuggestionView(
                    history: controller.searchHistory.toList(),
                    suggestions: controller.suggestions.toList(),
                    onSearch: controller.searchKeyword,
                    onRemoveHistory: controller.removeHistory,
                    onClearHistory: controller.clearHistory,
                    onOpen: AppNavigator.toNovelDetail,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(NovelSearchModel item) {
    return InkWell(
      onTap: () {
        AppNavigator.toNovelDetail(item.id);
      },
      child: Container(
        padding: AppStyle.edgeInsetsA12,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NetImage(
              item.cover ?? "",
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
                    item.title.i18n,
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
                  AppStyle.vGap4,
                  Text((item.types ?? "").i18n,
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  AppStyle.vGap4,
                  Text((item.lastName ?? "").i18n,
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
