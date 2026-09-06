import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/app_error.dart';
import 'package:zai_x/models/user/comic_history_model.dart';
import 'package:zai_x/models/user/login_result_model.dart';
import 'package:zai_x/models/user/novel_history_model.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';
import 'package:zai_x/models/user/subscribe_news_model.dart';
import 'package:zai_x/models/user/subscribe_novel_model.dart';
import 'package:zai_x/models/user/task_model.dart';
import 'package:zai_x/models/user/user_center_model.dart';
import 'package:zai_x/models/user/user_profile_model.dart';
import 'package:zai_x/requests/common/api.dart';
import 'package:zai_x/requests/common/http_client.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/app/i18n.dart';

class UserRequest {
  /// 登录
  /// - [nickname] 用户名
  /// - [password] 密码
  Future<LoginResultModel> login(
      {required String nickname, required String password}) async {
    var pwd = md5.convert(utf8.encode(password)).toString().toLowerCase();

    Map<String, dynamic> data = {
      "username": nickname,
      "passwd": pwd,
    };

    var result = await HttpClient.instance.postJson(
      "/login/passwd",
      baseUrl: Api.BASE_URL_USER,
      data: data,
      formUrlEncoded: true,
      checkCode: true,
    );

    return LoginResultModel.fromJson(result["user"]);
  }

  /// 用户资料
  Future<UserProfileModel> userProfile() async {
    var result = await HttpClient.instance.getJson(
      "/u_center/personal/info/get",
      baseUrl: Api.BASE_URL_USER,
      checkCode: true,
      needLogin: true,
      withDefaultParameter: true,
    );

    return UserProfileModel.fromJson(result);
  }

  Future<UserCenterInfo> userCenterInfo({required int userId}) async {
    var result = await HttpClient.instance.getJson(
      "/other_center/index",
      baseUrl: Api.BASE_URL_USER,
      queryParameters: {
        "hisUid": userId,
      },
      withDefaultParameter: false,
      needLogin: true,
    );
    if (result is Map) {
      HttpClient.checkErrno(result);
    }
    return UserCenterInfo.fromJson(
      Map<String, dynamic>.from(result["data"]["info"] as Map),
    );
  }

  Future<List<UserCenterCommentItem>> userCenterComments({
    required int userId,
    int page = 1,
    int pageSize = 10,
    int source = AppConstant.kTypeComic,
    int sortBy = 1,
  }) async {
    var result = await HttpClient.instance.getJson(
      "/other_center/comment_list",
      baseUrl: Api.BASE_URL_USER,
      queryParameters: {
        "hisUid": userId,
        "page": page,
        "size": pageSize,
        "source": source,
        "sortBy": sortBy,
      },
      withDefaultParameter: false,
      needLogin: true,
    );
    if (result is Map) {
      HttpClient.checkErrno(result);
    }
    var list = <UserCenterCommentItem>[];
    for (var item in (result["data"]["commentList"] ?? const [])) {
      list.add(UserCenterCommentItem.fromJson(
        Map<String, dynamic>.from(item as Map),
      ));
    }
    return list;
  }

  Future<bool> addFocus({required int userId}) async {
    var result = await HttpClient.instance.getJson(
      "/u_center/focus/add",
      baseUrl: Api.BASE_URL_USER,
      queryParameters: {
        "toUid": userId,
      },
      withDefaultParameter: false,
      needLogin: true,
    );
    if (result is Map) {
      HttpClient.checkErrno(result);
    }
    return true;
  }

  Future<bool> removeFocus({required int userId}) async {
    var result = await HttpClient.instance.getJson(
      "/u_center/focus/del",
      baseUrl: Api.BASE_URL_USER,
      queryParameters: {
        "toUid": userId,
      },
      withDefaultParameter: false,
      needLogin: true,
    );
    if (result is Map) {
      HttpClient.checkErrno(result);
    }
    return true;
  }

  /// 用户签到
  /// 返回 true 表示签到成功，errno==1 时抛出含 errmsg 的异常
  Future<bool> userSignIn() async {
    var result = await HttpClient.instance.postJson(
      "/task/sign_in",
      baseUrl: Api.BASE_SIGN_IN_USER,
      needLogin: true,
    );

    if (result is Map && result['errno'] == 1) {
      throw result['errmsg']?.toString() ?? '今天已签到过~'.i18n;
    }
    return true;
  }

  /// 任务中心的任务清单
  ///
  /// 官方 H5 走 GET /lpi/v1/task/list，与签到同一个服务。
  Future<List<UserTaskModel>> taskList() async {
    return parseUserTasks(await taskListRaw());
  }

  /// 任务清单的原始回应：字段命名没有公开文件，需要照原样看
  Future<dynamic> taskListRaw() async {
    var result = await HttpClient.instance.getJson(
      "/task/list",
      baseUrl: Api.BASE_SIGN_IN_USER,
      needLogin: true,
    );
    return result;
  }

  /// 个人资料接口探测
  ///
  /// 官方只有 i.zaimanhua.com 那支前端知道这些接口，参数名没有公开文件。
  /// 这里刻意少带参数，用回传的错误讯息反推需要什么栏位；全部都是读取或检查，
  /// 不会改到帐号资料。
  Future<Map<String, dynamic>> probeProfileApis() async {
    var result = <String, dynamic>{};

    Future<void> run(String name, Future<dynamic> Function() action) async {
      try {
        result[name] = await action();
      } catch (e) {
        result[name] = 'ERROR: ${e.toString()}';
      }
    }

    await run(
      "personal/info/get",
      () => HttpClient.instance.getJson(
        "/u_center/personal/info/get",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
      ),
    );
    await run(
      "setting/check_can_modify_name",
      () => HttpClient.instance.postJson(
        "/u_center/setting/check_can_modify_name",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
      ),
    );
    await run(
      "user/checkNickName",
      () => HttpClient.instance.getJson(
        "/user/checkNickName",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
        queryParameters: {"nickname": "再漫畫測試暱稱"},
      ),
    );
    await run(
      "setting/modify_name(空参数)",
      () => HttpClient.instance.postJson(
        "/u_center/setting/modify_name",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
      ),
    );
    await run(
      "personal/info/edit(空参数)",
      () => HttpClient.instance.postJson(
        "/u_center/personal/info/edit",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
      ),
    );
    await run(
      "personal/save_photo(空参数)",
      () => HttpClient.instance.postJson(
        "/u_center/personal/save_photo",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
      ),
    );
    await run(
      "personal/privacy",
      () => HttpClient.instance.getJson(
        "/u_center/personal/privacy",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
      ),
    );
    return result;
  }

  /// 第二轮探测：确认昵称检查与资料编辑真正吃的栏位
  ///
  /// 只做检查与可还原的编辑（description 事后会被改回去），不动昵称与头像。
  Future<Map<String, dynamic>> probeProfileFields() async {
    var result = <String, dynamic>{};

    Future<void> run(String name, Future<dynamic> Function() action) async {
      try {
        result[name] = await action();
      } catch (e) {
        result[name] = 'ERROR: \${e.toString()}';
      }
    }

    for (var key in const ['nickName', 'name', 'nick_name', 'nick']) {
      await run(
        'checkNickName?key=$key',
        () => HttpClient.instance.getJson(
          "/user/checkNickName",
          baseUrl: Api.BASE_URL_USER,
          needLogin: true,
          queryParameters: {key: 'zmh_probe_name'},
        ),
      );
    }

    await run(
      'info/edit description=探测中',
      () => HttpClient.instance.postJson(
        "/u_center/personal/info/edit",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
        formUrlEncoded: true,
        data: {'description': '探测中'},
      ),
    );
    await run(
      'info/get after edit',
      () => HttpClient.instance.getJson(
        "/u_center/personal/info/get",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
      ),
    );
    await run(
      'info/edit description=(还原)',
      () => HttpClient.instance.postJson(
        "/u_center/personal/info/edit",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
        formUrlEncoded: true,
        data: {'description': ''},
      ),
    );

    for (var key in const ['photo', 'file', 'image', 'img', 'avatar']) {
      await run(
        'save_photo key=$key base64',
        () => HttpClient.instance.postJson(
          "/u_center/personal/save_photo",
          baseUrl: Api.BASE_URL_USER,
          needLogin: true,
          formUrlEncoded: true,
          data: {key: _kTinyPngBase64},
        ),
      );
    }
    await run(
      'save_photo photo=dataUrl',
      () => HttpClient.instance.postJson(
        "/u_center/personal/save_photo",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
        formUrlEncoded: true,
        data: {'photo': 'data:image/png;base64,$_kTinyPngBase64'},
      ),
    );
    await run(
      'save_photo multipart photo',
      () => HttpClient.instance.postJson(
        "/u_center/personal/save_photo",
        baseUrl: Api.BASE_URL_USER,
        needLogin: true,
        data: {'photo': _kTinyPngBase64},
      ),
    );

    // 真正的 multipart 上传：base64 与表单栏位都被打回票，八成要档案本体
    for (var key in const ['photo', 'file', 'image']) {
      await run(
        'save_photo multipart field=$key',
        () => _uploadTinyPhoto(key),
      );
    }
    return result;
  }

  /// 用 multipart 送一张 1x1 PNG，纯粹试栏位名
  Future<dynamic> _uploadTinyPhoto(String field) async {
    var bytes = base64Decode(_kTinyPngBase64);
    var form = FormData.fromMap({
      field: MultipartFile.fromBytes(bytes, filename: 'avatar.png'),
    });
    var response = await Dio().post(
      '${Api.BASE_URL_USER}/u_center/personal/save_photo',
      data: form,
      options: Options(
        headers: {
          'Authorization': 'Bearer ${UserService.instance.dmzjToken}',
        },
        responseType: ResponseType.json,
      ),
    );
    return response.data;
  }

  /// 1x1 透明 PNG，只用来看接口回什么错误
  static const String _kTinyPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

  /// 昵称是否还能修改
  Future<bool> canModifyNickName() async {
    var result = await HttpClient.instance.postJson(
      "/u_center/setting/check_can_modify_name",
      baseUrl: Api.BASE_URL_USER,
      needLogin: true,
    );
    if (result is Map) {
      var data = result["data"];
      if (data is Map) {
        return data["can_modify"] == true;
      }
    }
    return false;
  }

  /// 个人资料原始栏位（与 info/edit 的栏位名一致）
  Future<Map<String, dynamic>> personalInfo() async {
    var result = await HttpClient.instance.getJson(
      "/u_center/personal/info/get",
      baseUrl: Api.BASE_URL_USER,
      needLogin: true,
      withDefaultParameter: true,
    );
    if (result is Map) {
      var data = result["data"];
      if (data is Map) {
        var info = data["personalInfo"];
        if (info is Map) {
          return Map<String, dynamic>.from(info);
        }
        return Map<String, dynamic>.from(data);
      }
    }
    return <String, dynamic>{};
  }

  /// 昵称是否可用（没被占用、格式正确）
  Future<bool> checkNickName(String nickName) async {
    var result = await HttpClient.instance.getJson(
      "/user/checkNickName",
      baseUrl: Api.BASE_URL_USER,
      needLogin: true,
      queryParameters: {"nickName": nickName},
    );
    return result is Map && result["errno"] == 0;
  }

  /// 修改昵称
  Future<void> modifyNickName(String nickName) async {
    var result = await HttpClient.instance.postJson(
      "/u_center/setting/modify_name",
      baseUrl: Api.BASE_URL_USER,
      needLogin: true,
      formUrlEncoded: true,
      data: {"nickName": nickName},
    );
    _throwIfFailed(result);
  }

  /// 编辑个人资料
  ///
  /// 字段沿用 personal/info/get 回来的名字：description、sex、birthday、address 等。
  Future<void> editPersonalInfo(Map<String, dynamic> fields) async {
    var result = await HttpClient.instance.postJson(
      "/u_center/personal/info/edit",
      baseUrl: Api.BASE_URL_USER,
      needLogin: true,
      formUrlEncoded: true,
      data: fields,
    );
    _throwIfFailed(result);
  }

  /// 上传头像
  ///
  /// 实测：save_photo 只吃 multipart，且栏位名是 image（photo/file 都回「上传错误」），
  /// 成功后回传 data.img_url。回传的网址若与目前不同，再用 info/edit 设定 photo。
  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    var form = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: filename),
    });
    var response = await Dio().post(
      '\${Api.BASE_URL_USER}/u_center/personal/save_photo',
      data: form,
      options: Options(
        headers: {
          'Authorization': 'Bearer \${UserService.instance.dmzjToken}',
        },
        responseType: ResponseType.json,
      ),
    );
    var result = response.data;
    _throwIfFailed(result);
    if (result is Map) {
      var data = result['data'];
      if (data is Map) {
        return data['img_url']?.toString() ?? '';
      }
    }
    return '';
  }

  void _throwIfFailed(dynamic result) {
    if (result is Map) {
      var errno = result["errno"];
      if (errno != null && errno != 0) {
        throw result["errmsg"]?.toString() ?? "操作失败".i18n;
      }
    }
  }

  /// 领取任务奖励
  ///
  /// 官方 H5 走 GET /lpi/v1/task/get_reward。参数名没有公开文件，
  /// 常见的三种写法一起带上，服务器会挑自己认得的那个。
  Future<String> taskGetReward(int taskId) async {
    var result = await HttpClient.instance.getJson(
      "/task/get_reward",
      baseUrl: Api.BASE_SIGN_IN_USER,
      needLogin: true,
      queryParameters: {
        "task_id": taskId,
        "taskId": taskId,
        "id": taskId,
      },
    );
    if (result is Map) {
      var errno = result["errno"];
      if (errno != null && errno != 0) {
        throw result["errmsg"]?.toString() ?? "领取失败".i18n;
      }
      var data = result["data"];
      if (data is Map) {
        var text = data["msg"] ?? data["message"] ?? data["reward"];
        if (text != null && text.toString().isNotEmpty) {
          return text.toString();
        }
      }
    }
    return "";
  }

  /// 我的漫画订阅
  /// - [page] 页数从0开始
  /// - [subType] 全部=1，未读=2，已读=3，完结=4
  /// - [letter] all=全部
  Future<List<UserSubscribeComicItemModel>> comicSubscribes(
      {required int subType, int page = 1, String letter = ""}) async {
    var list = <UserSubscribeComicItemModel>[];
    var result = await HttpClient.instance.getJson(
      '/comic/sub/list',
      queryParameters: {
        //uid=$uid&sub_type=$subType&letter=$letter&dmzj_token=$token&page=$page&type=$type
        ...(subType != 1 ? {"status": subType} : {}),
        "firstLetter": letter,
        "page": page,
        "size": 20
      },
      needLogin: true,
      checkCode: true,
    );
    for (var item in result["subList"]) {
      list.add(UserSubscribeComicItemModel.fromJson(item));
    }
    return list;
  }

  /// 我的小说订阅
  /// - [page] 页数从0开始
  /// - [subType] 全部=1，未读=2，已读=3，完结=4
  /// - [letter] all=全部
  Future<List<UserSubscribeNovelModel>> novelSubscribes(
      {required int subType, int page = 0, String letter = "all"}) async {
    var list = <UserSubscribeNovelModel>[];
    var result = await HttpClient.instance.getJson(
      '/novel/sub/list',
      queryParameters: {
        //uid=$uid&sub_type=$subType&letter=$letter&dmzj_token=$token&page=$page&type=$type
        ...(subType != 0 ? {"status": subType} : {}),
        "firstLetter": letter,
        "page": page,
        "size": 20
      },
      needLogin: true,
      checkCode: true,
    );
    for (var item in result["subList"]) {
      list.add(UserSubscribeNovelModel.fromJson(item));
    }
    return list;
  }

  /// 我的新闻收藏
  /// - [page] 页数从0开始
  Future<List<UserSubscribeNewsModel>> newsSubscribes({int page = 1}) async {
    var uid = UserService.instance.userId;
    var par = {"uid": int.parse(uid), "page": page};
    var parJson = jsonEncode(par);
    var sign = Api.sign(parJson, 'app_news_sub');

    var result = await HttpClient.instance.postJson(
      '/api/news/getSubscribe',
      baseUrl: Api.BASE_URL_INTERFACE,
      data: {
        "parm": parJson,
        "sign": sign,
      },
    );
    var data = json.decode(result);
    if (data["result"] != 1000) {
      throw AppError(data["msg"]);
    }
    var list = <UserSubscribeNewsModel>[];
    for (var item in data["data"]) {
      list.add(UserSubscribeNewsModel.fromJson(item));
    }
    return list;
  }

  /// 添加订阅
  /// - [type] 类型，对应AppConstant
  Future<bool> addSubscribe({required List<int> ids, required int type}) async {
    var requestUrl = "/comic/sub/add";
    var requestQuery = <String, dynamic>{};
    if (type == AppConstant.kTypeComic) {
      requestUrl = "/comic/sub/add";
      requestQuery = {
        "comic_id": ids.join(","),
      };
    } else if (type == AppConstant.kTypeNovel) {
      requestUrl = "/novel/sub/add";
      requestQuery = {
        "novel_id": ids.join(","),
      };
    }

    await HttpClient.instance.getJson(
      requestUrl,
      queryParameters: requestQuery,
      needLogin: true,
      checkCode: true,
    );
    return true;
  }

  /// 更新订阅的阅读状态
  /// - [type] 类型，对应AppConstant
  Future<bool> subscribeRead({required int id, required int type}) async {
    var typeStr = "mh";
    if (type == AppConstant.kTypeComic) {
      typeStr = "mh";
    } else if (type == AppConstant.kTypeNovel) {
      typeStr = "xs";
    }

    await HttpClient.instance.getJson(
      '/subscribe/read',
      queryParameters: {
        "obj_id": id,
        "type": typeStr,
      },
      withDefaultParameter: true,
      needLogin: true,
    );
    return true;
  }

  /// 取消订阅
  /// - [type] 类型，对应AppConstant
  Future<bool> removeSubscribe(
      {required List<int> ids, required int type}) async {
    var requestUrl = "/comic/sub/del";
    var requestQuery = <String, dynamic>{};
    if (type == AppConstant.kTypeComic) {
      requestUrl = "/comic/sub/del";
      requestQuery = {
        "comic_id": ids.join(","),
      };
    } else if (type == AppConstant.kTypeNovel) {
      requestUrl = "/novel/sub/del";
      requestQuery = {
        "novel_id": ids.join(","),
      };
    }

    await HttpClient.instance.getJson(
      requestUrl,
      queryParameters: requestQuery,
      needLogin: true,
      checkCode: true,
    );
    return true;
  }

  /// 查询订阅状态
  /// - [objId] 漫画ID或小说ID
  /// - [type] 类型，对应AppConstant
  Future<bool> checkSubscribeStatus(
      {required int objId, required int type}) async {
    var typeId = 1;
    if (type == AppConstant.kTypeComic) {
      typeId = 1;
    } else if (type == AppConstant.kTypeNovel) {
      typeId = 2;
    }

    var result = await HttpClient.instance.getJson(
      '/comic/sub/checkIsSub',
      checkCode: true,
      queryParameters: {
        "objId": objId,
        "source": typeId,
      },
      needLogin: true,
    );
    return result["isSub"];
  }

  /// 漫画阅读记录
  /// - [page] 页数从0开始，接口并没有分页
  Future<List<UserComicHistoryModel>> comicHistory({int page = 1}) async {
    var list = <UserComicHistoryModel>[];
    var result = await HttpClient.instance.getJson(
      '/readingRecord/list/',
      queryParameters: {
        "source": "mh",
        "page": page,
      },
      needLogin: true,
      checkCode: true,
      baseUrl: Api.BASE_URL,
    );
    for (var item in (result["recordList"] ?? const [])) {
      list.add(UserComicHistoryModel.fromJson(item));
    }
    //远程与本地同步
    DBService.instance.syncRemoteComicHistory(list);
    return list;
  }

  /// 小说阅读记录
  /// - [page] 页数从0开始，接口并没有分页
  Future<List<UserNovelHistoryModel>> novelHistory({int page = 1}) async {
    var list = <UserNovelHistoryModel>[];
    var result = await HttpClient.instance.getJson(
      '/readingRecord/list/',
      queryParameters: {
        "source": "xs",
        "page": page,
      },
      needLogin: true,
      checkCode: true,
      baseUrl: Api.BASE_URL,
    );
    for (var item in (result["recordList"] ?? const [])) {
      list.add(UserNovelHistoryModel.fromJson(item));
    }
    //远程与本地同步
    DBService.instance.syncRemoteNovelHistory(list);
    return list;
  }

  /// 上传漫画记录
  Future<bool> uploadComicHistory({
    required int comicId,
    required int chapterId,
    required int page,
    required DateTime time,
  }) async {
    var data = {
      "bizId": comicId,
      "chapterId": chapterId,
      "page": page,
    };
    await HttpClient.instance.postJson(
      "/readingRecord/add",
      baseUrl: Api.BASE_URL,
      data: {
        "source": "mh",
        "json": "[${json.encode(data)}]",
      },
      formUrlEncoded: true,
      needLogin: true,
      checkCode: true,
    );

    return true;
  }

  /// 上传小说记录
  Future<bool> uploadNovelHistory({
    required int novelId,
    required int chapterId,
    required int volumeId,
    required int page,
    required int total,
    required DateTime time,
  }) async {
    var data = {
      "bizId": novelId,
      "volumeId": volumeId,
      "chapterId": chapterId,
      "page": page,
    };
    await HttpClient.instance.postJson(
      "/readingRecord/add",
      baseUrl: Api.BASE_URL,
      data: {
        "source": "xs",
        "json": "[${json.encode(data)}]",
      },
      formUrlEncoded: true,
      needLogin: true,
      checkCode: true,
    );

    return true;
  }
}
