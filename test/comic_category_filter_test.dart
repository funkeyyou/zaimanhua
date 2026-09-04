import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/models/comic/category_filter_model.dart';
import 'package:zai_x/models/comic/comic_tag_table.g.dart';
import 'package:zai_x/modules/comic/category_detail/category_detail_controller.dart';

ComicCategoryFilterModel _group(
  String title,
  int dimension,
  List<List<Object>> items,
) {
  return ComicCategoryFilterModel(
    title: title,
    dimension: dimension,
    items: items
        .map(
          (e) => ComicCategoryFilterItemModel(
            tagId: e[0] as int,
            tagName: e[1] as String,
          ),
        )
        .toList(),
  );
}

List<ComicCategoryFilterModel> _buildGroups() => [
      _group("排序", kComicSortDimension, [
        [1, "更新排序"],
        [2, "热度排序"],
      ])
        ..selectId.value = 1,
      _group("状态", ComicTagDimension.status, [
        [0, "全部"],
        [2309, "连载"],
        [2310, "完结"],
      ]),
      _group("地区", ComicTagDimension.zone, [
        [0, "全部"],
        [2304, "日本"],
      ]),
      _group("受众", ComicTagDimension.audience, [
        [0, "全部"],
        [3262, "少年漫"],
      ]),
      _group("题材", ComicTagDimension.theme, [
        [0, "全部"],
        [8, "爱情"],
        [3243, "ゆり"],
      ]),
    ];

void main() {
  test("标签表收录了被服务端藏起来的题材", () {
    // 服务端 /comic/filter/category 不返回这些，但它们的 tagId 筛选有效
    for (final tagId in [3243, 18522, 3246, 3250, 3251, 5, 14, 30788]) {
      final tag = kComicTagById[tagId];
      expect(tag, isNotNull, reason: "缺少 tagId $tagId");
      expect(tag!.dimension, ComicTagDimension.theme);
    }
  });

  test("标签表按维度分好组", () {
    expect(
      kComicTagTable.where((x) => x.dimension == ComicTagDimension.status).length,
      2,
    );
    expect(
      kComicTagTable.where((x) => x.dimension == ComicTagDimension.zone).length,
      4,
    );
    expect(
      kComicTagTable
          .where((x) => x.dimension == ComicTagDimension.audience)
          .length,
      4,
    );
    expect(kComicTagById[2309]!.dimension, ComicTagDimension.status);
  });

  test("隐藏题材标签会被选中，而不是掉回全部漫画", () {
    final groups = _buildGroups();
    CategoryDetailController.applyEntryTag(groups, 3243, "ゆり");

    final theme = groups.firstWhere(
      (x) => x.dimension == ComicTagDimension.theme,
    );
    expect(theme.selectId.value, 3243);
    expect(theme.selected?.tagName, "ゆり");
  });

  test("进度和地区标签会落到自己的分组", () {
    final groups = _buildGroups();
    CategoryDetailController.applyEntryTag(groups, 2310, "完结");
    expect(
      groups.firstWhere((x) => x.dimension == ComicTagDimension.status).selectId.value,
      2310,
    );
    expect(
      groups.firstWhere((x) => x.dimension == ComicTagDimension.theme).selectId.value,
      0,
    );

    final zoneGroups = _buildGroups();
    CategoryDetailController.applyEntryTag(zoneGroups, 2304, "日本");
    expect(
      zoneGroups.firstWhere((x) => x.dimension == ComicTagDimension.zone).selectId.value,
      2304,
    );
  });

  test("表里没有的新标签会挂到题材下，保证还能筛", () {
    final groups = _buildGroups();
    CategoryDetailController.applyEntryTag(groups, 99999, "新标签");

    final theme = groups.firstWhere(
      (x) => x.dimension == ComicTagDimension.theme,
    );
    expect(theme.selectId.value, 99999);
    expect(theme.selected?.tagName, "新标签");
  });

  test("排序分组不会抢走入口标签", () {
    final groups = _buildGroups();
    // 排序项的 tagId 是 1/2，正好和某些题材 tagId 撞号
    CategoryDetailController.applyEntryTag(groups, 2, "热度排序");

    final sort = groups.firstWhere((x) => x.dimension == kComicSortDimension);
    expect(sort.selectId.value, 1, reason: "排序不应该被入口标签改掉");
    final theme = groups.firstWhere(
      (x) => x.dimension == ComicTagDimension.theme,
    );
    expect(theme.selectId.value, 2);
  });
}
