import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/// Isolated from Zaimanhua IDs, account synchronization and recent reading.
class HitomiLibrary {
  static const boxName = 'hitomi_library_v1';
  final Box box;
  HitomiLibrary(this.box);

  /// Hive.initFlutter() defaults to the user's Documents folder on desktop.
  /// Desktop keeps this box beside the app's other data; mobile keeps its
  /// private default directory so existing favorites are still found.
  static Future<HitomiLibrary> open({
    bool? desktop,
    Future<Directory> Function() supportDirectory =
        getApplicationSupportDirectory,
  }) async {
    final useSupport =
        desktop ?? (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final path = useSupport ? (await supportDirectory()).path : null;
    return HitomiLibrary(await Hive.openBox(boxName, path: path));
  }

  String id(Map gallery) => gallery['id'].toString();
  Map? entry(String id) => box.get(id) as Map?;
  bool favorite(Map gallery) => entry(id(gallery))?['favorite'] == true;
  int page(Map gallery) => (entry(id(gallery))?['page'] as int?) ?? 0;
  Future<void> save(Map gallery, {bool? favorite, int? page}) async {
    final old = entry(id(gallery));
    await box.put(id(gallery), {
      'gallery': gallery,
      'favorite': favorite ?? old?['favorite'] ?? false,
      'page': page ?? old?['page'] ?? 0,
      'readAt': page != null
          ? DateTime.now().millisecondsSinceEpoch
          : old?['readAt'] ?? 0,
    });
  }

  List<Map> entries({required bool favorites}) {
    final items = box.values
        .cast<Map>()
        .where(
            (e) => favorites ? e['favorite'] == true : (e['readAt'] as int) > 0)
        .toList();
    items.sort((a, b) => (b['readAt'] as int).compareTo(a['readAt'] as int));
    return items;
  }
}
