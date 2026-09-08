import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/widgets/recommendation_banner.dart';

void main() {
  testWidgets('wide recommendation art leaves room for the book lists',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    int? selected;
    Widget page() => MaterialApp(
            home: Scaffold(
                body: Column(children: [
          RecommendationBanner(
              images: const ['', '', ''],
              titles: const ['First', 'Second', 'Third'],
              autoplay: false,
              onSelected: (index) => selected = index),
          const Text('Bookshelf preview'),
        ])));
    await tester.binding.setSurfaceSize(const Size(360, 800));
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Bookshelf preview')).dy, lessThan(230));
    await tester.tap(find.text('First').first);
    expect(selected, 0);
    await tester.binding.setSurfaceSize(const Size(1600, 800));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Bookshelf preview')).dy, lessThan(320));
    expect(tester.takeException(), isNull);
  });
}
