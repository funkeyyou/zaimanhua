import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/modules/bookshelf/recent_comics.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/widgets/adaptive_workspace.dart';

ComicHistory history(int id, {int page = 5}) => ComicHistory(
      comicId: id,
      chapterId: id * 10,
      comicName: 'Comic $id',
      comicCover: '',
      chapterName: 'Chapter $id',
      updateTime: DateTime(2026, 9, id),
      page: page,
    );

void main() {
  testWidgets('recent row reveals more books when unfolded and keeps one row',
      (tester) async {
    final books = List.generate(12, (index) => history(index + 1));
    int? selected;
    Widget page(double scale) => MaterialApp(
            home: Scaffold(
                body: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: RecentComicsRow(
              histories: books, onSelected: (book) => selected = book.comicId),
        )));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(360, 900));
    await tester.pumpWidget(page(1));
    final card = find.byWidgetPredicate((widget) =>
        widget is InkWell && widget.key.toString().contains('recent-'));
    expect(card, findsNWidgets(3));
    final narrowWidth =
        tester.getSize(find.byKey(const ValueKey('recent-1'))).width;
    await tester.tap(find.byKey(const ValueKey('recent-2')));
    expect(selected, 2);

    await tester.binding.setSurfaceSize(const Size(1000, 900));
    await tester.pump();
    expect(card.evaluate().length, greaterThan(3));
    final positions = card
        .evaluate()
        .map((element) => tester.getTopLeft(find.byWidget(element.widget)).dy)
        .toSet();
    expect(positions.length, 1);
    expect(tester.getSize(find.byKey(const ValueKey('recent-1'))).width,
        lessThan(narrowWidth * 1.5));
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(320, 900));
    await tester.pumpWidget(page(1.8));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'recent history reacts to saved pages without reopening the shelf',
      (tester) async {
    Get.testMode = true;
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ComicHistoryAdapter());
    }
    late Directory directory;
    final db = DBService();
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('zmh-recent-ui-');
      db.comicHistoryBox =
          await Hive.openBox<ComicHistory>('recent-ui', path: directory.path);
    });
    Get.put<DBService>(db);
    await tester.runAsync(() async => db.putComicHistory(history(1)));
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: RecentComics())));
    expect(find.text('第5页'), findsOneWidget);
    await tester.runAsync(() async => db.putComicHistory(history(1, page: 17)));
    await tester.pump();
    expect(find.text('第17页'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    Get.reset();
    await tester.runAsync(() async {
      await db.comicHistoryBox.close();
      await directory.delete(recursive: true);
    });
  });

  testWidgets(
      'workspace uses full width and preserves scroll and nested routes across folding',
      (tester) async {
    final scroll = ScrollController();
    final navigator = GlobalKey<NavigatorState>();
    Widget page(bool showDetail) => MaterialApp(
            home: Scaffold(
                body: AdaptiveWorkspace(
          showDetail: showDetail,
          primary: ListView.builder(
              key: const ValueKey('shelf'),
              controller: scroll,
              itemExtent: 64,
              itemCount: 100,
              itemBuilder: (_, i) => Text('Book $i')),
          detail: Navigator(
              key: navigator,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(body: Text('Root')))),
        )));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    await tester.pumpWidget(page(false));
    expect(tester.getSize(find.byKey(const ValueKey('shelf'))).width, 1200);
    scroll.jumpTo(640);
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Detail'))));
    await tester.pumpWidget(page(true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const ValueKey('shelf'))).width,
        lessThan(500));
    expect(scroll.offset, 640);
    expect(find.text('Detail'), findsOneWidget);
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);
    expect(navigator.currentState!.canPop(), isTrue);
    expect(scroll.offset, 640);
    await tester.pumpWidget(page(false));
    await tester.pumpAndSettle();
    expect(scroll.offset, 640);
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });
}
