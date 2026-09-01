import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zai_x/app/app_style.dart';
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
    return OrientationBuilder(
      builder: (context, orientation) {
        return orientation == Orientation.landscape
            ? _buildWide(context, indexStack, content)
            : _buildNarrow(context, indexStack, content);
      },
    );
  }

  Widget _buildNarrow(BuildContext context, Widget indexStack, Widget content) {
    return Stack(
      children: [
        Obx(
          () => Scaffold(
            body: indexStack,
            bottomNavigationBar: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: controller.index.value,
                onTap: controller.setIndex,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedFontSize: 11,
                unselectedFontSize: 11,
                backgroundColor: Theme.of(context).cardColor,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Remix.bear_smile_line),
                    activeIcon: Icon(Remix.bear_smile_fill),
                    label: "漫画".i18n,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Remix.article_line),
                    activeIcon: Icon(Remix.article_fill),
                    label: "资讯".i18n,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Remix.book_open_line),
                    activeIcon: Icon(Remix.book_open_fill),
                    label: "轻小说".i18n,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Remix.book_marked_line),
                    activeIcon: Icon(Remix.book_marked_fill),
                    label: "书架".i18n,
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Remix.user_smile_line),
                    activeIcon: Icon(Remix.user_smile_fill),
                    label: "我的".i18n,
                  ),
                ],
              ),
            ),
          ),
        ),
        Obx(
          () => IgnorePointer(
            ignoring: !controller.showContent.value,
            child: content,
          ),
        )
      ],
    );
  }

  Widget _buildWide(BuildContext context, Widget indexStack, Widget content) {
    return Scaffold(
      body: Row(
        children: [
          Obx(
            () => Padding(
              padding: EdgeInsets.only(right: 2),
              child: NavigationRail(
                elevation: 2,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: controller.setIndex,
                selectedIndex: controller.index.value,
                leading: SizedBox(
                  height: AppStyle.statusBarHeight,
                ),
                selectedLabelTextStyle: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                unselectedLabelTextStyle: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Remix.bear_smile_line),
                    label: Text("漫画".i18n),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Remix.article_line),
                    label: Text("资讯".i18n),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Remix.book_open_line),
                    label: Text("轻小说".i18n),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Remix.book_marked_line),
                    label: Text("书架".i18n),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Remix.user_smile_line),
                    label: Text("我的".i18n),
                  ),
                ],
              ),
            ),
          ),
          Container(
            // constraints: const BoxConstraints(maxWidth: 450),
            width: 450,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withValues(alpha: .1),
                ),
              ),
            ),
            child: indexStack,
          ),
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildIndexStack() {
    return Obx(
      () => IndexedStack(
        key: controller.indexKey,
        index: controller.index.value,
        children: controller.pages,
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
