import 'package:flutter/widgets.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/event_bus.dart';
import 'package:zai_x/models/comment/comment_item.dart';
import 'package:zai_x/requests/comment_request.dart';
import 'package:zai_x/routes/app_navigator.dart';
import 'package:zai_x/services/user_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:zai_x/app/i18n.dart';

class AddCommentController extends BaseController {
  final int type;
  final int objId;
  final CommentItem? replyItem;
  AddCommentController({
    required this.objId,
    required this.type,
    this.replyItem,
  });
  final CommentRequest request = CommentRequest();
  final TextEditingController textEditingController = TextEditingController();

  void submit() async {
    if (textEditingController.text.isEmpty) {
      SmartDialog.showToast("内容不能为空".i18n);
      return;
    }
    try {
      SmartDialog.showLoading();
      if (replyItem == null) {
        await request.sendComment(
          objId: objId,
          type: type,
          content: textEditingController.text,
        );
      } else {
        await request.sendComment(
          objId: objId,
          type: type,
          content: textEditingController.text,
          toCommentId: replyItem!.id.toInt(),
          originCommentId: replyItem!.originId.toInt(),
          toUid: replyItem!.userId.toInt(),
        );
      }

      SmartDialog.showToast("发表成功".i18n);
      // 「每日一歌」「举手发言」这类评论任务这时候就完成了
      UserService.instance.claimTasksSoon();
      EventBus.instance.emit(EventBus.kRefreshComment, objId);
      AppNavigator.closePage();
    } catch (e) {
      SmartDialog.showToast(e.toString());
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
  }
}
