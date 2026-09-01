import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/i18n.dart';

class ComicSubscribeController
    extends BasePageController<UserSubscribeComicItemModel> {
  ComicSubscribeController() {
    for (var item in List.generate(
        26, (index) => String.fromCharCode(index + 65).toLowerCase())) {
      letters.addAll({item: "${item.toUpperCase()}开头".i18n});
    }
  }
  final UserRequest request = UserRequest();

  var letter = "".obs;

  Map letters = {
    "": "全部".i18n,
    "number": "数字开头".i18n,
  };

  Map<int, String> types = {
    1: "全部订阅".i18n,
    2: "连载中",
    3: "已完结".i18n,
  };
  var type = 1.obs;

  var editMode = false.obs;

  @override
  Future<List<UserSubscribeComicItemModel>> getData(
      int page, int pageSize) async {
    var ls = await request.comicSubscribes(
      subType: type.value,
      letter: letter.value,
      page: page,
    );
    UserService.instance.subscribedComicIds.addAll(ls.map((e) => e.id));
    return ls;
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
