import 'dart:async';

import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/subscribe_tag_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicSubscribeController
    extends BasePageController<UserSubscribeComicItemModel> {
  final UserRequest request = UserRequest();

  Map<int, String> types = {
    1: "全部订阅".i18n,
    2: "连载中",
    3: "已完结".i18n,
  };
  var type = 1.obs;

  /// 排序方式
  /// * [0] 订阅时间（接口默认顺序，新到旧）
  /// * [1] 订阅时间（旧到新）
  /// * [2] 更新时间（新到旧）
  /// * [3] 更新时间（旧到新）
  Map<int, String> sorts = {
    0: "订阅时间 ↓".i18n,
    1: "订阅时间 ↑".i18n,
    2: "更新时间 ↓".i18n,
    3: "更新时间 ↑".i18n,
  };
  late var sort = AppSettingsService.instance.subscribeSort.value.obs;

  /// 题材标签筛选（空字串=全部）
  var tag = "".obs;
  var tags = <String>[].obs;
  var tagLoading = false.obs;

  /// 完整的订阅清单（未套用标签筛选与排序）
  final _all = <UserSubscribeComicItemModel>[];

  var editMode = false.obs;

  /// 正在補齊分頁／排序：畫面先顯示讀取動畫，算完再一次呈現
  var preparing = false.obs;

  /// 標籤篩選與非預設排序都需要完整清單才能算對
  bool get _needsFullList => sort.value != 0 || tag.value.isNotEmpty;

  @override
  Future<List<UserSubscribeComicItemModel>> getData(
      int page, int pageSize) async {
    var ls = await request.comicSubscribes(
      subType: type.value,
      letter: "",
      page: page,
    );
    UserService.instance.subscribedComicIds.addAll(ls.map((e) => e.id));
    return ls;
  }

  @override
  Future loadData() async {
    var needFull = _needsFullList;
    // 補分頁的過程中清單會一直長，排完序又整個重排；
    // 先用讀取動畫蓋住，排好之後再一次顯示。
    if (needFull) {
      preparing.value = true;
    }
    try {
      await super.loadData();
      if (needFull) {
        // 只排序／篩選已載入的那一頁會誤導，先把分頁補齊（上限 500 筆）
        var guard = 0;
        while (canLoadMore.value && list.length < 500 && guard++ < 25) {
          await super.loadData();
        }
        canLoadMore.value = false;
      }
      _all
        ..clear()
        ..addAll(list);
      if (tag.value.isEmpty) {
        // 先把清單畫出來，標籤在背景補抓，抓到再更新下拉選單
        applyFilterAndSort();
        unawaited(_loadTags());
      } else {
        // 標籤篩選要等標籤補齊才算得準
        await _loadTags();
        applyFilterAndSort();
      }
    } finally {
      preparing.value = false;
    }
  }

  /// 訂閱清單沒有題材欄位，標籤要另外從漫畫詳情補抓（結果會快取）
  Future _loadTags() async {
    var ids = _all.map((e) => e.id).toList();
    tags.value = SubscribeTagService.availableTags(ids);
    if (tags.isEmpty && ids.isEmpty) {
      return;
    }
    if (tagLoading.value) {
      return;
    }
    tagLoading.value = true;
    try {
      var updated = await SubscribeTagService.fetchMissing(ids);
      if (updated) {
        tags.value = SubscribeTagService.availableTags(ids);
        applyFilterAndSort();
      }
    } finally {
      tagLoading.value = false;
    }
  }

  void applyFilterAndSort() {
    var items = tag.value.isEmpty
        ? List<UserSubscribeComicItemModel>.from(_all)
        : _all
            .where((e) => SubscribeTagService.tagsOf(e.id).contains(tag.value))
            .toList();
    switch (sort.value) {
      case 1:
        // 介面預設是新到舊，反轉即為舊到新
        items = items.reversed.toList();
        break;
      case 2:
        // 章節 ID 為全站遞增，數字越大代表更新時間越近
        items.sort(
          (a, b) => b.lastUpdateChapterId.compareTo(a.lastUpdateChapterId),
        );
        break;
      case 3:
        items.sort(
          (a, b) => a.lastUpdateChapterId.compareTo(b.lastUpdateChapterId),
        );
        break;
    }
    list.value = items;
    pageEmpty.value = items.isEmpty;
  }

  void setSort(int value) {
    if (sort.value == value) {
      return;
    }
    var wasFull = _needsFullList;
    sort.value = value;
    AppSettingsService.instance.setSubscribeSort(value);
    if (!wasFull && _needsFullList) {
      refreshData();
    } else {
      applyFilterAndSort();
    }
  }

  void setTag(String value) {
    if (tag.value == value) {
      return;
    }
    var wasFull = _needsFullList;
    tag.value = value;
    if (!wasFull && _needsFullList) {
      refreshData();
    } else if (value.isNotEmpty && tagLoading.value) {
      // 標籤還在補抓，等抓完再顯示篩選結果
      _applyAfterTags();
    } else {
      applyFilterAndSort();
    }
  }

  /// 等背景的標籤補抓結束後再套用篩選
  Future _applyAfterTags() async {
    preparing.value = true;
    try {
      while (tagLoading.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      applyFilterAndSort();
    } finally {
      preparing.value = false;
    }
  }

  /// 標籤下拉選單的內容
  Map<String, String> get tagOptions {
    var map = <String, String>{"": "全部".i18n};
    for (var t in tags) {
      map[t] = t;
    }
    return map;
  }

  void cancelEdit() {
    for (var item in list) {
      item.isChecked.value = false;
    }
    editMode.value = false;
  }

  void cancelSub() async {
    var ids = list.where((x) => x.isChecked.value).map((e) => e.id).toList();
    if (ids.isEmpty) {
      cancelEdit();
      return;
    }
    cancelEdit();
    await UserService.instance.cancelSubscribe(ids, AppConstant.kTypeComic);
    easyRefreshController.callRefresh();
  }

  void addFavorite() async {
    for (var item in list.where((x) => x.isChecked.value)) {
      DBService.instance.putComicFavorite(
        title: item.title,
        cover: item.cover,
        comicId: item.id,
      );
    }
    cancelEdit();
    SmartDialog.showToast("已添加至本机收藏".i18n);
  }
}
