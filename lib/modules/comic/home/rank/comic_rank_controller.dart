import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/comic/rank_item_model.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicRankController extends BasePageController<ComicRankListItemModel> {
  final ComicRequest request = ComicRequest();
  RxMap<int, String> tags = {
    0: "全部分类".i18n,
  }.obs;
  var tag = 0.obs;

  Map<int, String> byTimes = {
    0: "日排行".i18n,
    1: "周排行".i18n,
    2: "月排行".i18n,
    3: "总排行".i18n,
  };
  var byTime = 0.obs;

  Map<int, String> rankTypes = {
    0: "人气排行".i18n,
    1: "吐槽排行".i18n,
    2: "订阅排行".i18n,
  };
  var rankType = 0.obs;

  @override
  void onInit() {
    loadFilter();
    super.onInit();
  }

  void loadFilter() async {
    try {
      tags.value = await request.rankFilter();
    } catch (e) {
      SmartDialog.showToast(e.toString());
    }
  }

  @override
  Future<List<ComicRankListItemModel>> getData(int page, int pageSize) async {
    var ls = await request.rank(
      tagId: tag.value,
      byTime: byTime.value,
      rankType: rankType.value,
      page: page,
    );

    return ls.where((e) => e.title.isNotEmpty).toList();
  }
}
