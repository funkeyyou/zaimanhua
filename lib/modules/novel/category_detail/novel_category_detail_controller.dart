import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/novel/category_filter_model.dart';
import 'package:zai_x/models/novel/category_novel_model.dart';
import 'package:zai_x/requests/novel_request.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class NovelCategoryDetailController
    extends BasePageController<NovelCategoryNovelModel> {
  final int id;
  NovelCategoryDetailController(this.id);
  final NovelRequest request = NovelRequest();
  RxList<NovelCategoryFilterModel> filters = RxList<NovelCategoryFilterModel>();

  @override
  void onInit() {
    loadFilter();
    super.onInit();
  }

  String getTitle() {
    var items = filters.where((x) => x.selectId.value != 0 && x.title != "排序".i18n);

    if (items.isEmpty) {
      return "全部小说".i18n;
    } else {
      return items
          .map((e) =>
              e.items.firstWhere((x) => x.tagId == e.selectId.value).tagName)
          .join("-");
    }
  }

  void loadFilter() async {
    try {
      filters.value = await request.categoryFilter();
      for (var item in filters) {
        var tag = item.items.firstWhereOrNull((x) => x.tagId == id);
        if (tag != null) {
          item.selectId.value = tag.tagId;
        }
      }
      filters.insert(
        0,
        NovelCategoryFilterModel(
          title: "排序".i18n,
          items: [
            NovelCategoryFilterItemModel(tagId: 1, tagName: "更新排序".i18n),
            NovelCategoryFilterItemModel(tagId: 2, tagName: "热度排序".i18n),
          ],
        )..selectId.value = 1,
      );
      filters.insert(
        1,
        NovelCategoryFilterModel(
          title: "状态".i18n,
          items: [
            NovelCategoryFilterItemModel(tagId: 0, tagName: "全部".i18n),
            NovelCategoryFilterItemModel(tagId: 1, tagName: "连载中"),
            NovelCategoryFilterItemModel(tagId: 2, tagName: "已完结".i18n),
          ],
        ),
      );
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  @override
  Future<List<NovelCategoryNovelModel>> getData(int page, int pageSize) async {
    if (filters.isEmpty) {
      return await request.categoryNovel(cateId: id, page: page - 1);
    } else {
      var sort = filters.first.selectId.value;
      var status = filters[1].selectId.value;
      var cateId =
          filters.firstWhereOrNull((x) => x.title == "题材".i18n)?.selectId.value ?? 0;

      return await request.categoryNovel(
          cateId: cateId, status: status, sort: sort, page: page - 1);
    }
  }
}
