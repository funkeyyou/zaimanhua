import 'dart:convert';

import 'package:get/get.dart';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

class ComicViewPointModel {
  ComicViewPointModel({
    required this.id,
    required this.uid,
    required this.content,
    required this.num,
    required this.page,
  });

  factory ComicViewPointModel.fromJson(List<dynamic> json) =>
      ComicViewPointModel(
        id: asT<int>(json[0])!,
        uid: asT<int>(json[6])!,
        content: asT<String>(json[7])!,
        num: (asT<int?>(json[1]) ?? 0).obs,
        page: asT<int>(json[5])!,
      );

  int id;
  int uid;
  String content;
  RxInt num;
  int page;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'uid': uid,
        'content': content,
        'num': num,
        'page': page,
      };
}
