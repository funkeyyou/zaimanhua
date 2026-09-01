import 'package:zai_x/app/log.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:zai_x/services/local_storage_service.dart';

/// 訂閱清單的標籤來源。
///
/// 訂閱清單 API 只回傳書名、封面、最新話等欄位，並沒有題材標籤，因此標籤要
/// 逐本從漫畫詳情補抓。抓過的結果會存進本機，之後就不必再打同一支 API。
class SubscribeTagService {
  SubscribeTagService._();

  static const String kCacheKey = 'SubscribeTagsCache';
  static const int _concurrency = 5;

  static Map<String, List<String>>? _cache;

  static Map<String, List<String>> get cache {
    if (_cache != null) {
      return _cache!;
    }
    var stored = LocalStorageService.instance
        .getValue<Map>(kCacheKey, <String, dynamic>{});
    var map = <String, List<String>>{};
    stored.forEach((k, v) {
      if (v is List) {
        map['$k'] = v.map((e) => '$e').toList();
      }
    });
    _cache = map;
    return _cache!;
  }

  static List<String> tagsOf(int comicId) => cache['$comicId'] ?? const [];

  static Future<void> _save() async {
    await LocalStorageService.instance.setValue(kCacheKey, cache);
  }

  /// 補抓缺少標籤的漫畫，回傳是否有新增資料
  /// * [comicIds] 需要標籤的漫畫
  /// * [limit] 單次最多補抓幾本，避免一次打太多請求
  static Future<bool> fetchMissing(
    List<int> comicIds, {
    int limit = 60,
  }) async {
    var missing = comicIds
        .where((id) => !cache.containsKey('$id'))
        .toSet()
        .take(limit)
        .toList();
    if (missing.isEmpty) {
      return false;
    }
    var request = ComicRequest();
    for (var i = 0; i < missing.length; i += _concurrency) {
      var chunk = missing.skip(i).take(_concurrency).toList();
      await Future.wait(chunk.map((id) async {
        try {
          var detail = await request.comicDetail(comicId: id);
          cache['$id'] = detail.types.map((e) => e.tagName).toList();
        } catch (e) {
          // 讀不到（例如需要登入或等級限制）就記成空的，避免每次重試
          Log.logPrint(e);
          cache['$id'] = const [];
        }
      }));
    }
    await _save();
    return true;
  }

  /// 由目前的訂閱清單彙整可選標籤（依出現次數排序）
  static List<String> availableTags(List<int> comicIds) {
    var counts = <String, int>{};
    for (var id in comicIds) {
      for (var tag in tagsOf(id)) {
        if (tag.isEmpty) continue;
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    var tags = counts.keys.toList();
    tags.sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return tags;
  }
}

