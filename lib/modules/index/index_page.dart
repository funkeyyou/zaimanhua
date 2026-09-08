import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zai_x/widgets/adaptive_workspace.dart';
import 'package:zai_x/modules/common/empty_page.dart';
import 'package:zai_x/modules/index/index_controller.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:zai_x/app/i18n.dart';

class IndexPage extends GetView<IndexController> {
  const IndexPage({super.key});

  @override
  Widget build(BuildContext context) {
    final content = _buildContentNavigator();
    final indexStack = _buildIndexStack();
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 840;
      return Obx(() => Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: wide ? 84 : 0,
                  child: wide ? _buildRail(context) : const SizedBox.shrink(),
                ),
                Expanded(
                  child: AdaptiveWorkspace(
                    primary: indexStack,
                    detail: content,
                    showDetail: controller.showContent.value,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: wide || controller.showContent.value
                ? null
                : BottomNavigationBar(
                    currentIndex: controller.index.value,
                    onTap: controller.setIndex,
                    type: BottomNavigationBarType.fixed,
                    showSelectedLabels: true,
                    showUnselectedLabels: true,
                    selectedFontSize: 12,
                    unselectedFontSize: 12,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    elevation: 4,
                    items: [
                      for (var i = 0; i < _labels.length; i++)
                        BottomNavigationBarItem(
                          icon: Icon(_icons[i]),
                          activeIcon: Icon(_activeIcons[i]),
                          label: _labels[i].i18n,
                        ),
                    ],
                  ),
          ));
    });
  }

  static const _labels = ['漫画', '资讯', '轻小说', '书架', '我的'];
  static const _icons = [
    Remix.book_2_line,
    Remix.article_line,
    Remix.book_open_line,
    Remix.book_marked_line,
    Remix.user_smile_line,
  ];
  static const _activeIcons = [
    Remix.book_2_fill,
    Remix.article_fill,
    Remix.book_open_fill,
    Remix.book_marked_fill,
    Remix.user_smile_fill,
  ];

  Widget _buildRail(BuildContext context) {
    return NavigationRail(
      minWidth: 84,
      scrollable: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: controller.setIndex,
      selectedIndex: controller.index.value,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset('assets/images/zaimanhua_x.png',
              width: 40, height: 40),
        ),
      ),
      selectedLabelTextStyle:
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: const TextStyle(fontSize: 12),
      destinations: [
        for (var i = 0; i < _labels.length; i++)
          NavigationRailDestination(
            icon: Icon(_icons[i]),
            selectedIcon: Icon(_activeIcons[i]),
            label: Text(_labels[i].i18n),
          ),
      ],
    );
  }

  Widget _buildIndexStack() {
    return Obx(
      () => IndexedStack(
        key: controller.indexKey,
        index: controller.index.value,
        children: [
          for (var i = 0; i < controller.pages.length; i++)
            TickerMode(
              key: ValueKey(i),
              enabled: controller.index.value == i,
              child: controller.pages[i],
            ),
        ],
      ),
    );
  }

  /// 子路由
  Widget _buildContentNavigator() {
    /// 拦截子路由的返回
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // 阅读器等主路由刚关闭时，忽略紧跟着的重复返回事件，
          // 否则会把子路由的详情页(选集页面)一起退掉，直接掉回底部分页。
          if (AppNavigator.justClosedMainRoute) {
            return;
          }
          if (Navigator.canPop(Get.context!)) {
            Get.back();
            return;
          } else if (AppNavigator.subNavigatorKey!.currentState!.canPop()) {
            AppNavigator.subNavigatorKey!.currentState!.pop();
            return;
          }

          if (controller.doubleClickExit) {
            controller.doubleClickTimer?.cancel();
            SystemNavigator.pop();
            return;
          }
          controller.setDoubleExitFlag();
        }
      },
      // onWillPop: () async {
      //   if (Navigator.canPop(Get.context!)) {
      //     return true;
      //   }
      //   if (AppNavigator.subNavigatorKey!.currentState!.canPop()) {
      //     AppNavigator.subNavigatorKey!.currentState!.pop();
      //     return false;
      //   }
      //   return true;
      // },
      child: ClipRect(
        child: Navigator(
          key: AppNavigator.subNavigatorKey,
          initialRoute: '/',
          onUnknownRoute: (settings) => GetPageRoute(
            page: () => const EmptyPage(),
          ),
          observers: [
            SubNavigatorObserver(),
          ],
          onGenerateRoute: AppPages.generateSubRoute,
        ),
      ),
    );
  }
}

/// 子路由监听
class SubNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      var routeName = route.settings.name ?? "";
      AppNavigator.currentContentRouteName = routeName;
      Get.find<IndexController>().showContent.value = routeName != '/';
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);

    var routeName = previousRoute?.settings.name ?? "";
    AppNavigator.currentContentRouteName = routeName;
    Get.find<IndexController>().showContent.value = routeName != '/';
  }
}
