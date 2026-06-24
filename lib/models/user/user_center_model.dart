import 'dart:convert';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

int asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

class UserCenterInfo {
  UserCenterInfo({
    required this.uid,
    required this.nickname,
    required this.sex,
    required this.photo,
    required this.isFocus,
    required this.fansNum,
    required this.commentLikeNum,
  });

  factory UserCenterInfo.fromJson(Map<String, dynamic> json) => UserCenterInfo(
        uid: asInt(json['Uid'] ?? json['uid']),
        nickname: (json['Nickname'] ?? json['nickname'] ?? '').toString(),
        sex: asInt(json['Sex'] ?? json['sex']),
        photo: (json['Photo'] ?? json['photo'] ?? '').toString(),
        isFocus: json['IsFocus'] == true || json['isFocus'] == true,
        fansNum: asInt(json['FansNum'] ?? json['fansNum']),
        commentLikeNum: asInt(json['CommentLikeNum'] ?? json['commentLikeNum']),
      );

  int uid;
  String nickname;
  int sex;
  String photo;
  bool isFocus;
  int fansNum;
  int commentLikeNum;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'nickname': nickname,
        'sex': sex,
        'photo': photo,
        'isFocus': isFocus,
        'fansNum': fansNum,
        'commentLikeNum': commentLikeNum,
      };

  @override
  String toString() => jsonEncode(toJson());
}

class UserCenterCommentItem {
  UserCenterCommentItem({
    required this.id,
    required this.objId,
    required this.content,
    required this.senderUid,
    required this.images,
    required this.likeAmount,
    required this.replyAmount,
    required this.createTime,
    required this.toCommentId,
    required this.originCommentId,
    required this.photo,
    required this.nickname,
    required this.sex,
    required this.isLike,
    required this.entity,
    this.toCommentInfo,
  });

  factory UserCenterCommentItem.fromJson(Map<String, dynamic> json) {
    final author = json['author'] is Map
        ? Map<String, dynamic>.from(json['author'] as Map)
        : <String, dynamic>{};
    final stats = json['stats'] is Map
        ? Map<String, dynamic>.from(json['stats'] as Map)
        : <String, dynamic>{};
    final imgList = json['imgList'];
    final images = imgList is List
        ? imgList.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : (json['upload_images'] ?? '')
            .toString()
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList();

    return UserCenterCommentItem(
      id: asInt(json['id']),
      objId: asInt(json['obj_id']),
      content: (json['content'] ?? '').toString(),
      senderUid: asInt(json['sender_uid'] ?? author['uid']),
      images: images,
      likeAmount: asInt(stats['like_amount'] ?? json['like_amount']),
      replyAmount: asInt(stats['reply_amount'] ?? json['reply_amount']),
      createTime: asInt(json['create_time']),
      toCommentId: asInt(json['to_comment_id']),
      originCommentId: asInt(json['origin_comment_id']),
      photo: (author['photo'] ?? json['photo'] ?? '').toString(),
      nickname: (author['nickname'] ?? json['nickname'] ?? '').toString(),
      sex: asInt(author['sex'] ?? json['sex']),
      isLike: stats['is_like'] == true || json['is_like'] == true,
      entity: UserCenterCommentEntity.fromJson(
        json['entity'] is Map
            ? Map<String, dynamic>.from(json['entity'] as Map)
            : <String, dynamic>{},
      ),
      toCommentInfo: json['to_comment_info'] is Map
          ? UserCenterReplyInfo.fromJson(
              Map<String, dynamic>.from(json['to_comment_info'] as Map),
            )
          : null,
    );
  }

  int id;
  int objId;
  String content;
  int senderUid;
  List<String> images;
  int likeAmount;
  int replyAmount;
  int createTime;
  int toCommentId;
  int originCommentId;
  String photo;
  String nickname;
  int sex;
  bool isLike;
  UserCenterCommentEntity entity;
  UserCenterReplyInfo? toCommentInfo;
}

class UserCenterCommentEntity {
  UserCenterCommentEntity({
    required this.id,
    required this.name,
    required this.cover,
    required this.source,
  });

  factory UserCenterCommentEntity.fromJson(Map<String, dynamic> json) =>
      UserCenterCommentEntity(
        id: asInt(json['id']),
        name: (json['name'] ?? '').toString().trim(),
        cover: (json['cover'] ?? '').toString(),
        source: asInt(json['source']),
      );

  int id;
  String name;
  String cover;
  int source;
}

class UserCenterReplyInfo {
  UserCenterReplyInfo({
    required this.id,
    required this.content,
    required this.createTime,
    required this.authorNickname,
  });

  factory UserCenterReplyInfo.fromJson(Map<String, dynamic> json) {
    final author = json['author'] is Map
        ? Map<String, dynamic>.from(json['author'] as Map)
        : <String, dynamic>{};
    return UserCenterReplyInfo(
      id: asInt(json['id']),
      content: (json['content'] ?? '').toString(),
      createTime: asInt(json['create_time']),
      authorNickname: (author['nickname'] ?? '').toString(),
    );
  }

  int id;
  String content;
  int createTime;
  String authorNickname;
}
