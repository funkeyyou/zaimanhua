import 'package:flutter/material.dart';
import 'package:zai_x/app/dialog_utils.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/models/comic/search_item.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/search_history_service.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicSearchController extends BasePageController<SearchComicItem> {
  final String keyword;
  ComicSearchController(this.keyword) {
    searchController = TextEditingController(text: keyword);
    showHotWord.value = keyword.isEmpty;
  }
  late TextEditingController searchController;
  final ComicRequest request = ComicRequest();

  String _keyword = "";

  RxMap<int, String> hotWords = <int, String>{}.obs;

  var showHotWord = true.obs;

  /// 搜索历史
  final searchHistory = <String>[].obs;

  /// 依输入内容从本机资料给的建议
  final suggestions = <LocalSearchSuggestion>[].obs;

  @override
  void onInit() {
    // loadHotWord();
    loadHistory();
    if (keyword.isNotEmpty) {
      submit();
    }
    super.onInit();
  }

  void loadHistory() {
    searchHistory.assignAll(
      SearchHistoryService.get(AppConstant.kTypeComic),
    );
  }

  /// 输入变化时更新建议；清空输入就回到历史列表
  void onKeywordChanged(String text) {
    suggestions.assignAll(
      SearchHistoryService.suggest(AppConstant.kTypeComic, text),
    );
    if (text.isEmpty) {
      showHotWord.value = true;
    }
  }

  void searchKeyword(String text) {
    searchController.text = text;
    submit();
  }

  Future<void> removeHistory(String text) async {
    await SearchHistoryService.remove(AppConstant.kTypeComic, text);
    loadHistory();
  }

  Future<void> clearHistory() async {
    await SearchHistoryService.clear(AppConstant.kTypeComic);
    loadHistory();
  }

  void submit() async {
    if (searchController.text.isEmpty) {
      list.clear();
      showHotWord.value = true;
      return;
    }

    if (int.tryParse(searchController.text) != null &&
        await numberJumpComic()) {
      return;
    }

    if (searchController.text.startsWith("id:\\") && await handelJumpComic()) {
      return;
    }

    showHotWord.value = false;
    _keyword = searchController.text;
    suggestions.clear();
    await SearchHistoryService.add(AppConstant.kTypeComic, _keyword);
    loadHistory();
    refreshData();
  }

  Future<bool> handelJumpComic() async {
    var id = int.tryParse(searchController.text.replaceAll("id:\\", "")) ?? 0;
    if (id != 0) {
      AppNavigator.toComicDetail(id);
      return true;
    } else {
      return false;
    }
  }

  Future numberJumpComic() async {
    if (!await DialogUtils.showAlertDialog(
      "你输入了纯数字，是否跳转至对应的漫画?".i18n,
      title: "漫画ID跳转".i18n,
    )) {
      return false;
    }
    return await handelJumpComic();
  }

  @override
  Future<List<SearchComicItem>> getData(int page, int pageSize) async {
    if (searchController.text.isEmpty) {
      return [];
    }
    // if (AppSettingsService.instance.comicSearchUseWebApi.value) {
    //   //WEB接口不能分页
    //   if (page > 1) {
    //     return [];
    //   }
    //   return await request.searchWeb(keyword: _keyword);
    // } else {
    return await request.search(keyword: _keyword, page: page);
    //}
  }

  void loadHotWord() async {
    try {
      hotWords.value = await request.searchHotWord();
    } catch (e) {
      Log.logPrint(e);
    }
  }
}
