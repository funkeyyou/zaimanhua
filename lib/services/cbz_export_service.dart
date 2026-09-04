import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/db/comic_download_info.dart';

/// 把已下載的章節打包成 cbz
///
/// 下載的圖片存在 App 私有目錄（安卓在檔案管理器裡看不到），
/// 匯出成 cbz 之後才好丟到別的閱讀器或備份。
class CbzExportService {
  CbzExportService._();

  /// 匯出指定章節，回傳實際產生的檔案路徑
  static Future<List<String>> exportChapters({
    required List<ComicDownloadInfo> chapters,
    required String outputDir,
    void Function(int done, int total)? onProgress,
  }) async {
    var results = <String>[];
    var dir = Directory(outputDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    var done = 0;
    for (var info in chapters) {
      try {
        var source = Directory(info.savePath);
        if (await source.exists()) {
          var target = p.join(outputDir, '${fileNameOf(info)}.cbz');
          // 章節目錄裡就是 001.jpg、002.jpg…，整包壓進去即可
          await ZipFileEncoder().zipDirectory(source, filename: target);
          results.add(target);
        }
      } catch (e) {
        Log.logPrint(e);
      }
      onProgress?.call(++done, chapters.length);
    }
    return results;
  }

  /// 檔名：漫畫名_章節名（去掉檔案系統不接受的字元）
  static String fileNameOf(ComicDownloadInfo info) =>
      sanitize('${info.comicName}_${info.chapterName}');

  static String sanitize(String raw) {
    var name = raw.replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), '_').trim();
    if (name.isEmpty) {
      name = 'comic';
    }
    return name.length > 80 ? name.substring(0, 80) : name;
  }
}
