import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/user/comic_history_model.dart';
import 'package:zai_x/requests/user_request.dart';

class ComicHistoryController extends BasePageController<UserComicHistoryModel> {
  final UserRequest request = UserRequest();

  @override
  Future<List<UserComicHistoryModel>> getData(int page, int pageSize) async {
    return await request.comicHistory(page: page);
  }
}
