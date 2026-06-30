import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/user/novel_history_model.dart';
import 'package:zai_x/requests/user_request.dart';

class NovelHistoryController extends BasePageController<UserNovelHistoryModel> {
  final UserRequest request = UserRequest();

  @override
  Future<List<UserNovelHistoryModel>> getData(int page, int pageSize) async {
    return await request.novelHistory(page: page);
  }
}
