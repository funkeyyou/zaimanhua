import 'dart:convert';

import 'package:get/get.dart';
import 'package:zai_x/models/comic/comic_tag_table.g.dart';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

class ComicCategoryFilterModel {
  ComicCategoryFilterModel({
    required this.title,
    required this.items,
    this.dimension = 0,
  });

  factory ComicCategoryFilterModel.fromJson(Map<String, dynamic> json) {
    final List<ComicCategoryFilterItemModel>? items =
        json['items'] is List ? <ComicCategoryFilterItemModel>[] : null;
    if (items != null) {
      for (final dynamic item in json['items']!) {
        if (item != null) {
          items.add(ComicCategoryFilterItemModel.fromJson(
              asT<Map<String, dynamic>>(item)!));
        }
      }
    }
    return ComicCategoryFilterModel(
      title: asT<String>(json['title'])!,
      items: items!,
    );
  }

  String title;
  List<ComicCategoryFilterItemModel> items;

  /// 分组维度，取值见 [ComicTagDimension]，本地排序分组用 [kComicSortDimension]
  int dimension;

  var selectId = 0.obs;

  /// 当前选中项
  ComicCategoryFilterItemModel? get selected =>
      items.firstWhereOrNull((x) => x.tagId == selectId.value);

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'title': title,
        'items': items,
        'dimension': dimension,
      };
}

class ComicCategoryFilterItemModel {
  ComicCategoryFilterItemModel({
    required this.tagId,
    required this.tagName,
  });

  factory ComicCategoryFilterItemModel.fromJson(Map<String, dynamic> json) =>
      ComicCategoryFilterItemModel(
        tagId: asT<int>(json['tagId'])!,
        tagName: asT<String>(json['title'])!,
      );

  int tagId;
  String tagName;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tag_id': tagId,
        'tag_name': tagName,
      };
}
