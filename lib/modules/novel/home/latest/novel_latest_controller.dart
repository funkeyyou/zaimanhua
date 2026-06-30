import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/novel/latest_model.dart';
import 'package:zai_x/requests/novel_request.dart';

class NovelLatestController extends BasePageController<NovelLatestModel> {
  final NovelRequest request = NovelRequest();

  @override
  Future<List<NovelLatestModel>> getData(int page, int pageSize) async {
    var ls = await request.latest(page: page);

    return ls;
  }
}
