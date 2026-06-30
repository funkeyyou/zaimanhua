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
  static final RegExp _installedFontNamePattern = RegExp(r'^\d{13}_(.+)$');

  final Set<String> _loadedFontPaths = {};

  Future init() async {
    return;
  }

  String getFontName(String fontPath) {
    if (fontPath.isEmpty) {
      return '系统默认';
    }
    return getFontNameFromFileName(p.basename(fontPath));
  }

  String getFontNameFromFileName(String fileName) {
    final baseName = p.basename(fileName);
    final match = _installedFontNamePattern.firstMatch(baseName);
    final displayName = match?.group(1) ?? baseName;
    return p.basenameWithoutExtension(displayName).trim();
  }

  String getFontKey(String fontPath) {
    return getFontName(fontPath).toLowerCase();
  }

  bool hasSameFontName(String fontName, Iterable<String> fontPaths) {
    final fontKey = fontName.trim().toLowerCase();
    if (fontKey.isEmpty) {
      return false;
    }
    return fontPaths.any((path) => getFontKey(path) == fontKey);
  }

  List<String> filterAvailableFontPaths(Iterable<String> fontPaths) {
    final fontKeys = <String>{};
    final result = <String>[];
    for (final fontPath in fontPaths) {
      if (fontPath.isEmpty || !File(fontPath).existsSync()) {
        continue;
      }
      final fontKey = getFontKey(fontPath);
      if (fontKey.isEmpty || !fontKeys.add(fontKey)) {
        continue;
      }
      result.add(fontPath);
    }
    return result;
  }

  String? getFontFamily(String fontPath) {
    if (fontPath.isEmpty) {
      return null;
    }
    return 'NovelReaderFont_${fontPath.hashCode.abs()}';
  }

  Future<String?> pickAndInstallFont({
    Iterable<String> existingFontPaths = const [],
  }) async {
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

    final fontName = getFontNameFromFileName(file.name);
    if (hasSameFontName(fontName, existingFontPaths)) {
      throw Exception('已添加同名字体：$fontName');
    }

    final dir = await _fontDirectory();
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.name)}';
    final targetPath = p.join(dir.path, fileName);
    await file.saveTo(targetPath);
    await loadFont(targetPath);
    return targetPath;
  }

  Future<void> deleteFont(String fontPath) async {
    if (fontPath.isEmpty) {
      return;
    }
    final file = File(fontPath);
    if (!await file.exists()) {
      _loadedFontPaths.remove(fontPath);
      return;
    }
    final fontDir = await _fontDirectory();
    final fontDirPath = p.canonicalize(fontDir.path);
    final fontPathToDelete = p.canonicalize(file.path);
    if (!p.isWithin(fontDirPath, fontPathToDelete)) {
      return;
    }
    await file.delete();
    _loadedFontPaths.remove(fontPath);
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
