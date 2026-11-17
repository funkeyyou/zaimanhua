import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/widgets/vertical_zoom_view.dart';

void main() {
  Future<ScrollController> pump(WidgetTester tester) async {
    final controller = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400,
        height: 800,
        child: VerticalZoomView(
          builder: (context, locked) => ListView.builder(
            controller: controller,
            physics: locked ? const NeverScrollableScrollPhysics() : null,
            itemCount: 50,
            itemBuilder: (_, i) => SizedBox(height: 200, child: Text('$i')),
          ),
        ),
      ),
    ));
    return controller;
  }

  Matrix4 transformOf(WidgetTester tester) => tester
      .widget<Transform>(find
          .descendant(
              of: find.byType(VerticalZoomView),
              matching: find.byType(Transform))
          .first)
      .transform;

  testWidgets('双指张开会放大，缩放时列表不跟着滚', (tester) async {
    final list = await pump(tester);
    final a = await tester.startGesture(const Offset(150, 400), pointer: 1);
    final b = await tester.startGesture(const Offset(250, 400), pointer: 2);
    await tester.pump();
    for (var i = 1; i <= 10; i++) {
      await a.moveTo(Offset(150 - i * 5, 400 + i * 3));
      await b.moveTo(Offset(250 + i * 5, 400 + i * 3));
      await tester.pump();
    }
    final scale = transformOf(tester).getMaxScaleOnAxis();
    expect(scale, closeTo(2, 0.05));
    expect(list.offset, 0);
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(transformOf(tester).getMaxScaleOnAxis(), closeTo(2, 0.05));
  });

  testWidgets('放大后单指上下照常滚动、左右平移画面', (tester) async {
    final list = await pump(tester);
    final a = await tester.startGesture(const Offset(150, 400), pointer: 1);
    final b = await tester.startGesture(const Offset(250, 400), pointer: 2);
    await tester.pump();
    for (var i = 1; i <= 10; i++) {
      await a.moveTo(Offset(150 - i * 5, 400));
      await b.moveTo(Offset(250 + i * 5, 400));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    final before = transformOf(tester).getTranslation().x;

    // 测试画面是 800×600，起点要落在画面内
    await tester.dragFrom(const Offset(200, 500), const Offset(60, -300));
    await tester.pumpAndSettle();
    expect(list.offset, greaterThan(0));
    expect(transformOf(tester).getTranslation().x, greaterThan(before));
  });

  testWidgets('捏回原大小会还原', (tester) async {
    await pump(tester);
    final a = await tester.startGesture(const Offset(150, 400), pointer: 1);
    final b = await tester.startGesture(const Offset(250, 400), pointer: 2);
    await tester.pump();
    await a.moveTo(const Offset(140, 400));
    await b.moveTo(const Offset(260, 400));
    await tester.pump();
    await a.moveTo(const Offset(151, 400));
    await b.moveTo(const Offset(251, 400));
    await tester.pump();
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(transformOf(tester).getMaxScaleOnAxis(), 1);
    expect(transformOf(tester).getTranslation().x, 0);
  });
}
