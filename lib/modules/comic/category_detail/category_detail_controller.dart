import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/comic/category_comic_model.dart';
import 'package:zai_x/models/comic/category_filter_model.dart';
import 'package:zai_x/models/comic/comic_tag_table.g.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class CategoryDetailController
    extends BasePageController<ComicCategoryComicModel> {
  final int id;

  /// 进入本页时带的标签名
  ///
  /// 只在服务端出现了本地标签表还没收录的新标签时用来兜底显示。
  final String? entryTagName;

  CategoryDetailController(this.id, {this.entryTagName});

  final ComicRequest request = ComicRequest();
  RxList<ComicCategoryFilterModel> filters = RxList<ComicCategoryFilterModel>();

  @override
  void onInit() {
    loadFilter();
    super.onInit();
  }

  ComicCategoryFilterModel? group(int dimension) =>
      filters.firstWhereOrNull((x) => x.dimension == dimension);

  int selectedOf(int dimension) => group(dimension)?.selectId.value ?? 0;

  /// 是否有筛选条件(排序不算)
  bool get hasFilter => filters
      .where((x) => x.dimension != kComicSortDimension)
      .any((x) => x.selectId.value != 0);

  String getTitle() {
    var names = filters
        .where((x) => x.dimension != kComicSortDimension)
        .map((e) => e.selected)
        .whereType<ComicCategoryFilterItemModel>()
        .where((x) => x.tagId != 0)
        .map((x) => x.tagName.i18n)
        .toList();

    if (names.isEmpty) {
      return "全部漫画".i18n;
    }
    return names.join("·");
  }

  /// 选中某个标签
  ///
  /// 接口只有 theme 一个通用标签位，受众和题材都往这个位置塞，
  /// 所以两者只能二选一，选了一边就把另一边清掉。
  void select(ComicCategoryFilterModel filter, int tagId) {
    filter.selectId.value = tagId;
    if (tagId != 0) {
      if (filter.dimension == ComicTagDimension.theme) {
        group(ComicTagDimension.audience)?.selectId.value = 0;
      } else if (filter.dimension == ComicTagDimension.audience) {
        group(ComicTagDimension.theme)?.selectId.value = 0;
      }
    }
    filters.refresh();
    refreshData();
  }

  /// 清空全部筛选条件
  void resetFilter() {
    for (var item in filters) {
      if (item.dimension == kComicSortDimension) continue;
      item.selectId.value = 0;
    }
    filters.refresh();
    refreshData();
  }

  void loadFilter() async {
    try {
      var groups = await request.categoryFilter();
      groups.insert(
        0,
        ComicCategoryFilterModel(
          title: "排序",
          dimension: kComicSortDimension,
          items: [
            ComicCategoryFilterItemModel(tagId: 1, tagName: "更新排序"),
            ComicCategoryFilterItemModel(tagId: 2, tagName: "热度排序"),
          ],
        )..selectId.value = 1,
      );
      applyEntryTag(groups, id, entryTagName);
      filters.value = groups;
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  /// 把进入本页时带的标签落到对应分组
  ///
  /// 以前只在「全部分类」这一组里找，ゆり 之类被服务端藏起来的标签根本不在表里，
  /// 选中状态就一直是 0，最后筛出来的是全部漫画。
  static void applyEntryTag(
    List<ComicCategoryFilterModel> groups,
    int tagId, [
    String? tagName,
  ]) {
    if (tagId == 0) return;
    for (var item in groups) {
      if (item.dimension == kComicSortDimension) continue;
      if (item.items.any((x) => x.tagId == tagId)) {
        item.selectId.value = tagId;
        return;
      }
    }
    // 服务端新加的标签，本地表还没收录：临时挂到题材下，保证仍然筛得出来
    var theme = groups.firstWhereOrNull(
      (x) => x.dimension == ComicTagDimension.theme,
    );
    if (theme == null) return;
    theme.items.add(
      ComicCategoryFilterItemModel(tagId: tagId, tagName: tagName ?? "标签"),
    );
    theme.selectId.value = tagId;
  }

  @override
  Future<List<ComicCategoryComicModel>> getData(int page, int pageSize) async {
    if (filters.isEmpty) {
      return await request.categoryComic(id: id, page: page);
    }
    var theme = selectedOf(ComicTagDimension.theme);
    var audience = selectedOf(ComicTagDimension.audience);

    return await request.categoryComic(
      id: theme != 0 ? theme : audience,
      sort: selectedOf(kComicSortDimension),
      page: page,
      status: selectedOf(ComicTagDimension.status),
      zone: selectedOf(ComicTagDimension.zone),
    );
  }
}
