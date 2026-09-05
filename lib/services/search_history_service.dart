import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/local_storage_service.dart';

/// 本地搜索建议的一条：来自阅读记录或本地收藏
class LocalSearchSuggestion {
  LocalSearchSuggestion({
    required this.id,
    required this.title,
    required this.from,
  });

  final int id;
  final String title;

  /// 来源说明，例如「阅读记录」「本地收藏」
  final String from;
}

/// 搜索历史与本地建议
///
/// 官方的热门搜索接口早就 404 了，所以建议改用本机资料：
/// 搜过的关键词、看过的作品、收藏的作品。
class SearchHistoryService {
  static const int kMaxItems = 20;

  static String _key(int type) => type == AppConstant.kTypeNovel
      ? LocalStorageService.kNovelSearchHistory
      : LocalStorageService.kComicSearchHistory;

  static List<String> get(int type) {
    try {
      var value = LocalStorageService.instance
          .getValue<List<dynamic>>(_key(type), const <dynamic>[]);
      return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } catch (e) {
      // 旧资料型别不对就当作没有历史
      return [];
    }
  }

  static Future<void> add(int type, String keyword) async {
    var text = keyword.trim();
    if (text.isEmpty) {
      return;
    }
    var list = get(type)..removeWhere((e) => e == text);
    list.insert(0, text);
    if (list.length > kMaxItems) {
      list = list.sublist(0, kMaxItems);
    }
    await LocalStorageService.instance.setValue(_key(type), list);
  }

  static Future<void> remove(int type, String keyword) async {
    var list = get(type)..removeWhere((e) => e == keyword);
    await LocalStorageService.instance.setValue(_key(type), list);
  }

  static Future<void> clear(int type) async {
    await LocalStorageService.instance.removeValue(_key(type));
  }

  /// 依输入的关键词，从阅读记录与本地收藏里挑出可能想找的作品
  static List<LocalSearchSuggestion> suggest(int type, String keyword) {
    var text = keyword.trim().toLowerCase();
    if (text.isEmpty) {
      return [];
    }
    var db = DBService.instance;
    var result = <int, LocalSearchSuggestion>{};

    void put(int id, String title, String from) {
      if (id == 0 || title.isEmpty || result.containsKey(id)) {
        return;
      }
      if (!title.toLowerCase().contains(text)) {
        return;
      }
      result[id] = LocalSearchSuggestion(id: id, title: title, from: from);
    }

    if (type == AppConstant.kTypeNovel) {
      for (var item in db.getNovelHistoryList()) {
        put(item.novelId, item.novelName, "阅读记录");
      }
    } else {
      for (var item in db.getComicHistoryList()) {
        put(item.comicId, item.comicName, "阅读记录");
      }
    }
    for (var item in db.localFavoriteBox.values) {
      if (item.type != type) {
        continue;
      }
      put(item.objId, item.title, "本地收藏");
    }
    return result.values.take(8).toList();
  }
}
