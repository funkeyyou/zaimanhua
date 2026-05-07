import 'dart:convert';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

class NovelRankModel {
  NovelRankModel({
    required this.id,
    required this.title,
    required this.authors,
    required this.cover,
    required this.hotHits,
    required this.lastName,
    required this.lastUpdateVolumeName,
    required this.lastUpdateVolumeId,
    required this.lastUpdateChapterName,
    required this.lastUpdateChapterId,
    required this.status,
    required this.typesText,
    required this.subNums,
    this.lastUpdateTime = 0,
  });

  factory NovelRankModel.fromJson(Map<String, dynamic> json) {
    return NovelRankModel(
      id: asT<int>(json['id']) ?? 0,
      title: asT<String>(json['title']) ?? '',
      authors: asT<String>(json['authors']) ?? '',
      cover: asT<String>(json['cover']) ?? '',
      hotHits: asT<int>(json['hot_hits']) ?? 0,
      lastName: asT<String>(json['last_name']) ?? '',
      lastUpdateVolumeName: asT<String>(json['last_update_volume_name']) ?? '',
      lastUpdateVolumeId: asT<int>(json['last_update_volume_id']) ?? 0,
      lastUpdateChapterName:
          asT<String>(json['last_update_chapter_name']) ?? '',
      lastUpdateChapterId: asT<int>(json['last_update_chapter_id']) ?? 0,
      status: asT<String>(json['status']) ?? '',
      typesText: asT<String>(json['types']) ?? '',
      subNums: asT<int>(json['sub_nums']) ?? 0,
      // Some older endpoints may still return this field.
      lastUpdateTime: asT<int>(json['last_update_time']) ?? 0,
    );
  }

  int id;
  String title;
  String authors;
  String cover;
  int hotHits;
  String lastName;
  String lastUpdateVolumeName;
  int lastUpdateVolumeId;
  String lastUpdateChapterName;
  int lastUpdateChapterId;
  String status;
  String typesText;
  int subNums;
  int lastUpdateTime;

  // Compatibility getters for existing UI/business code.
  String get name => title;

  List<String> get types => typesText
      .split('/')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  int get subscribeAmount => subNums;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'authors': authors,
        'cover': cover,
        'hot_hits': hotHits,
        'last_name': lastName,
        'last_update_volume_name': lastUpdateVolumeName,
        'last_update_volume_id': lastUpdateVolumeId,
        'last_update_chapter_name': lastUpdateChapterName,
        'last_update_chapter_id': lastUpdateChapterId,
        'status': status,
        'types': typesText,
        'sub_nums': subNums,
        'last_update_time': lastUpdateTime,
      };
}
