import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/comic/update_item_model.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:get/get.dart';

class ComicLatestController extends BasePageController<ComicUpdateItemModel> {
  final ComicRequest request = ComicRequest();
  Map types = {
    "全部漫畫": 100,
    "原創漫畫": 1,
    "譯製漫畫": 0,
  };
  var type = 100.obs;

  @override
  Future<List<ComicUpdateItemModel>> getData(int page, int pageSize) async {
    var ls = await request.latest(type: type.value, page: page);

    return ls;
  }
}
