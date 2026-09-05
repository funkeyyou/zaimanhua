import 'package:flutter/material.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/models/novel/search_model.dart';
import 'package:zai_x/requests/novel_request.dart';
import 'package:zai_x/services/search_history_service.dart';
import 'package:get/get.dart';

class NovelSearchController extends BasePageController<NovelSearchModel> {
  final String keyword;
  NovelSearchController(this.keyword) {
    searchController = TextEditingController(text: keyword);
  }
  late TextEditingController searchController;
  final NovelRequest request = NovelRequest();

  String _keyword = "";
  RxMap<int, String> hotWords = <int, String>{}.obs;
  var showHotWord = true.obs;

  /// 搜索历史
  final searchHistory = <String>[].obs;

  /// 依输入内容从本机资料给的建议
  final suggestions = <LocalSearchSuggestion>[].obs;

  @override
  void onInit() {
    //  loadHotWord();
    loadHistory();
    if (keyword.isNotEmpty) {
      submit();
    }
    super.onInit();
  }

  void loadHistory() {
    searchHistory.assignAll(
      SearchHistoryService.get(AppConstant.kTypeNovel),
    );
  }

  /// 输入变化时更新建议；清空输入就回到历史列表
  void onKeywordChanged(String text) {
    suggestions.assignAll(
      SearchHistoryService.suggest(AppConstant.kTypeNovel, text),
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
    await SearchHistoryService.remove(AppConstant.kTypeNovel, text);
    loadHistory();
  }

  Future<void> clearHistory() async {
    await SearchHistoryService.clear(AppConstant.kTypeNovel);
    loadHistory();
  }

  void submit() async {
    if (searchController.text.isEmpty) {
      list.clear();
      showHotWord.value = true;
      return;
    }
    showHotWord.value = false;
    _keyword = searchController.text;
    suggestions.clear();
    await SearchHistoryService.add(AppConstant.kTypeNovel, _keyword);
    loadHistory();
    refreshData();
  }

  @override
  Future<List<NovelSearchModel>> getData(int page, int pageSize) async {
    if (searchController.text.isEmpty) {
      return [];
    }
    return await request.search(keyword: _keyword, page: page);
  }

  void loadHotWord() async {
    try {
      hotWords.value = await request.searchHotWord();
    } catch (e) {
      Log.logPrint(e);
    }
  }
}
