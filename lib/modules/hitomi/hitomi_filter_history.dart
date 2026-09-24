import 'dart:convert';
import 'package:hive/hive.dart';

class HitomiFilterHistory {
  HitomiFilterHistory(this.box);
  final Box box;
  static const key = 'HitomiRecentFiltersV1';
  List<Map<String, dynamic>> read() =>
      (box.get(key, defaultValue: <dynamic>[]) as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  Future<void> remember(
      {required String query,
      required String language,
      required String category,
      required List<String> tags}) async {
    final normalized = tags.toSet().toList()..sort();
    if (query.trim().isEmpty &&
        language == 'chinese' &&
        category.isEmpty &&
        normalized.isEmpty) {
      return;
    }
    final entry = <String, dynamic>{
      'query': query.trim(),
      'language': language,
      'category': category,
      'tags': normalized
    };
    final signature = jsonEncode(entry);
    final entries = read()..removeWhere((e) => jsonEncode(e) == signature);
    await box.put(key, [entry, ...entries].take(10).toList());
  }

  Future<void> clear() => box.delete(key);
}
