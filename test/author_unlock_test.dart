import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/modules/hitomi/author_unlock.dart';

void main() {
  testWidgets('author requires ten taps and reopening resets partial sequence',
      (tester) async {
    var unlocks = 0;
    Widget screen() =>
        MaterialApp(home: Scaffold(body: AuthorUnlock(onUnlock: () async {
          unlocks++;
        })));
    await tester.pumpWidget(screen());
    for (var i = 0; i < 9; i++) {
      await tester.tap(find.text('funkeyyou'));
    }
    expect(unlocks, 0);
    await tester.tap(find.text('funkeyyou'));
    await tester.pump();
    expect(unlocks, 1);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('funkeyyou'));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen());
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('funkeyyou'));
    }
    expect(unlocks, 1);
  });
}
