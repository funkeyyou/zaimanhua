import 'package:dio/dio.dart';
import 'package:zai_x/models/version_model.dart';

/// 通用的請求
class CommonRequest {
  Future<VersionModel> checkUpdate() async {
    try {
      return await checkUpdateGitMirror();
    } catch (e) {
      return await checkUpdateJsDelivr();
    }
  }

  /// 檢查更新
  Future<VersionModel> checkUpdateGitMirror() async {
    var result = await Dio().get(
      "https://raw.gitmirror.com/xiaoyaocz/zai_x/zaimanhua/document/app_version.json",
      queryParameters: {
        "ts": DateTime.now().millisecondsSinceEpoch,
      },
      options: Options(
        responseType: ResponseType.json,
      ),
    );
    return VersionModel.fromJson(result.data);
  }

  /// 檢查更新
  Future<VersionModel> checkUpdateJsDelivr() async {
    var result = await Dio().get(
      "https://cdn.jsdelivr.net/gh/xiaoyaocz/zai_x@zaimanhua/document/app_version.json",
      queryParameters: {
        "ts": DateTime.now().millisecondsSinceEpoch,
      },
      options: Options(
        responseType: ResponseType.json,
      ),
    );
    return VersionModel.fromJson(result.data);
  }
}
