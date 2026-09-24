import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/modules/hitomi/hitomi_page.dart';
import 'package:zai_x/modules/hitomi/hitomi_source.dart';
import 'package:zai_x/modules/hitomi/hitomi_library.dart';

class _Source extends HitomiSource {
  final queries = <String>[];
  @override
  Future<void> refreshRules({bool force = false}) async {}
  @override
  Future<List<int>> list(String query, String language) async {
    queries.add('$query|$language');
    return [];
  }
}

void main() {
  testWidgets('independent shelf, history and hide action fit phone and tablet',
      (tester) async {
    late Directory dir;
    late HitomiLibrary library;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('hitomi-ui-');
      library =
          HitomiLibrary(await Hive.openBox('hitomi_ui_test', path: dir.path));
      await library.save({
        'id': 1,
        'title': 'Saved comic',
        'files': [],
        'tags': [
          {'tag': 'sample'}
        ]
      }, favorite: true);
    });
    var hidden = false;
    for (final width in [360.0, 1000.0]) {
      final source = _Source();
      await tester.binding.setSurfaceSize(Size(width, 850));
      await tester.pumpWidget(MaterialApp(
          home: HitomiPage(
              source: source,
              library: Future.value(library),
              onHide: () => hidden = true)));
      await tester.pumpAndSettle();
      // The hidden source keeps a neutral name in the visible UI.
      expect(find.text('画廊'), findsOneWidget);
      expect(find.textContaining('Hitomi'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('hitomi-category')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('同人志').last);
      await tester.pumpAndSettle();
      expect(source.queries.last, 'type:doujinshi|chinese');
      await tester.tap(find.byTooltip('清除筛选'));
      await tester.pumpAndSettle();
      expect(source.queries.last, '|chinese');
      await tester.tap(find.text('书架'));
      await tester.pumpAndSettle();
      expect(find.text('Saved comic'), findsOneWidget);
      expect(find.text('全部标签'), findsOneWidget);
      await tester.tap(find.text('浏览记录'));
      await tester.pumpAndSettle();
      expect(find.text('暂无记录'), findsOneWidget);
      await tester.tap(find.byTooltip('隐藏入口'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('隐藏'));
      await tester.pumpAndSettle();
      expect(hidden, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    await tester.binding.setSurfaceSize(null);
    await tester.runAsync(() async {
      await library.box.close();
      await dir.delete(recursive: true);
    });
  });
}
