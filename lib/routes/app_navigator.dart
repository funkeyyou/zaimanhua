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
import 'package:zai_x/app/i18n.dart';

class AppNavigator {
  /// 当前内容路由的名称
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

  /// 跳转子路由页面
  static void toContentPage(String name, {dynamic arg, bool replace = false}) {
    if (currentContentRouteName == name && replace) {
      Get.offAndToNamed(name, arguments: arg, id: kSubNavigatorID);
    } else {
      Get.toNamed(name, arguments: arg, id: kSubNavigatorID);
    }
  }

  /// 子路由栈里是否还有内容页(即 '/' 之上还有页面)
  static bool get hasContentPage =>
      subNavigatorKey?.currentState?.canPop() ?? false;

  /// 主路由(阅读器等)最近一次被关闭的时间
  static DateTime? _lastMainRoutePop;

  /// 主路由刚刚关闭(短时间内)
  ///
  /// Android 的返回事件在某些机型上会被派发两次：第一次退掉主路由的阅读器，
  /// 第二次落到首页的返回拦截里，把子路由的详情页也一起退掉。
  /// 首页拦截会用这个标记忽略紧接着的那一次。
  static bool get justClosedMainRoute {
    final last = _lastMainRoutePop;
    if (last == null) return false;
    return DateTime.now().difference(last).inMilliseconds < 500;
  }

  static void markMainRoutePopped() {
    _lastMainRoutePop = DateTime.now();
  }

  /// 阅读器关闭后，确保内容区仍停在原来的详情页(选集页面)
  ///
  /// 阅读器跑在主路由、详情页跑在子路由，两者生命周期互相独立；
  /// 某些情况下(系统返回手势一次退掉两层、子路由被重建)详情页会一起消失，
  /// 退出阅读器后就直接掉回底部分页(书架/首页)。这里做一次兜底还原。
  static void _restoreDetailPage(String routeName, int id) {
    if (currentContentRouteName != routeName || !hasContentPage) {
      toContentPage(routeName, arg: id);
    }
  }

  /// 关闭页面
  /// 优先关闭主路由的页面
  static void closePage() {
    if (Navigator.canPop(Get.context!)) {
      Get.back();
    } else {
      Get.back(id: 1);
    }
  }

  /// 打开新闻详情
  static void toNewsDetail({
    required String url,
    String title = "资讯详情",
    int newsId = 0,
  }) {
    final resolvedUrl = NewsLinkResolver.resolve(url: url, newsId: newsId);
    if (resolvedUrl == null) {
      SmartDialog.showToast("无法打开此链接：$url".i18n);
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

  /// 打开漫画详情
  static void toComicDetail(int id) {
    toContentPage(RoutePath.kComicDetail, arg: id);
  }

  /// 打开小说详情
  static void toNovelDetail(int id) {
    Log.w("打开小说:$id".i18n);
    toContentPage(RoutePath.kNovelDetail, arg: id);
  }

  /// 打开评论
  static void toComment({
    required int objId,
    required int type,
  }) {
    toContentPage(RoutePath.kComment, arg: {
      "objId": objId,
      "type": type,
    });
  }

  /// 打开WebView
  static void toWebView(String url) {
    url = url.trimRight().trimLeft();
    if (Platform.isAndroid || Platform.isIOS) {
      toContentPage(RoutePath.kWebView, arg: url);
    } else {
      launchUrlString(url);
    }
  }

  /// 打开漫画分类详情
  /// - [tagName] 标签名，服务端新加的标签本地表还没有时用来显示
  static void toComicCategoryDetail(int id, {String? tagName}) {
    toContentPage(
      RoutePath.kComicCategoryDetail,
      arg: {"id": id, "tagName": tagName},
    );
  }

  /// 打开漫画作者详情
  static void toComicAuthorDetail(int id) {
    toContentPage(RoutePath.kComicAuthorDetail, arg: id);
  }

  /// 打开专题详情
  static void toSpecialDetail(int id) {
    toContentPage(RoutePath.kSpecialDetail, arg: id);
  }

  /// 打开漫画搜索
  static void toComicSearch({String keyword = ""}) {
    toContentPage(RoutePath.kComicSearch, arg: keyword);
  }

  /// 打开轻小说搜索
  static void toNovelSearch({String keyword = ""}) {
    toContentPage(RoutePath.kNovelSearch, arg: keyword);
  }

  /// 打开漫画分类详情
  static void toNovelCategoryDetail(int id) {
    toContentPage(RoutePath.kNovelCategoryDetail, arg: id);
  }

  /// 打开用户订阅
  /// - [type] 0=漫画,1=小说,2=新闻
  static void toUserSubscribe({int type = 0}) {
    toContentPage(RoutePath.kUserSubscribe, arg: type);
  }

  /// 打开用户历史记录
  /// - [type] 0=漫画,1=小说
  static void toUserHistory({int type = 0}) {
    toContentPage(RoutePath.kUserHistory, arg: type);
  }

  /// 打开本地历史记录
  /// - [type] 0=漫画,1=小说
  static void toLocalHistory({int type = 0}) {
    toContentPage(RoutePath.kLocalHistory, arg: type);
  }

  /// 打开本地历史记录
  /// - [type] 0=漫画,1=小说,2=下载
  static void toSettings({int type = 0}) {
    toContentPage(RoutePath.kSettings, arg: type);
  }

  /// 打开漫画阅读
  static Future toComicReader({
    required int comicId,
    required String comicTitle,
    required String comicCover,
    required List<ComicDetailChapterItem> chapters,
    required ComicDetailChapterItem chapter,
    required bool isLongComic,
  }) async {
    // 使用主路由跳转
    final fromDetail = currentContentRouteName == RoutePath.kComicDetail;
    await Get.toNamed(RoutePath.kComicReader, arguments: {
      "comicId": comicId,
      "comicTitle": comicTitle,
      "comicCover": comicCover,
      "chapters": chapters,
      "chapter": chapter,
      "isLongComic": isLongComic,
    });
    markMainRoutePopped();
    if (fromDetail) {
      _restoreDetailPage(RoutePath.kComicDetail, comicId);
    }
  }

  /// 打开漫画阅读
  static Future toNovelReader({
    required int novelId,
    required String novelTitle,
    required String novelCover,
    required List<NovelDetailChapter> chapters,
    required NovelDetailChapter chapter,
  }) async {
    // 使用主路由跳转
    final fromDetail = currentContentRouteName == RoutePath.kNovelDetail;
    await Get.toNamed(RoutePath.kNovelReader, arguments: {
      "novelId": novelId,
      "novelTitle": novelTitle,
      "novelCover": novelCover,
      "chapters": chapters,
      "chapter": chapter,
    });
    markMainRoutePopped();
    if (fromDetail) {
      _restoreDetailPage(RoutePath.kNovelDetail, novelId);
    }
  }

  /// 打开漫画下载-选择章节
  static void toComicDownloadSelect(int id) {
    toContentPage(RoutePath.kComicDownloadSelect, arg: id);
  }

  /// 打开小说下载-选择章节
  static void toNovelDownloadSelect(int id) {
    toContentPage(RoutePath.kNovelDownloadSelect, arg: id);
  }

  /// 打开漫画下载管理
  /// * [type] 0=下载完成，1=下载中
  static void toComicDownloadManage(int type) {
    toContentPage(RoutePath.kComicDownload, arg: type);
  }

  /// 打开已下载的漫画
  /// * [info] 已下载的漫画信息
  static void toComicDownloadDetail(ComicDownloadedItem info) {
    toContentPage(RoutePath.kComicDownloadDetail, arg: info);
  }

  /// 打开小说下载管理
  /// * [type] 0=下载完成，1=下载中
  static void toNovelDownloadManage(int type) {
    toContentPage(RoutePath.kNovelDownload, arg: type);
  }

  /// 打开已下载的小说
  /// * [info] 已下载的漫画信息
  static void toNovelDownloadDetail(NovelDownloadedItem info) {
    toContentPage(RoutePath.kNovelDownloadDetail, arg: info);
  }

  /// 打开添加/回复评论
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

  /// 打开用户的评论
  /// * [userId] 用户ID
  static void toUserComment(int userId) {
    toContentPage(RoutePath.kUserComment, arg: userId);
  }

  /// 打开用户中心
  /// * [userId] 用户ID
  static void toUserCenter(int userId) {
    toContentPage(RoutePath.kUserCenter, arg: userId);
  }

  /// 打开本机收藏
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
