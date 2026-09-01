import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/widgets.dart';
import 'package:zai_x/app/log.dart';

import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class BaseController extends GetxController {
  /// 載入中，更新頁面
  var pageLoadding = false.obs;

  /// 載入中,不會更新頁面
  var loadding = false;

  /// 空白頁面
  var pageEmpty = false.obs;

  /// 頁面錯誤
  var pageError = false.obs;

  /// 未登入
  var notLogin = false.obs;

  /// 錯誤資訊
  var errorMsg = "".obs;

  Error? error;

  /// 顯示錯誤
  /// * [msg] 錯誤資訊
  /// * [showPageError] 顯示頁面錯誤
  /// * 只在第一頁載入錯誤時showPageError=true，後續頁載入錯誤時使用Toast彈出通知
  void handleError(Object exception, {bool showPageError = false}) {
    Log.logPrint(exception);
    var msg = exceptionToString(exception);
    if (exception is Error) {
      error = exception;
    }
    if (showPageError) {
      pageError.value = true;
      errorMsg.value = msg;
    } else {
      SmartDialog.showToast(exceptionToString(msg));
    }
  }

  String exceptionToString(Object exception) {
    return exception.toString().replaceAll("Exception:", "");
  }

  void onLogin() {}
  void onLogout() {}
}

class BaseDataController<T> extends BaseController {
  T? data;
  Future loadData() async {
    try {
      if (loadding) return;
      loadding = true;
      pageError.value = false;
      pageLoadding.value = true;
      error = null;
      var result = await getData();
      data = result;
    } catch (e) {
      handleError(exceptionToString(e), showPageError: true);
    } finally {
      loadding = false;
      pageLoadding.value = false;
    }
  }

  Future<T?> getData() async {
    return null;
  }
}

class BasePageController<T> extends BaseController {
  final ScrollController scrollController = ScrollController();
  final EasyRefreshController easyRefreshController = EasyRefreshController();
  int currentPage = 1;
  int count = 0;
  int maxPage = 0;
  int pageSize = 24;
  var canLoadMore = false.obs;
  var list = <T>[].obs;

  Future refreshData() async {
    currentPage = 1;
    list.clear();
    await loadData();
  }

  Future loadData() async {
    try {
      if (loadding) return;
      loadding = true;
      pageError.value = false;
      pageEmpty.value = false;
      notLogin.value = false;
      error = null;
      pageLoadding.value = currentPage == 1;

      var result = await getData(currentPage, pageSize);
      //是否可以載入更多
      if (result.isNotEmpty) {
        currentPage++;
        canLoadMore.value = true;
        pageEmpty.value = false;
      } else {
        canLoadMore.value = false;
        if (currentPage == 1) {
          pageEmpty.value = true;
        }
      }
      // 賦值資料
      if (currentPage == 1) {
        list.value = result;
      } else {
        list.addAll(result);
      }
    } catch (e) {
      handleError(e, showPageError: currentPage == 1);
    } finally {
      loadding = false;
      pageLoadding.value = false;
    }
  }

  Future<List<T>> getData(int page, int pageSize) async {
    return [];
  }

  void scrollToTopOrRefresh() {
    if (scrollController.offset > 0) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    } else {
      easyRefreshController.callRefresh();
    }
  }
}
