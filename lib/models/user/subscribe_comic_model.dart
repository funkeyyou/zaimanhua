import 'dart:convert';

import 'package:get/get.dart';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

class UserSubscribeComicItemModel {
  UserSubscribeComicItemModel({
    required this.id,
    required this.title,
    required this.cover,
    required this.subReaded,
    required this.lastUpdateChapterId,
    required this.lastUpdateChapterName,
    required this.lastUpdateTime,
    required this.comicPy,
    required this.status,
    required this.readingRecord,
    required this.hasNew,
  });

  factory UserSubscribeComicItemModel.fromJson(Map<String, dynamic> json) =>
      UserSubscribeComicItemModel(
        id: asT<int>(json['id'])!,
        title: asT<String>(json['title'])!,
        cover: asT<String>(json['cover'])!,
        subReaded: asT<int>(json['sub_readed'])!,
        lastUpdateChapterId: asT<int>(json['last_update_chapter_id'])!,
        lastUpdateChapterName: asT<String>(json['last_update_chapter_name'])!,
        // 接口的更新时间（秒）。章节 id 不是全站递增，排序只能靠这个
        lastUpdateTime: asT<int>(json['last_updatetime']) ?? 0,
        comicPy: asT<String>(json['comic_py'])!,
        status: asT<String>(json['status'])!,
        readingRecord: ReadingRecord.fromJson(
            asT<Map<String, dynamic>>(json['readingRecord']) ?? {}),
        hasNew: (asT<int>(json['sub_readed']) == 0).obs,
      );

  int id;
  String title;
  String cover;
  int subReaded;
  int lastUpdateChapterId;
  String lastUpdateChapterName;
  int lastUpdateTime;
  String comicPy;
  String status;
  ReadingRecord readingRecord;

  var isChecked = false.obs;
  var hasNew = false.obs;

  /// 更新時間排序鍵。
  ///
  /// 章節 ID 並不是全站遞增（同一天更新的兩部作品，章節 ID 可能差好幾千），
  /// 拿來當更新順序會讓最近更新的作品掉到後面。接口另外給了 last_updatetime，
  /// 那才是真正的更新時間；少數沒有這欄位的舊資料退回章節 ID，至少順序穩定。
  int get updateSortKey =>
      lastUpdateTime > 0 ? lastUpdateTime : lastUpdateChapterId;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'cover': cover,
        'sub_readed': subReaded,
        'last_update_chapter_id': lastUpdateChapterId,
        'last_update_chapter_name': lastUpdateChapterName,
        'last_updatetime': lastUpdateTime,
        'comic_py': comicPy,
        'status': status,
        'readingRecord': readingRecord,
      };
}

class ReadingRecord {
  ReadingRecord({
    required this.typeName,
    required this.uid,
    required this.source,
    required this.bizId,
    required this.chapterId,
    required this.viewingTime,
    required this.record,
    required this.volumeId,
    required this.totalNum,
    required this.chapterName,
    required this.volumeName,
  });

  factory ReadingRecord.fromJson(Map<String, dynamic> json) => ReadingRecord(
        typeName: asT<String>(json['type_name']) ?? '',
        uid: asT<int>(json['uid']) ?? 0,
        source: asT<int>(json['source']) ?? 0,
        bizId: asT<int>(json['biz_id']) ?? 0,
        chapterId: asT<int>(json['chapter_id']) ?? 0,
        viewingTime: asT<int>(json['viewing_time']) ?? 0,
        record: asT<int>(json['record']) ?? 0,
        volumeId: asT<int>(json['volume_id']) ?? 0,
        totalNum: asT<int>(json['total_num']) ?? 0,
        chapterName: asT<String>(json['chapter_name']) ?? '',
        volumeName: asT<String>(json['volume_name']) ?? '',
      );

  String typeName;
  int uid;
  int source;
  int bizId;
  int chapterId;
  int viewingTime;
  int record;
  int volumeId;
  int totalNum;
  String chapterName;
  String volumeName;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type_name': typeName,
        'uid': uid,
        'source': source,
        'biz_id': bizId,
        'chapter_id': chapterId,
        'viewing_time': viewingTime,
        'record': record,
        'volume_id': volumeId,
        'total_num': totalNum,
        'chapter_name': chapterName,
        'volume_name': volumeName,
      };
}
