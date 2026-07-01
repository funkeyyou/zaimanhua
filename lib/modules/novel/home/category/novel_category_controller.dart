import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/novel/category_model.dart';
import 'package:zai_x/requests/novel_request.dart';
import 'package:zai_x/routes/app_navigator.dart';

class NovelCategoryController extends BasePageController<NovelCategoryModel> {
  final NovelRequest request = NovelRequest();

  @override
  Future<List<NovelCategoryModel>> getData(int page, int pageSize) async {
    if (page > 1) {
      return [];
    }
    var ls = await request.categores();

    return ls;
  }

  void toDetail(NovelCategoryModel item) {
    AppNavigator.toNovelCategoryDetail(item.tagId);
  }
}
