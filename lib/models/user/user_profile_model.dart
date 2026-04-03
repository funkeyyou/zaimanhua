import 'dart:convert';

T? asT<T>(dynamic value) {
  if (value is T) {
    return value;
  }
  return null;
}

class UserProfileModel {
  UserProfileModel({
    this.uid,
    required this.nickname,
    this.description,
    this.email,
    this.sex,
    this.blood,
    this.birthday,
    this.constellation,
    this.address,
    this.photo,
    this.isSign,
    this.userLevel,
    this.adExperience,
    this.cookieVal,
    this.userfeeinfo,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Supports both:
    // 1) {"personalInfo": {...}}
    // 2) {...} (already personal info object)
    final dynamic personalInfoRaw = json['personalInfo'];
    final Map<String, dynamic> info = personalInfoRaw is Map<String, dynamic>
        ? personalInfoRaw
        : json;

    final bool isMember = asT<bool>(info['isMember']) ?? false;
    final String? memberExpireTime = asT<String?>(info['memberExpireTime']);

    final UserfeeInfo? userfeeinfo;
    if (info['userFeeInfo'] is Map<String, dynamic>) {
      userfeeinfo = UserfeeInfo.fromLegacyJson(
        asT<Map<String, dynamic>>(info['userFeeInfo'])!,
      );
    } else {
      userfeeinfo = UserfeeInfo.fromMemberInfo(
        isMember: isMember,
        memberExpireTime: memberExpireTime,
      );
    }

    return UserProfileModel(
      uid: asT<int?>(info['uid']),
      nickname: asT<String?>(info['nickname']) ?? '',
      description: asT<String?>(info['description']),
      email: asT<String?>(info['email']),
      sex: asT<int?>(info['sex']),
      blood: asT<int?>(info['blood']),
      birthday: asT<String?>(info['birthday']),
      constellation: asT<String?>(info['constellation']),
      address: asT<String?>(info['address']),
      photo: asT<String?>(info['photo']),
      isSign: asT<bool?>(info['is_sign']),
      userLevel: switch (info['user_level']) {
        String level => int.tryParse(level),
        int level => level,
        num level => level.toInt(),
        _ => null,
      },
      adExperience: asT<int?>(info['adExperience']),
      cookieVal: asT<String?>(info['cookie_val']),
      userfeeinfo: userfeeinfo,
    );
  }

  int? uid;
  String nickname;
  String? description;
  String? email;
  int? sex;
  int? blood;
  String? birthday;
  String? constellation;
  String? address;
  String? photo;
  bool? isSign;
  int? userLevel;
  int? adExperience;
  String? cookieVal;
  UserfeeInfo? userfeeinfo;

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'nickname': nickname,
        'description': description,
        'email': email,
        'sex': sex,
        'blood': blood,
        'birthday': birthday,
        'constellation': constellation,
        'address': address,
        'photo': photo,
        'is_sign': isSign,
        'user_level': userLevel,
        'adExperience': adExperience,
        'cookie_val': cookieVal,
        'userFeeInfo': userfeeinfo,
      };
}

class UserfeeInfo {
  UserfeeInfo({
    this.mCate,
    this.mPeriod,
  });

  factory UserfeeInfo.fromLegacyJson(Map<String, dynamic> json) => UserfeeInfo(
        mCate: switch (json['m_cate']) {
          int value => value,
          num value => value.toInt(),
          _ => 0,
        },
        mPeriod: switch (json['m_period']) {
          int value => value,
          num value => value.toInt(),
          _ => 0,
        },
      );

  factory UserfeeInfo.fromMemberInfo({
    required bool isMember,
    required String? memberExpireTime,
  }) {
    final DateTime? expireAt = memberExpireTime == null
        ? null
        : DateTime.tryParse(memberExpireTime)?.toLocal();
    return UserfeeInfo(
      mCate: isMember ? 1 : 0,
      mPeriod: expireAt == null ? 0 : expireAt.millisecondsSinceEpoch ~/ 1000,
    );
  }

  int? mCate;
  int? mPeriod;

  bool get isVip => (mCate ?? 0) > 0;

  DateTime get expiresTime =>
      DateTime.fromMillisecondsSinceEpoch((mPeriod ?? 0) * 1000);

  @override
  String toString() {
    return jsonEncode(this);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'm_cate': mCate,
        'm_period': mPeriod,
      };
}
