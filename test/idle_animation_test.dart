import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/widgets/page_grid_view.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';

void main() {
  testWidgets('loaded grids stop the hidden loading animation', (tester) async {
    final controller = BasePageController<int>();
    controller.list.add(1);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PageGridView(
      pageController: controller,
      crossAxisCount: 3,
      loadMore: false,
      showPageLoadding: true,
      itemBuilder: (_, i) => const SizedBox(height: 80, child: Text('Ready')),
    ))));
    // Old Offstage loaders keep ticking indefinitely, causing this to time out.
    await tester.pumpAndSettle(const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3));
    expect(find.byType(AppLoaddingWidget, skipOffstage: false), findsNothing);
    controller.pageLoadding.value = true;
    await tester.pump();
    expect(find.byType(AppLoaddingWidget), findsOneWidget);
    controller.pageLoadding.value = false;
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(const SizedBox());
    controller.scrollController.dispose();
    controller.easyRefreshController.dispose();
  });
}
