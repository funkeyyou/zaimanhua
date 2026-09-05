import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zai_x/app/controller/base_controller.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/app/log.dart';
import 'package:zai_x/models/user/task_model.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/services/user_service.dart';

class TaskCenterController extends BaseController {
  final UserRequest request = UserRequest();

  final groups = <UserTaskGroup>[].obs;

  /// 目前的积分
  final credits = RxnInt();

  /// 累计签到概况
  final signSummary = Rx<SignSummary>(SignSummary(continuousDays: 0, totalDays: 0));

  List<UserTaskModel> get tasks =>
      groups.expand((e) => e.tasks).toList(growable: false);

  /// task/list 的原始回应，用来核对字段命名
  dynamic rawResponse;

  @override
  void onInit() {
    loadTasks();
    super.onInit();
  }

  Future<void> loadTasks() async {
    if (!UserService.instance.logined.value) {
      pageError.value = true;
      errorMsg.value = "请先登录".i18n;
      pageLoadding.value = false;
      return;
    }
    try {
      pageLoadding.value = true;
      pageError.value = false;
      rawResponse = await request.taskListRaw();
      groups.assignAll(parseUserTaskGroups(rawResponse));
      credits.value = parseUserCredits(rawResponse);
      signSummary.value = parseSignSummary(rawResponse);
    } catch (e) {
      Log.logPrint(e);
      pageError.value = true;
      errorMsg.value = e.toString();
    } finally {
      pageLoadding.value = false;
    }
  }

  Future<void> claim(UserTaskModel task) async {
    try {
      SmartDialog.showLoading();
      var message = await request.taskGetReward(task.id);
      SmartDialog.showToast(message.isEmpty ? "领取成功".i18n : message.i18n);
    } catch (e) {
      SmartDialog.showToast(e.toString().i18n);
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
    await loadTasks();
  }

  /// 把目前可领的一次领完
  Future<void> claimAll() async {
    var claimable = tasks.where((e) => e.claimable).toList();
    if (claimable.isEmpty) {
      SmartDialog.showToast("现在没有可领取的奖励".i18n);
      return;
    }
    try {
      SmartDialog.showLoading();
      var done = 0;
      for (var task in claimable) {
        try {
          await request.taskGetReward(task.id);
          done++;
        } catch (e) {
          Log.logPrint(e);
        }
      }
      SmartDialog.showToast(
        done == 0 ? "领取失败".i18n : "已领取完成的任务奖励".i18n,
      );
    } finally {
      SmartDialog.dismiss(status: SmartStatus.loading);
    }
    await loadTasks();
  }

  /// 把整份原始资料复制起来，并另存成档案，方便核对接口字段
  Future<void> copyRaw() async {
    if (rawResponse == null) {
      SmartDialog.showToast("还没有取得资料".i18n);
      return;
    }
    var text = const JsonEncoder.withIndent('  ').convert(rawResponse);
    Utils.copyText(text);
    try {
      var dir = await getExternalStorageDirectory() ??
          await getApplicationSupportDirectory();
      var file = File(p.join(dir.path, 'task_list_raw.json'));
      await file.writeAsString(text);
      SmartDialog.showToast(file.path);
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 长按任务看原始资料：接口字段有变动时可以直接对照
  void showRaw(UserTaskModel task) {
    Get.dialog(
      SimpleDialog(
        title: Text(task.title.i18n),
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          SelectableText(
            const JsonEncoder.withIndent('  ').convert(task.raw),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
