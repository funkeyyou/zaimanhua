import 'package:get/get.dart';

/// 動漫之家評論介面太TM混亂了
/// 使用此類統一Model

class CommentItem {
  CommentItem({
    required this.id,
    required this.objId,
    required this.content,
    required this.photo,
    required this.createTime,
    required this.images,
    required this.likeAmount,
    required this.nickname,
    required this.replyAmount,
    required this.userId,
    required this.gender,
    required this.type,
    required this.originId,
    this.toCommentId = 0,
    this.isLike,
    this.isEmpty = false,
  });

  factory CommentItem.createEmpty() {
    return CommentItem(
      id: 0,
      objId: 0,
      content: "該評論不存在，可能已被刪除",
      photo: "",
      createTime: 0,
      images: [],
      likeAmount: 0.obs,
      nickname: "-",
      replyAmount: 0,
      userId: 0,
      gender: 0,
      type: 0,
      originId: 0,
      toCommentId: 0,
      isLike: false.obs,
      isEmpty: true,
    );
  }

  int id;
  int objId;
  String content;
  int createTime;
  Rx<int> likeAmount;
  int replyAmount;
  String nickname;
  String photo;
  List<String> images;
  int userId;
  List<CommentItem> parents = [];
  bool isEmpty;
  int gender;
  int type;
  int originId;
  int toCommentId;
  /// 是否已點贊（響應式，支援實時切換點贊狀態）
  Rx<bool>? isLike;
}
