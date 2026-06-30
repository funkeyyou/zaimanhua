import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/models/user/user_center_model.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:get/get.dart';

class UserCenterController extends BasePageController<UserCenterCommentItem> {
  final int userId;
  final UserRequest request = UserRequest();
  final Rx<UserCenterInfo?> info = Rx<UserCenterInfo?>(null);
  final isFocus = false.obs;
  final focusLoadding = false.obs;

  UserCenterController(this.userId) {
    pageSize = 10;
  }

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_loadMoreWhenNearBottom);
    loadInfo();
  }

  void _loadMoreWhenNearBottom() {
    if (!scrollController.hasClients) return;
    if (loadding || !canLoadMore.value) return;
    if (scrollController.position.extentAfter < 300) {
      loadData();
    }
  }

  Future<void> loadInfo() async {
    try {
      final result = await request.userCenterInfo(userId: userId);
      info.value = result;
      isFocus.value = result.isFocus;
    } catch (e) {
      handleError(e);
    }
  }

  @override
  Future<List<UserCenterCommentItem>> getData(int page, int pageSize) async {
    return request.userCenterComments(
      userId: userId,
      page: page,
      pageSize: pageSize,
      source: AppConstant.kTypeComic,
    );
  }

  Future<void> toggleFocus() async {
    if (focusLoadding.value) return;
    try {
      focusLoadding.value = true;
      if (isFocus.value) {
        await request.removeFocus(userId: userId);
        isFocus.value = false;
        if (info.value != null && info.value!.fansNum > 0) {
          info.value!.fansNum--;
          info.refresh();
        }
      } else {
        await request.addFocus(userId: userId);
        isFocus.value = true;
        if (info.value != null) {
          info.value!.fansNum++;
          info.refresh();
        }
      }
    } catch (e) {
      handleError(e);
    } finally {
      focusLoadding.value = false;
    }
  }
}
