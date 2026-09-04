import 'dart:convert';

import 'package:zai_x/models/comic/comic_tag_table.g.dart';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

class ComicCategoryItemModel {
  ComicCategoryItemModel({
    required this.tagId,
    required this.title,
    required this.cover,
    this.tagType = ComicTagDimension.theme,
  });

  factory ComicCategoryItemModel.fromJson(Map<String, dynamic> json) =>
      ComicCategoryItemModel(
        tagId: asT<int>(json['tagId'])!,
        title: asT<String>(json['title'])!,
        cover: asT<String>(json['cover'])!,
        tagType: asT<int>(json['tagType']) ??
            kComicTagById[asT<int>(json['tagId'])]?.dimension ??
            ComicTagDimension.theme,
      );

  int tagId;
  String title;
  String cover;

  /// 标签维度，取值见 [ComicTagDimension]
  int tagType;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tagId': tagId,
        'title': title,
        'cover': cover,
        'tagType': tagType,
      };
}
