import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/comic/category_item_model.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:zai_x/routes/app_navigator.dart';

class ComicCategoryController
    extends BasePageController<ComicCategoryItemModel> {
  final ComicRequest request = ComicRequest();

  @override
  Future<List<ComicCategoryItemModel>> getData(int page, int pageSize) async {
    if (page > 1) {
      return [];
    }
    var ls = await request.categores();

    return ls;
  }

  void toDetail(ComicCategoryItemModel item) {
    AppNavigator.toComicCategoryDetail(item.tagId, tagName: item.title);
  }
}
