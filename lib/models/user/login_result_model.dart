import 'dart:convert';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

int _asInt(dynamic value, {int defaultValue = 0}) {
  return switch (value) {
    int intValue => intValue,
    num numValue => numValue.toInt(),
    String stringValue => int.tryParse(stringValue) ?? defaultValue,
    _ => defaultValue,
  };
}

String _asString(dynamic value, {String defaultValue = ''}) {
  return switch (value) {
    String stringValue => stringValue,
    num numValue => numValue.toString(),
    _ => defaultValue,
  };
}

class LoginResultModel {
  LoginResultModel({
    required this.uid,
    required this.nickname,
    required this.token,
    required this.photo,
    required this.bindPhone,
    required this.email,
    required this.setPasswd,
  });

  factory LoginResultModel.fromJson(Map<String, dynamic> json) =>
      LoginResultModel(
        uid: _asInt(json['uid']),
        nickname: _asString(json['nickname']),
        token: _asString(json['token']),
        photo: _asString(json['photo']),
        bindPhone: _asString(json['bind_phone']),
        email: _asString(json['email']),
        setPasswd: _asInt(json['setPasswd']),
      );

  int uid;
  String nickname;
  String token;
  String photo;
  String bindPhone;
  String email;
  int setPasswd;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'nickname': nickname,
        'token': token,
        'photo': photo,
        'bind_phone': bindPhone,
        'email': email,
        'setPasswd': setPasswd
      };
}
