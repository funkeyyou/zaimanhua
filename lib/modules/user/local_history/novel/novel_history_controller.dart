import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/db/novel_history.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/services/db_service.dart';

class LocalNovelHistoryController extends BasePageController<NovelHistory> {
  final UserRequest request = UserRequest();

  @override
  Future<List<NovelHistory>> getData(int page, int pageSize) async {
    if (page > 1) {
      return [];
    }

    return DBService.instance.getNovelHistoryList();
  }
}
