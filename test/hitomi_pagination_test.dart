import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/modules/hitomi/hitomi_grid.dart';
import 'package:zai_x/modules/hitomi/hitomi_library.dart';
import 'package:zai_x/modules/hitomi/hitomi_page.dart';
import 'package:zai_x/modules/hitomi/hitomi_source.dart';

class _Source extends HitomiSource {
  final fetched = <int>[];
  @override
  Future<void> refreshRules({bool force = false}) async {}
  @override
  Future<List<int>> list(String query, String language) async =>
      List.generate(100, (i) => i + 1);
  @override
  Future<Map<String, dynamic>> gallery(int id) async {
    fetched.add(id);
    return {'id': id, 'title': 'Book $id', 'files': [], 'tags': []};
  }
}

void main() {
  test('batch fills whole rows and never exceeds actual results', () {
    expect(hitomiBatchEnd(0, 100, 5), 20);
    expect(hitomiBatchEnd(18, 100, 5, fillRowOnly: true), 20);
    expect(hitomiBatchEnd(20, 23, 5), 23);
  });
  testWidgets('unfold fills row and scrolling loads more without duplicates',
      (tester) async {
    late Directory dir;
    late Box box;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('hitomi-pagination-');
      box = await Hive.openBox('pagination_test', path: dir.path);
    });
    final source = _Source();
    await tester.binding.setSurfaceSize(const Size(360, 850));
    await tester.pumpWidget(MaterialApp(
        home: HitomiPage(
            source: source,
            library: Future.value(HitomiLibrary(box)),
            onHide: () {})));
    await tester.pumpAndSettle();
    expect(source.fetched.length, 18);
    await tester.binding.setSurfaceSize(const Size(800, 850));
    await tester.pumpAndSettle();
    expect(source.fetched.length % 5, 0);
    final before = source.fetched.length;
    await tester.drag(find.byKey(const ValueKey('hitomi-explore-list')),
        const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(source.fetched.length, greaterThan(before));
    expect(source.fetched.toSet().length, source.fetched.length);
    expect(find.text('加载更多'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
    await tester.runAsync(() async {
      await box.close();
      await dir.delete(recursive: true);
    });
  });
  testWidgets('taller desktop window loads more without scrolling',
      (tester) async {
    late Directory dir;
    late Box box;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('hitomi-resize-');
      box = await Hive.openBox('resize_test', path: dir.path);
    });
    final source = _Source();
    await tester.binding.setSurfaceSize(const Size(800, 600));
    await tester.pumpWidget(MaterialApp(
        home: HitomiPage(
            source: source,
            library: Future.value(HitomiLibrary(box)),
            onHide: () {})));
    await tester.pumpAndSettle();
    final before = source.fetched.length;
    expect(before, 20);
    // Same width keeps five columns; only the window height grows, so the
    // list cannot be scrolled until another batch arrives.
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    await tester.pumpAndSettle();
    expect(source.fetched.length, greaterThan(before));
    expect(source.fetched.length % 5, 0);
    expect(source.fetched.toSet().length, source.fetched.length);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.binding.setSurfaceSize(null);
    await tester.runAsync(() async {
      await box.close();
      await dir.delete(recursive: true);
    });
  });
}
