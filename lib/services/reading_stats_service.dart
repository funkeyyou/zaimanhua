import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/log.dart';

/// 某一天的阅读量
class DailyReadingStat {
  DailyReadingStat({
    required this.day,
    required this.comicChapters,
    required this.novelChapters,
    required this.seconds,
  });

  final DateTime day;
  final int comicChapters;
  final int novelChapters;
  final int seconds;

  int get chapters => comicChapters + novelChapters;

  bool get isEmpty => chapters == 0 && seconds == 0;
}

/// 阅读统计
///
/// 只在本机累计：看了几话、花了多少时间，不上传任何东西。
class ReadingStatsService extends GetxService {
  static ReadingStatsService get instance => Get.find<ReadingStatsService>();

  /// 服务还没就绪时（例如背景 isolate、单元测试）安静跳过，别把阅读流程带塌
  static ReadingStatsService? get _maybe =>
      Get.isRegistered<ReadingStatsService>() ? instance : null;

  /// 看完一话（安全版）
  static void recordChapter(int type) {
    _maybe?.addChapter(type);
  }

  /// 累计阅读时间（安全版）
  static void recordSeconds(int seconds) {
    _maybe?.addSeconds(seconds);
  }

  /// 保留最近半年
  static const int kKeepDays = 180;

  late Box statsBox;

  /// 用来让统计页在阅读后自动刷新
  final revision = 0.obs;

  Future init() async {
    var dir = await getApplicationSupportDirectory();
    statsBox = await Hive.openBox("ZaiReadingStats", path: dir.path);
    await _cleanup();
  }

  static String keyOf(DateTime time) {
    var month = time.month.toString().padLeft(2, '0');
    var day = time.day.toString().padLeft(2, '0');
    return '${time.year}-$month-$day';
  }

  /// 看完一话
  Future<void> addChapter(int type, {DateTime? at}) async {
    var field = type == AppConstant.kTypeNovel ? 'novel' : 'comic';
    await _bump(field, 1, at: at);
  }

  /// 累计阅读时间；太短的停留（例如误触）不计
  Future<void> addSeconds(int seconds, {DateTime? at}) async {
    if (seconds < 5) {
      return;
    }
    await _bump('sec', seconds, at: at);
  }

  Future<void> _bump(String field, int delta, {DateTime? at}) async {
    try {
      var key = keyOf(at ?? DateTime.now());
      var raw = statsBox.get(key);
      var map = <String, int>{'comic': 0, 'novel': 0, 'sec': 0};
      if (raw is Map) {
        raw.forEach((k, v) {
          var name = k.toString();
          if (map.containsKey(name)) {
            map[name] = v is int ? v : int.tryParse(v.toString()) ?? 0;
          }
        });
      }
      map[field] = (map[field] ?? 0) + delta;
      await statsBox.put(key, map);
      revision.value++;
    } catch (e) {
      Log.logPrint(e);
    }
  }

  DailyReadingStat statOf(DateTime day) {
    var raw = statsBox.get(keyOf(day));
    var comic = 0;
    var novel = 0;
    var seconds = 0;
    if (raw is Map) {
      comic = _asInt(raw['comic']);
      novel = _asInt(raw['novel']);
      seconds = _asInt(raw['sec']);
    }
    return DailyReadingStat(
      day: DateTime(day.year, day.month, day.day),
      comicChapters: comic,
      novelChapters: novel,
      seconds: seconds,
    );
  }

  /// 最近 n 天，最早的排前面
  List<DailyReadingStat> recentDays(int days) {
    var today = DateTime.now();
    return List.generate(
      days,
      (i) => statOf(today.subtract(Duration(days: days - 1 - i))),
    );
  }

  DailyReadingStat get today => statOf(DateTime.now());

  /// 全部累计
  DailyReadingStat get total {
    var comic = 0;
    var novel = 0;
    var seconds = 0;
    for (var raw in statsBox.values) {
      if (raw is! Map) continue;
      comic += _asInt(raw['comic']);
      novel += _asInt(raw['novel']);
      seconds += _asInt(raw['sec']);
    }
    return DailyReadingStat(
      day: DateTime.now(),
      comicChapters: comic,
      novelChapters: novel,
      seconds: seconds,
    );
  }

  /// 连续阅读天数：从今天（或昨天）往前数
  int get streak {
    var today = DateTime.now();
    var count = 0;
    for (var i = 0; i < kKeepDays; i++) {
      var stat = statOf(today.subtract(Duration(days: i)));
      if (stat.isEmpty) {
        // 今天还没看不算断，昨天没看才算断
        if (i == 0) continue;
        break;
      }
      count++;
    }
    return count;
  }

  /// 有阅读记录的总天数
  int get activeDays => statsBox.keys.length;

  Future<void> clear() async {
    await statsBox.clear();
    revision.value++;
  }

  /// 丢掉太旧的记录
  Future<void> _cleanup() async {
    try {
      var limit = keyOf(DateTime.now().subtract(const Duration(days: kKeepDays)));
      var expired = statsBox.keys
          .where((k) => k.toString().compareTo(limit) < 0)
          .toList();
      if (expired.isNotEmpty) {
        await statsBox.deleteAll(expired);
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
