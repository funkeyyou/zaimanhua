import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/user/subscribe_novel_model.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:get/get.dart';

class NovelSubscribeController
    extends BasePageController<UserSubscribeNovelModel> {
  NovelSubscribeController() {
    for (var item in List.generate(
        26, (index) => String.fromCharCode(index + 65).toLowerCase())) {
      letters.addAll({item: "${item.toUpperCase()}開頭"});
    }
  }
  final UserRequest request = UserRequest();

  var letter = "".obs;

  Map letters = {
    "": "全部",
    "number": "數字開頭",
  };

  Map<int, String> types = {
    0: "全部訂閱",
    2: "已讀",
    1: "未讀",
  };
  var type = 0.obs;

  @override
  Future<List<UserSubscribeNovelModel>> getData(int page, int pageSize) async {
    var ls = await request.novelSubscribes(
      subType: type.value,
      letter: letter.value,
      page: page - 1,
    );
    UserService.instance.subscribedNovelIds.addAll(ls.map((e) => e.id));
    return ls;
  }

  var editMode = false.obs;
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
    await UserService.instance.cancelSubscribe(ids, AppConstant.kTypeNovel);
    easyRefreshController.callRefresh();
  }
}
