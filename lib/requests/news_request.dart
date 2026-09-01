import 'dart:convert';

import 'package:zai_x/models/news/news_banner_model.dart';
import 'package:zai_x/models/news/news_list_item_model.dart';
import 'package:zai_x/models/news/news_stat_model.dart';
import 'package:zai_x/models/news/news_tag_model.dart';
import 'package:zai_x/requests/common/api.dart';
import 'package:zai_x/requests/common/http_client.dart';
import 'package:zai_x/services/user_service.dart';

class NewsRequest {
  /// 新聞分類
  Future<List<NewsTagModel>> category() async {
    var list = <NewsTagModel>[];
    var result = await HttpClient.instance.getJson(
      '/news/category',
    );
    for (var item in result["data"]["cateList"]) {
      list.add(NewsTagModel.fromJson(item));
    }
    return list;
  }

  /// 新聞Banner
  Future<List<NewsBannerModel>> banner() async {
    var list = <NewsBannerModel>[];
    var result = await HttpClient.instance.getJson('/news/recommend');
    for (var item in result["data"]["recommendList"]) {
      list.add(NewsBannerModel.fromJson(item));
    }
    return list;
  }

  /// 讀取新聞列表
  /// - [id] 新聞分類ID
  /// - [page] 頁數，從1開始
  Future<List<NewsListItemModel>> getNewsList(int id, int page) async {
    var result = await HttpClient.instance.getJson(
      '/news/list/$id/${id == 0 ? 2 : 3}/$page',
    );

    HttpClient.checkErrno(result);
    var list = <NewsListItemModel>[];
    for (var item in result["data"]["newsList"]) {
      list.add(NewsListItemModel.fromJson(item));
    }
    return list;
  }

  /// 新聞資料
  /// - [newsId] 新聞ID
  Future<NewsStatModel> stat(int newsId) async {
    var result = await HttpClient.instance.getJson(
      '/v3/article/total/$newsId.json',
      checkCode: true,
    );

    return NewsStatModel.fromJson(result);
  }

  /// 新聞點贊
  /// - [newsId] 新聞ID
  Future<bool> like(int newsId) async {
    await HttpClient.instance.getJson(
      '/article/mood/$newsId',
      checkCode: true,
    );

    return true;
  }

  /// 新聞檢查收藏
  /// - [newsId] 新聞ID
  Future<bool> checkCollect(int newsId) async {
    var uid = UserService.instance.userId;
    var par = {"uid": int.parse(uid), "sub_id": newsId};
    var parJson = jsonEncode(par);
    var sign = Api.sign(parJson, 'app_news_sub');

    var result = await HttpClient.instance.postJson(
      '/api/news/subscribe/check',
      baseUrl: Api.BASE_URL_INTERFACE,
      data: {
        "parm": parJson,
        "sign": sign,
      },
    );

    return json.decode(result)["result"] == 809;
  }

  /// 新聞收藏
  /// - [newsId] 新聞ID
  Future<bool> collect(int newsId) async {
    var uid = UserService.instance.userId;
    var par = {"uid": int.parse(uid), "sub_id": newsId};
    var parJson = jsonEncode(par);
    var sign = Api.sign(parJson, 'app_news_sub');

    var result = await HttpClient.instance.postJson(
      '/api/news/subscribe/add',
      baseUrl: Api.BASE_URL_INTERFACE,
      data: {
        "parm": parJson,
        "sign": sign,
      },
    );

    return json.decode(result)["result"] == 1000;
  }

  /// 移除收藏
  /// - [newsId] 新聞ID
  Future<bool> delCollect(int newsId) async {
    var uid = UserService.instance.userId;
    var par = {"uid": int.parse(uid), "sub_id": newsId};
    var parJson = jsonEncode(par);
    var sign = Api.sign(parJson, 'app_news_sub');

    var result = await HttpClient.instance.postJson(
      '/api/news/subscribe/del',
      baseUrl: Api.BASE_URL_INTERFACE,
      data: {
        "parm": parJson,
        "sign": sign,
      },
    );

    return json.decode(result)["result"] == 1000;
  }
}
