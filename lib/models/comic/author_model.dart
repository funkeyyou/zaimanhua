import 'dart:convert';

class ComicAuthorModel {
  ComicAuthorModel({
    required this.nickname,
    this.description,
    required this.cover,
    required this.data,
    this.totalNum,
  });

  /// 从新版接口 /comic/list_by_author 响应解析
  /// 响应结构: { errno, errmsg, data: { authorInfo, comicList, totalNum } }
  factory ComicAuthorModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> dataMap =
        (json['data'] as Map<String, dynamic>?) ?? {};
    final Map<String, dynamic> authorInfo =
        (dataMap['authorInfo'] as Map<String, dynamic>?) ?? {};
    final List<dynamic> comicList = (dataMap['comicList'] as List?) ?? [];

    return ComicAuthorModel(
      nickname: (authorInfo['author_name'] as String?) ?? '',
      description: (authorInfo['author_info'] as String?) ?? '',
      cover: (authorInfo['cover'] as String?) ?? '',
      totalNum: dataMap['totalNum'] as int?,
      data: comicList
          .whereType<Map<String, dynamic>>()
          .map((e) => ComicAuthorComicModel.fromJson(e))
          .toList(),
    );
  }

  /// 作者名
  String nickname;

  /// 作者简介
  String? description;

  /// 作者头像
  String cover;

  /// 漫画总数
  int? totalNum;

  /// 漫画列表
  List<ComicAuthorComicModel> data;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'nickname': nickname,
        'description': description,
        'cover': cover,
        'totalNum': totalNum,
        'data': data,
      };
}

class ComicAuthorComicModel {
  ComicAuthorComicModel({
    required this.id,
    required this.name,
    required this.cover,
    required this.status,
    this.authors,
    this.types,
    this.lastUpdateChapterName,
    this.lastUpdatetime,
    this.comicPy,
  });

  factory ComicAuthorComicModel.fromJson(Map<String, dynamic> json) =>
      ComicAuthorComicModel(
        id: (json['id'] as int?) ?? 0,
        name: (json['name'] as String?) ?? '',
        cover: (json['cover'] as String?) ?? '',
        status: (json['status'] as String?) ?? '',
        authors: json['authors'] as String?,
        types: json['types'] as String?,
        lastUpdateChapterName: json['last_update_chapter_name'] as String?,
        lastUpdatetime: json['last_updatetime'] as int?,
        comicPy: json['comic_py'] as String?,
      );

  int id;
  String name;
  String cover;
  String status;
  String? authors;
  String? types;
  String? lastUpdateChapterName;
  int? lastUpdatetime;
  String? comicPy;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'cover': cover,
        'status': status,
        'authors': authors,
        'types': types,
        'last_update_chapter_name': lastUpdateChapterName,
        'last_updatetime': lastUpdatetime,
        'comic_py': comicPy,
      };
}
