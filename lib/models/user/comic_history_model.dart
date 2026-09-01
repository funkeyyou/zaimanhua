import 'dart:convert';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

class UserComicHistoryModel {
  UserComicHistoryModel({
    this.uid,
    this.type,
    required this.comicId,
    this.chapterId,
    this.record,
    this.viewingTime,
    required this.comicName,
    required this.cover,
    this.chapterName,
  });

  factory UserComicHistoryModel.fromJson(Map<String, dynamic> json) =>
      UserComicHistoryModel(
        uid: _asInt(json['uid']),
        type: _asInt(json['type']),
        comicId: _asInt(json['comic_id']) ?? _asInt(json['biz_id']) ?? 0,
        chapterId: _asInt(json['chapter_id']) ?? 0,
        record: _asInt(json['record']) ?? 0,
        viewingTime: _asInt(json['viewing_time']) ?? 0,
        comicName: asT<String?>(json['comic_name']) ??
            asT<String?>(json['title']) ??
            "未知漫画",
        cover: asT<String?>(json['cover']) ?? "",
        chapterName: asT<String?>(json['chapter_name']) ?? "-",
      );

  int? uid;
  int? type;
  int comicId;
  int? chapterId;
  int? record;
  int? viewingTime;
  String comicName;
  String cover;
  String? chapterName;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'type': type,
        'comic_id': comicId,
        'chapter_id': chapterId,
        'record': record,
        'viewing_time': viewingTime,
        'comic_name': comicName,
        'cover': cover,
        'chapter_name': chapterName,
      };
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '');
}
