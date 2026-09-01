import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/models/comment/comment_item.dart';
import 'package:zai_x/models/novel/novel_detail_model.dart';
import 'package:zai_x/routes/news_link_resolver.dart';
import 'package:zai_x/routes/route_path.dart';
import 'package:zai_x/services/comic_download_service.dart';
import 'package:zai_x/services/novel_download_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AppNavigator {
  /// 當前內容路由的名稱
  static String currentContentRouteName = "/";

  /// 子路由ID
  static const int kSubNavigatorID = 1;

  /// 子路由Key
  static final GlobalKey<NavigatorState>? subNavigatorKey =
      Get.nestedKey(kSubNavigatorID);

  /// 子路由的Context
  static BuildContext get subNavigatorContext =>
      subNavigatorKey!.currentContext!;

  static void toPage(String name, {dynamic arg}) {
    Get.toNamed(name, arguments: arg);
  }

  /// 跳轉子路由頁面
  static void toContentPage(String name, {dynamic arg, bool replace = false}) {
    if (currentContentRouteName == name && replace) {
      Get.offAndToNamed(name, arguments: arg, id: kSubNavigatorID);
    } else {
      Get.toNamed(name, arguments: arg, id: kSubNavigatorID);
    }
  }

  /// 關閉頁面
  /// 優先關閉主路由的頁面
  static void closePage() {
    if (Navigator.canPop(Get.context!)) {
      Get.back();
    } else {
      Get.back(id: 1);
    }
  }

  /// 開啟新聞詳情
  static void toNewsDetail({
    required String url,
    String title = "資訊詳情",
    int newsId = 0,
  }) {
    final resolvedUrl = NewsLinkResolver.resolve(url: url, newsId: newsId);
    if (resolvedUrl == null) {
      SmartDialog.showToast("無法開啟此連結：$url");
      return;
    }
    //https://news.dmzj.com/article/77288.html
    if (resolvedUrl.contains("article/")) {
      toContentPage(RoutePath.kNewsDetail, arg: {
        "title": title,
        "newsUrl": resolvedUrl,
        "newsId": newsId,
      });
    } else {
      toWebView(resolvedUrl);
    }
  }

  /// 開啟漫畫詳情
  static void toComicDetail(int id) {
    toContentPage(RoutePath.kComicDetail, arg: id);
  }

  /// 開啟小說詳情
  static void toNovelDetail(int id) {
    Log.w("開啟小說:$id");
    toContentPage(RoutePath.kNovelDetail, arg: id);
  }

  /// 開啟評論
  static void toComment({
    required int objId,
    required int type,
  }) {
    toContentPage(RoutePath.kComment, arg: {
      "objId": objId,
      "type": type,
    });
  }

  /// 開啟WebView
  static void toWebView(String url) {
    url = url.trimRight().trimLeft();
    if (Platform.isAndroid || Platform.isIOS) {
      toContentPage(RoutePath.kWebView, arg: url);
    } else {
      launchUrlString(url);
    }
  }

  /// 開啟漫畫分類詳情
  static void toComicCategoryDetail(int id) {
    toContentPage(RoutePath.kComicCategoryDetail, arg: id);
  }

  /// 開啟漫畫作者詳情
  static void toComicAuthorDetail(int id) {
    toContentPage(RoutePath.kComicAuthorDetail, arg: id);
  }

  /// 開啟專題詳情
  static void toSpecialDetail(int id) {
    toContentPage(RoutePath.kSpecialDetail, arg: id);
  }

  /// 開啟漫畫搜尋
  static void toComicSearch({String keyword = ""}) {
    toContentPage(RoutePath.kComicSearch, arg: keyword);
  }

  /// 開啟輕小說搜尋
  static void toNovelSearch({String keyword = ""}) {
    toContentPage(RoutePath.kNovelSearch, arg: keyword);
  }

  /// 開啟漫畫分類詳情
  static void toNovelCategoryDetail(int id) {
    toContentPage(RoutePath.kNovelCategoryDetail, arg: id);
  }

  /// 開啟使用者訂閱
  /// - [type] 0=漫畫,1=小說,2=新聞
  static void toUserSubscribe({int type = 0}) {
    toContentPage(RoutePath.kUserSubscribe, arg: type);
  }

  /// 開啟使用者歷史記錄
  /// - [type] 0=漫畫,1=小說
  static void toUserHistory({int type = 0}) {
    toContentPage(RoutePath.kUserHistory, arg: type);
  }

  /// 開啟本地歷史記錄
  /// - [type] 0=漫畫,1=小說
  static void toLocalHistory({int type = 0}) {
    toContentPage(RoutePath.kLocalHistory, arg: type);
  }

  /// 開啟本地歷史記錄
  /// - [type] 0=漫畫,1=小說,2=下載
  static void toSettings({int type = 0}) {
    toContentPage(RoutePath.kSettings, arg: type);
  }

  /// 開啟漫畫閱讀
  static Future toComicReader({
    required int comicId,
    required String comicTitle,
    required String comicCover,
    required List<ComicDetailChapterItem> chapters,
    required ComicDetailChapterItem chapter,
    required bool isLongComic,
  }) async {
    // 使用主路由跳轉
    await Get.toNamed(RoutePath.kComicReader, arguments: {
      "comicId": comicId,
      "comicTitle": comicTitle,
      "comicCover": comicCover,
      "chapters": chapters,
      "chapter": chapter,
      "isLongComic": isLongComic,
    });
  }

  /// 開啟漫畫閱讀
  static Future toNovelReader({
    required int novelId,
    required String novelTitle,
    required String novelCover,
    required List<NovelDetailChapter> chapters,
    required NovelDetailChapter chapter,
  }) async {
    // 使用主路由跳轉
    await Get.toNamed(RoutePath.kNovelReader, arguments: {
      "novelId": novelId,
      "novelTitle": novelTitle,
      "novelCover": novelCover,
      "chapters": chapters,
      "chapter": chapter,
    });
  }

  /// 開啟漫畫下載-選擇章節
  static void toComicDownloadSelect(int id) {
    toContentPage(RoutePath.kComicDownloadSelect, arg: id);
  }

  /// 開啟小說下載-選擇章節
  static void toNovelDownloadSelect(int id) {
    toContentPage(RoutePath.kNovelDownloadSelect, arg: id);
  }

  /// 開啟漫畫下載管理
  /// * [type] 0=下載完成，1=下載中
  static void toComicDownloadManage(int type) {
    toContentPage(RoutePath.kComicDownload, arg: type);
  }

  /// 開啟已下載的漫畫
  /// * [info] 已下載的漫畫資訊
  static void toComicDownloadDetail(ComicDownloadedItem info) {
    toContentPage(RoutePath.kComicDownloadDetail, arg: info);
  }

  /// 開啟小說下載管理
  /// * [type] 0=下載完成，1=下載中
  static void toNovelDownloadManage(int type) {
    toContentPage(RoutePath.kNovelDownload, arg: type);
  }

  /// 開啟已下載的小說
  /// * [info] 已下載的漫畫資訊
  static void toNovelDownloadDetail(NovelDownloadedItem info) {
    toContentPage(RoutePath.kNovelDownloadDetail, arg: info);
  }

  /// 開啟新增/回覆評論
  static void toAddComment({
    required int objId,
    required int type,
    CommentItem? replyItem,
  }) {
    toContentPage(RoutePath.kCommentAdd, arg: {
      "objId": objId,
      "type": type,
      "replyItem": replyItem,
    });
  }

  /// 開啟使用者的評論
  /// * [userId] 使用者ID
  static void toUserComment(int userId) {
    toContentPage(RoutePath.kUserComment, arg: userId);
  }

  /// 開啟使用者中心
  /// * [userId] 使用者ID
  static void toUserCenter(int userId) {
    toContentPage(RoutePath.kUserCenter, arg: userId);
  }

  /// 開啟本機收藏
  static void tolocalFavorite() {
    toContentPage(RoutePath.kLocalFavorite);
  }

  static void showBottomSheet(
    Widget widget, {
    bool isScrollControlled = false,
  }) {
    showModalBottomSheet(
      context: subNavigatorContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      isScrollControlled: isScrollControlled,
      backgroundColor: Get.theme.cardColor,
      builder: (context) => widget,
      routeSettings: const RouteSettings(name: "/modalBottomSheet"),
    );
  }
}
