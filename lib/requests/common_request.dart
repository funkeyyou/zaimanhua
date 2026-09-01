import 'dart:io';

import 'package:dio/dio.dart';
import 'package:zai_x/models/version_model.dart';

/// 通用的请求
class CommonRequest {
  /// 版本信息来源：本仓库的 GitHub Release
  static const String kRepo = "funkeyyou/zaimanhua";

  Future<VersionModel> checkUpdate() async {
    return await checkUpdateGithubRelease();
  }

  /// 检查更新：读取仓库最新的 Release
  Future<VersionModel> checkUpdateGithubRelease() async {
    var result = await Dio().get(
      "https://api.github.com/repos/$kRepo/releases/latest",
      queryParameters: {
        "ts": DateTime.now().millisecondsSinceEpoch,
      },
      options: Options(
        responseType: ResponseType.json,
        headers: const {
          "Accept": "application/vnd.github+json",
        },
      ),
    );
    return _parseRelease(result.data as Map);
  }

  /// 把 Release 转换成版本信息
  ///
  /// tag 形如 v1.4.0；下载地址优先取当前平台对应的资源。
  VersionModel _parseRelease(Map json) {
    var tag = (json["tag_name"] ?? "").toString();
    var version = tag.startsWith("v") ? tag.substring(1) : tag;
    var assets = (json["assets"] as List?) ?? const [];
    var downloadUrl = (json["html_url"] ?? "").toString();
    for (var item in assets) {
      var name = (item["name"] ?? "").toString().toLowerCase();
      var url = (item["browser_download_url"] ?? "").toString();
      if (url.isEmpty) continue;
      if ((Platform.isAndroid && name.endsWith(".apk")) ||
          (Platform.isWindows && name.endsWith(".zip"))) {
        downloadUrl = url;
        break;
      }
    }
    return VersionModel(
      version: version,
      versionNum: _parseVersionNum(version),
      versionDesc: (json["body"] ?? "").toString().trim(),
      downloadUrl: downloadUrl,
    );
  }

  /// 1.4.0 -> 10400，与 Utils.parseVersion 保持一致
  int _parseVersionNum(String version) {
    var num = "";
    for (var item in version.split(".")) {
      var digits = item.replaceAll(RegExp(r'[^0-9]'), "");
      if (digits.isEmpty) digits = "0";
      num += digits.padLeft(2, "0");
    }
    return int.tryParse(num) ?? 0;
  }
}
