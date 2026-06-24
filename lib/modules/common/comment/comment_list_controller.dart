import 'dart:async';

import 'package:flutter_dmzj/app/controller/base_controller.dart';
import 'package:flutter_dmzj/app/event_bus.dart';
import 'package:flutter_dmzj/models/comment/comment_item.dart';
import 'package:flutter_dmzj/requests/comment_request.dart';

class CommentListController extends BasePageController<CommentItem> {
  final int type;
  final int objId;
  final bool isHot;
  final CommentRequest request = CommentRequest();
  StreamSubscription? _refreshSubscription;

  CommentListController({
    required this.type,
    required this.objId,
    required this.isHot,
  });

  @override
  void onInit() {
    super.onInit();
    _refreshSubscription = EventBus.instance.listen(
      EventBus.kRefreshComment,
      (id) {
        if (id == objId) {
          refreshData();
        }
      },
    );
  }

  @override
  void onClose() {
    _refreshSubscription?.cancel();
    super.onClose();
  }

  @override
  Future<List<CommentItem>> getData(int page, int pageSize) async {
    if (isHot) {
      return await request.getComment(
        type: type,
        objId: objId,
        page: page,
        sortBy: 2,
      );
    } else {
      return await request.getComment(
        type: type,
        objId: objId,
        page: page,
      );
    }
  }
}
