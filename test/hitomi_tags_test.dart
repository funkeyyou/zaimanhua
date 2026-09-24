import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/modules/hitomi/hitomi_source.dart';
import 'package:zai_x/modules/hitomi/hitomi_tag_picker.dart';

class _Source extends HitomiSource {
  @override
  Future<List<String>> allTags() async => ['alpha', 'another', 'beta'];
  final calls = <String>[];
  @override
  Future<List<String>> tags(String letter) async =>
      letter == 'a' ? ['alpha', 'another'] : ['beta'];
  @override
  Future<List<int>> list(String query, String language) async {
    calls.add('$query|$language');
    return switch (query) {
      'type:manga' => [5, 4, 3, 2],
      'tag:alpha' => [4, 3, 2],
      'tag:beta' => [3, 2, 1],
      _ => []
    };
  }
}

void main() {
  test('catalog extracts decoded unique tags without external links', () {
    expect(
        HitomiSource.parseTags(
            '<a href="/tag/a%20b-all.html">x</a><a href="/tag/a%20b-all.html">x</a><a href="https://evil.test/tag/no-all.html">x</a><a href="/artist/no-all.html">x</a>'),
        ['a b']);
  });
  test('multiple tags intersect category and preserve order', () async {
    final source = _Source();
    expect(
        await source.filteredList('', 'chinese', 'manga',
            tags: ['alpha', 'beta', 'alpha']),
        [3, 2]);
    expect(source.calls,
        ['type:manga|chinese', 'tag:alpha|chinese', 'tag:beta|chinese']);
    source.dio.close();
  });
  testWidgets(
      'picker preserves selection across letters and applies explicitly',
      (tester) async {
    final source = _Source();
    List<String>? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await showModalBottomSheet<List<String>>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => SizedBox(
                              height: 550,
                              child: HitomiTagPicker(
                                  source: source, selected: const [])));
                    },
                    child: const Text('Open'))))));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bet');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(CheckboxListTile, 'beta'), findsOneWidget);
    expect(find.widgetWithText(CheckboxListTile, 'alpha'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'beta'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('应用 (2)'));
    await tester.pumpAndSettle();
    expect(result, ['alpha', 'beta']);
    source.dio.close();
  });
}
