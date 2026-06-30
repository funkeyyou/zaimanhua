import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/user/subscribe_news_model.dart';
import 'package:zai_x/requests/user_request.dart';

class NewsSubscribeController
    extends BasePageController<UserSubscribeNewsModel> {
  final UserRequest request = UserRequest();

  @override
  Future<List<UserSubscribeNewsModel>> getData(int page, int pageSize) async {
    return await request.newsSubscribes(
      page: page,
    );
  }
}
