import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/routes/route_path.dart';

/// 阅读器(主路由)关闭后，内容区(子路由)必须还停在漫画详情页。
void main() {
  Widget buildApp() {
    return GetMaterialApp(
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => Stack(
            children: [
              const Scaffold(body: Center(child: Text('BOOKSHELF'))),
              Navigator(
                key: AppNavigator.subNavigatorKey,
                initialRoute: '/',
                observers: [_TestSubObserver()],
                onGenerateRoute: (settings) => GetPageRoute(
                  settings: settings,
                  page: () => settings.name == RoutePath.kComicDetail
                      ? const Scaffold(body: Center(child: Text('DETAIL')))
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        GetPage(
          name: RoutePath.kComicReader,
          page: () => const Scaffold(body: Center(child: Text('READER'))),
        ),
      ],
    );
  }

  Future<void> openReader(WidgetTester tester) async {
    AppNavigator.toComicReader(
      comicId: 64175,
      comicTitle: 'test',
      comicCover: '',
      chapters: const <ComicDetailChapterItem>[],
      chapter: ComicDetailChapterItem(
        chapterId: 1,
        chapterTitle: 'c1',
        updateTime: 0,
        fileSize: 0,
        chapterOrder: 1,
      ),
      isLongComic: false,
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    AppNavigator.currentContentRouteName = '/';
  });

  testWidgets('正常返回时不重复推详情页', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    AppNavigator.toComicDetail(64175);
    await tester.pumpAndSettle();
    await openReader(tester);
    expect(find.text('READER'), findsOneWidget);

    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('DETAIL'), findsOneWidget);
    expect(AppNavigator.subNavigatorKey!.currentState!.canPop(), isTrue);
  });

  testWidgets('详情页被一起退掉时会自动补回来', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    AppNavigator.toComicDetail(64175);
    await tester.pumpAndSettle();
    await openReader(tester);

    // 模拟「一次返回退掉两层」：阅读器 + 子路由的详情页
    AppNavigator.subNavigatorKey!.currentState!.pop();
    Get.back();
    await tester.pumpAndSettle();

    expect(find.text('DETAIL'), findsOneWidget);
    expect(find.text('READER'), findsNothing);
  });
}

class _TestSubObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      AppNavigator.currentContentRouteName = route.settings.name ?? '';
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    AppNavigator.currentContentRouteName = previousRoute?.settings.name ?? '';
  }
}
