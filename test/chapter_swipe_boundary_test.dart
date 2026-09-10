import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/widgets/chapter_swipe_boundary.dart';

void main() {
  testWidgets('short fling turns chapters in both reading directions',
      (tester) async {
    for (final reverse in [false, true]) {
      var next = 0;
      var previous = 0;
      await tester.pumpWidget(MaterialApp(
          home: ChapterSwipeBoundary(
        reverse: reverse,
        canGoPrevious: true,
        canGoNext: true,
        onNext: () => next++,
        onPrevious: () => previous++,
        child: const ColoredBox(color: Colors.black),
      )));
      await tester.fling(
          find.byType(ColoredBox).last, Offset(reverse ? 35 : -35, 0), 1000);
      expect(next, 1);
      expect(previous, 0);
      await tester.fling(
          find.byType(ColoredBox).last, Offset(reverse ? -35 : 35, 0), 1000);
      expect(previous, 1);
    }
  });

  testWidgets('small drags, vertical gestures and pinch do not turn chapters',
      (tester) async {
    var turns = 0;
    await tester.pumpWidget(MaterialApp(
        home: ChapterSwipeBoundary(
      canGoPrevious: true,
      canGoNext: true,
      onNext: () => turns++,
      onPrevious: () => turns++,
      child: const ColoredBox(color: Colors.black),
    )));
    final target = find.byType(ColoredBox).last;
    await tester.timedDrag(
        target, const Offset(-35, 0), const Duration(seconds: 2));
    await tester.fling(target, const Offset(-35, 150), 1000);
    final first = await tester.startGesture(const Offset(300, 300), pointer: 1);
    final second =
        await tester.startGesture(const Offset(400, 300), pointer: 2);
    await first.moveBy(const Offset(-250, 0));
    await second.up();
    await first.up();
    expect(turns, 0);
  });

  testWidgets('ordinary page fling cannot skip into another chapter',
      (tester) async {
    var turns = 0;
    var atEnd = false;
    late StateSetter rebuild;
    await tester.pumpWidget(
        MaterialApp(home: StatefulBuilder(builder: (context, setState) {
      rebuild = setState;
      return ChapterSwipeBoundary(
        canGoPrevious: false,
        canGoNext: atEnd,
        onNext: () => turns++,
        onPrevious: () => turns++,
        child: const ColoredBox(color: Colors.black),
      );
    })));
    final gesture = await tester.startGesture(const Offset(400, 300));
    await gesture.moveBy(const Offset(-450, 0));
    rebuild(() => atEnd = true);
    await tester.pump();
    await gesture.up();
    expect(turns, 0);
  });
}
