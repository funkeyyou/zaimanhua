import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/version_model.dart';

/// App 内更新
///
/// Android：下载 APK 后直接唤起系统安装器；
/// Windows：下载 zip 后在档案总管里选取，省掉去 GitHub 手动找档案。
class AppUpdateService {
  static final RxBool downloading = false.obs;

  /// 0~1，-1 表示还不知道总大小
  static final RxDouble progress = (-1.0).obs;
  static CancelToken? _cancelToken;

  /// 只有这两个平台会出正式包
  static bool get supported => Platform.isAndroid || Platform.isWindows;

  static Future<void> download(VersionModel version) async {
    if (downloading.value) {
      return;
    }
    if (version.downloadUrl.isEmpty) {
      SmartDialog.showToast("没有可下载的安装档".i18n);
      return;
    }
    if (!supported) {
      await launchUrlString(
        version.downloadUrl,
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    if (Platform.isAndroid && !await _ensureInstallPermission()) {
      return;
    }

    downloading.value = true;
    progress.value = -1;
    _cancelToken = CancelToken();
    _showProgress();
    try {
      var file = await _targetFile(version);
      if (await file.exists()) {
        await file.delete();
      }
      await file.parent.create(recursive: true);
      await Dio().download(
        version.downloadUrl,
        file.path,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          progress.value = total > 0 ? received / total : -1;
        },
      );
      SmartDialog.dismiss();
      await _open(file);
    } on DioException catch (e) {
      SmartDialog.dismiss();
      if (CancelToken.isCancel(e)) {
        return;
      }
      Log.logPrint(e);
      SmartDialog.showToast("下载失败，改用浏览器下载".i18n);
      await launchUrlString(
        version.downloadUrl,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      SmartDialog.dismiss();
      Log.logPrint(e);
      SmartDialog.showToast("更新失败：${e.toString()}".i18n);
    } finally {
      downloading.value = false;
      _cancelToken = null;
    }
  }

  static void cancel() {
    _cancelToken?.cancel();
    SmartDialog.dismiss();
  }

  /// 下载位置：Android 用 App 专属外部目录（安装器读得到），Windows 用下载资料夹
  static Future<File> _targetFile(VersionModel version) async {
    Directory? dir;
    if (Platform.isWindows) {
      dir = await getDownloadsDirectory();
    } else {
      dir = await getExternalStorageDirectory();
    }
    dir ??= await getApplicationSupportDirectory();
    var name = Platform.isAndroid
        ? "ZAI-X-${version.version}.apk"
        : "ZAI-X-${version.version}-windows-x64.zip";
    return File(p.join(dir.path, name));
  }

  static Future<void> _open(File file) async {
    if (Platform.isAndroid) {
      var result = await OpenFilex.open(
        file.path,
        type: "application/vnd.android.package-archive",
      );
      if (result.type != ResultType.done) {
        SmartDialog.showToast(result.message);
      }
      return;
    }
    try {
      await Process.run("explorer.exe", ["/select,${file.path}"]);
    } catch (e) {
      Log.logPrint(e);
    }
    SmartDialog.showToast("${"已下载到".i18n}：${file.path}");
  }

  /// Android 8 起要先允许「安装未知来源应用」
  static Future<bool> _ensureInstallPermission() async {
    try {
      var status = await Permission.requestInstallPackages.status;
      if (status.isGranted) {
        return true;
      }
      status = await Permission.requestInstallPackages.request();
      if (status.isGranted) {
        return true;
      }
      SmartDialog.showToast("需要允许安装未知来源应用才能直接更新".i18n);
      return false;
    } catch (e) {
      Log.logPrint(e);
      // 权限查询失败时不挡住流程，交给系统安装器自己提示
      return true;
    }
  }

  static void _showProgress() {
    SmartDialog.show(
      clickMaskDismiss: false,
      builder: (_) => Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "正在下载新版本".i18n,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Obx(
              () => LinearProgressIndicator(
                value: progress.value < 0 ? null : progress.value,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Text(
                progress.value < 0
                    ? "连接中...".i18n
                    : "${(progress.value * 100).toStringAsFixed(0)}%",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: cancel,
              child: Text("取消".i18n),
            ),
          ],
        ),
      ),
    );
  }
}
