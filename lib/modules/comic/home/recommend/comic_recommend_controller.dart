import 'dart:async';

import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/comic/recommend_model.dart';
import 'package:zai_x/modules/comic/home/comic_home_controller.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ComicRecommendController extends BasePageController<ComicRecommendModel> {
  final ComicRequest request = ComicRequest();
  StreamSubscription<dynamic>? subLogin;
  StreamSubscription<dynamic>? subLogout;

  @override
  void onInit() {
    subLogin = UserService.loginedStream.listen((event) {
      loadSubscribe();
    });
    subLogout = UserService.logoutStream.listen((event) {
      list.removeWhere((x) => x.categoryId == 49);
    });
    super.onInit();
  }

  @override
  Future<List<ComicRecommendModel>> getData(int page, int pageSize) async {
    var ls = await request.recommend();

    if (UserService.instance.logined.value) {
      loadSubscribe();
    }
    return ls;
  }


  /// 重新整理國漫
  Future<void> refreshGuoman() async {
    try {
      var index = list.indexWhere((x) => x.categoryId == 52);
      var result =
          await request.refreshRecommend(111, size: 6, page: list[index].page);

      if (index != -1) {
        list[index].data = result;
        list[index].page++;
        list.refresh();
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 重新整理近期必看
  Future<void> refreshRecommend() async {
    try {
      var index = list.indexWhere((x) => x.categoryId == 47);

      var result = await request.refreshRecommend(110, page: list[index].page);

      if (index != -1) {
        list[index].data = result;
        list[index].page++;
        list.refresh();
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 載入訂閱
  void loadSubscribe() async {
    try {
      var result = await request.recommendSubscribe();
      var index = list.indexWhere((x) => x.categoryId == 49);
      if (index != -1) {
        list[index] = result;
      } else {
        list.insert(1, result);
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 重新整理熱門連載
  Future<void> refreshHot() async {
    try {
      var index = list.indexWhere((x) => x.categoryId == 54);
      var result =
          await request.refreshRecommend(112, page: list[index].page, size: 6);

      if (index != -1) {
        list[index].data = result;
        list[index].page++;
        list.refresh();
      }
    } catch (e) {
      Log.logPrint(e);
    }
  }

  void openDetail(ComicRecommendItemModel item) {
    //漫畫=1
    if (item.type == null || item.type == 1) {
      AppNavigator.toComicDetail(
        item.objId ?? item.id ?? 0,
      );
    } else if (item.type == 5) {
      //專題=5
      AppNavigator.toSpecialDetail(
        item.objId ?? 0,
      );
    } else if (item.type == 6) {
      //網頁=6
      AppNavigator.toWebView(item.url ?? "");
    } else if (item.type == 7) {
      //新聞=7
      AppNavigator.toNewsDetail(
        url: item.url ?? "",
        newsId: item.objId ?? 0,
        title: item.title,
      );
    } else if (item.type == 8) {
      //作者=8
      AppNavigator.toComicAuthorDetail(item.objId ?? 0);
    } else if (item.type == 13) {
      //社群=13
      //直接跳轉至網頁
      launchUrlString(
        "http://m.forum.idmzj.com/thread/detail?tid=${item.objId}",
        mode: LaunchMode.externalApplication,
      );
      // AppNavigator.toWebView(
      //   "http://m.forum.dmzj.com/thread/detail?tid=${item.objId}",
      // );
    } else {
      SmartDialog.showToast("未知型別，無法跳轉");
    }
  }

  void toSpecial() {
    var homeController = Get.find<ComicHomeController>();
    homeController.tabController.animateTo(3);
  }

  void toMySubscribe() {
    AppNavigator.toUserSubscribe();
  }

  @override
  void onClose() {
    subLogin?.cancel();
    subLogout?.cancel();
    super.onClose();
  }
}
