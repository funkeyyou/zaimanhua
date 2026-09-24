import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/modules/hitomi/hitomi_filter_history.dart';

void main() {
  test('recent filters deduplicate, cap ten, persist all fields, and clear',
      () async {
    final dir = await Directory.systemTemp.createTemp('hitomi-filters-');
    var box = await Hive.openBox('filter_test', path: dir.path);
    try {
      var history = HitomiFilterHistory(box);
      for (var i = 0; i < 12; i++) {
        await history.remember(
            query: '$i',
            language: 'japanese',
            category: 'manga',
            tags: ['beta', 'alpha']);
      }
      await history.remember(
          query: '5',
          language: 'japanese',
          category: 'manga',
          tags: ['alpha', 'beta']);
      expect(history.read(), hasLength(10));
      expect(history.read().first['query'], '5');
      await box.close();
      box = await Hive.openBox('filter_test', path: dir.path);
      history = HitomiFilterHistory(box);
      expect(history.read().first, {
        'query': '5',
        'language': 'japanese',
        'category': 'manga',
        'tags': ['alpha', 'beta']
      });
      await history.clear();
      expect(history.read(), isEmpty);
    } finally {
      await box.close();
      await dir.delete(recursive: true);
    }
  });
}
