import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dmzj/app/log.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as p;

class NovelFontService extends GetxService {
  static NovelFontService get instance => Get.find<NovelFontService>();

  static const String systemFontFamily = '';

  final Set<String> _loadedFontPaths = {};

  Future init() async {
    return;
  }

  String getFontName(String fontPath) {
    if (fontPath.isEmpty) {
      return '系统默认';
    }
    return p.basenameWithoutExtension(fontPath);
  }

  String? getFontFamily(String fontPath) {
    if (fontPath.isEmpty) {
      return null;
    }
    return 'NovelReaderFont_${fontPath.hashCode.abs()}';
  }

  Future<String?> pickAndInstallFont() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'font',
          extensions: ['ttf', 'otf', 'ttc'],
        ),
      ],
    );
    if (file == null) {
      return null;
    }

    final extension = p.extension(file.name).toLowerCase();
    if (!['.ttf', '.otf', '.ttc'].contains(extension)) {
      throw Exception('请选择 ttf、otf 或 ttc 字体文件');
    }

    final dir = await _fontDirectory();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.name)}';
    final targetPath = p.join(dir.path, fileName);
    await file.saveTo(targetPath);
    await loadFont(targetPath);
    return targetPath;
  }

  Future<void> loadFont(String fontPath) async {
    if (fontPath.isEmpty || _loadedFontPaths.contains(fontPath)) {
      return;
    }
    final file = File(fontPath);
    if (!await file.exists()) {
      throw Exception('字体文件不存在');
    }
    try {
      final bytes = await file.readAsBytes();
      final loader = FontLoader(getFontFamily(fontPath)!)
        ..addFont(
          Future.value(
            ByteData.sublistView(bytes),
          ),
        );
      await loader.load();
      _loadedFontPaths.add(fontPath);
    } catch (e) {
      Log.logPrint(e);
      rethrow;
    }
  }

  Future<Directory> _fontDirectory() async {
    final dir = await getApplicationSupportDirectory();
    final fontDir = Directory(p.join(dir.path, 'novel_fonts'));
    if (!await fontDir.exists()) {
      await fontDir.create(recursive: true);
    }
    return fontDir;
  }
}
