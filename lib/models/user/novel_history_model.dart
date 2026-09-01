import 'dart:convert';
import 'package:zai_x/app/i18n.dart';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

class UserNovelHistoryModel {
  UserNovelHistoryModel({
    this.uid,
    this.type,
    required this.lnovelId,
    this.volumeId,
    this.chapterId,
    this.record,
    this.viewingTime,
    this.totalNum,
    required this.cover,
    required this.novelName,
    this.volumeName,
    this.chapterName,
  });

  factory UserNovelHistoryModel.fromJson(Map<String, dynamic> json) =>
      UserNovelHistoryModel(
        uid: _asInt(json['uid']),
        type: _asInt(json['type']),
        lnovelId: _asInt(json['lnovel_id']) ?? _asInt(json['biz_id']) ?? 0,
        volumeId: _asInt(json['volume_id']) ?? 0,
        chapterId: _asInt(json['chapter_id']) ?? 0,
        record: _asInt(json['record']) ?? 0,
        viewingTime: _asInt(json['viewing_time']) ?? 0,
        totalNum: _asInt(json['total_num']) ?? 0,
        cover: asT<String?>(json['cover']) ?? "",
        novelName: asT<String?>(json['novel_name']) ??
            asT<String?>(json['title']) ??
            "未知小说".i18n,
        volumeName: asT<String?>(json['volume_name']) ?? "-",
        chapterName: asT<String?>(json['chapter_name']) ?? "-",
      );

  int? uid;
  int? type;
  int lnovelId;
  int? volumeId;
  int? chapterId;
  int? record;
  int? viewingTime;
  int? totalNum;
  String cover;
  String novelName;
  String? volumeName;
  String? chapterName;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'type': type,
        'lnovel_id': lnovelId,
        'volume_id': volumeId,
        'chapter_id': chapterId,
        'record': record,
        'viewing_time': viewingTime,
        'total_num': totalNum,
        'cover': cover,
        'novel_name': novelName,
        'volume_name': volumeName,
        'chapter_name': chapterName,
      };
}

int? _asInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '');
}
