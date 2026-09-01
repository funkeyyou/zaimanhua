import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:zai_x/app/dialog_utils.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/novel_font_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final settings = AppSettingsService.instance;
  var imageCacheSize = "正在计算缓存...".obs;
  var novelCacheSize = "正在计算缓存...".obs;

  @override
  void onInit() {
    super.onInit();
    getImageCachedSize();
    getNovelCachedSize();
  }

  void getImageCachedSize() async {
    try {
      imageCacheSize.value = "正在计算缓存...";
      var bytes = await getCachedSizeBytes();
      imageCacheSize.value = "${(bytes / 1024 / 1024).toStringAsFixed(1)}MB";
    } catch (e) {
      imageCacheSize.value = "缓存计算失败";
    }
  }

  void getNovelCachedSize() async {
    try {
      novelCacheSize.value = "正在计算缓存...";
      var bytes = await LocalStorageService.instance.getNovelCacheSize();
      novelCacheSize.value = "${(bytes / 1024 / 1024).toStringAsFixed(1)}MB";
    } catch (e) {
      novelCacheSize.value = "缓存计算失败";
    }
  }

  void cleanImageCache() async {
    var result = await clearDiskCachedImages();
    if (!result) {
      SmartDialog.showToast("清除失败");
    }
    getImageCachedSize();
  }

  void cleanNovelCache() async {
    var result = await LocalStorageService.instance.cleanNovelCacheSize();
    if (!result) {
      SmartDialog.showToast("清除失败");
    }
    getNovelCachedSize();
  }

  void setDownloadComicTask() {
    Get.dialog(
      SimpleDialog(
        title: const Text("漫画最大任务数"),
        children: [
          RadioGroup<int>(
            groupValue: settings.downloadComicTaskCount.value,
            onChanged: (e) {
              Get.back();
              settings.setDownloadComicTaskCount(e ?? 0);
            },
            child: Column(
              children: [0, 1, 2, 3, 4, 5]
                  .map(
                    (e) => RadioListTile<int>(
                      title: Text(e == 0 ? "无限制" : "$e个"),
                      value: e,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void setDownloadNovelTask() {
    Get.dialog(
      SimpleDialog(
        title: const Text("小说最大任务数"),
        children: [
          RadioGroup<int>(
            groupValue: settings.downloadNovelTaskCount.value,
            onChanged: (e) {
              Get.back();
              settings.setDownloadNovelTaskCount(e ?? 0);
            },
            child: Column(
              children: [0, 1, 2, 3, 4, 5]
                  .map(
                    (e) => RadioListTile<int>(
                      title: Text(e == 0 ? "无限制" : "$e个"),
                      value: e,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickNovelReaderFont() async {
    try {
      final path = await NovelFontService.instance.pickAndInstallFont(
        existingFontPaths: settings.novelReaderFontPaths,
      );
      if (path != null) {
        await settings.addNovelReaderFontPath(path);
      }
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  void showNovelReaderFontDialog() {
    Get.dialog(
      Obx(
        () => SimpleDialog(
          title: const Text("选择字体"),
          children: [
            RadioListTile<String>(
              title: const Text("系统默认"),
              value: '',
              groupValue: settings.novelReaderFontPath.value,
              onChanged: (value) async {
                Get.back();
                await settings.setNovelReaderFontPath(value ?? '');
              },
            ),
            ...settings.novelReaderFontPaths.map(
              (path) => RadioListTile<String>(
                title: Text(NovelFontService.instance.getFontName(path)),
                controlAffinity: ListTileControlAffinity.leading,
                secondary: IconButton(
                  tooltip: "删除字体",
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => deleteNovelReaderFont(path),
                ),
                value: path,
                groupValue: settings.novelReaderFontPath.value,
                onChanged: (value) async {
                  Get.back();
                  await settings.setNovelReaderFontPath(value ?? '');
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("导入字体"),
              onTap: () async {
                Get.back();
                await pickNovelReaderFont();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> deleteNovelReaderFont(String path) async {
    final fontName = NovelFontService.instance.getFontName(path);
    final result = await DialogUtils.showAlertDialog(
      "删除后需要重新导入才能再次使用。",
      title: "删除字体「$fontName」？",
      confirm: "删除",
    );
    if (!result) {
      return;
    }
    try {
      await settings.deleteNovelReaderFontPath(path);
      SmartDialog.showToast("删除成功");
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }
}
