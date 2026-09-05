import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/models/user/task_model.dart';
import 'package:zai_x/modules/user/task/task_center_controller.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/widgets/status/app_error_widget.dart';
import 'package:zai_x/widgets/status/app_loadding_widget.dart';

/// 任务中心：显示官方任务进度，可手动或自动领取奖励
class TaskCenterPage extends StatelessWidget {
  TaskCenterPage({super.key})
      : controller = Get.put(
          TaskCenterController(),
          tag: DateTime.now().millisecondsSinceEpoch.toString(),
        );

  final TaskCenterController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("任务中心".i18n),
        actions: [
          IconButton(
            tooltip: "复制原始资料".i18n,
            onPressed: controller.copyRaw,
            icon: const Icon(Icons.copy_all, size: 20),
          ),
          TextButton(
            onPressed: controller.claimAll,
            child: Text("全部领取".i18n),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.pageLoadding.value) {
          return const AppLoaddingWidget();
        }
        if (controller.pageError.value) {
          return AppErrorWidget(
            errorMsg: controller.errorMsg.value,
            onRefresh: controller.loadTasks,
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadTasks,
          child: ListView(
            children: [
              Obx(
                () => SwitchListTile(
                  title: Text("任务达成后自动领取".i18n),
                  subtitle: Text("启动 App 并登录后会自动领一次".i18n),
                  value: AppSettingsService.instance.autoClaimTask.value,
                  onChanged: AppSettingsService.instance.setAutoClaimTask,
                ),
              ),
              const Divider(height: 1),
              _buildSummary(),
              if (controller.groups.isEmpty)
                Padding(
                  padding: AppStyle.edgeInsetsA24,
                  child: Text(
                    "没有取得任务列表".i18n,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              else
                ...controller.groups.map(_buildGroup),
            ],
          ),
        );
      }),
    );
  }

  /// 顶部概况：积分与累计签到
  Widget _buildSummary() {
    var credits = controller.credits.value;
    var sign = controller.signSummary.value;
    if (credits == null && sign.isEmpty) {
      return const SizedBox.shrink();
    }
    var lines = <String>[];
    if (credits != null) {
      lines.add('${"当前积分".i18n}：$credits');
    }
    if (!sign.isEmpty) {
      lines.add(
        '${"连续签到".i18n} ${sign.continuousDays} ${"天".i18n}'
        '  ${"累计".i18n} ${sign.totalDays} ${"天".i18n}',
      );
    }
    return Padding(
      padding: AppStyle.edgeInsetsA12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines
            .map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  e,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGroup(UserTaskGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppStyle.edgeInsetsA12,
          child: Text(group.title.i18n, style: Get.textTheme.titleSmall),
        ),
        ...group.tasks.map(_buildItem),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildItem(UserTaskModel task) {
    return ListTile(
      title: Text(task.title.i18n),
      subtitle: Text(_subtitle(task)),
      onLongPress: () => controller.showRaw(task),
      trailing: task.received
          ? Text(
              "已领取".i18n,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            )
          : task.claimable
              ? ElevatedButton(
                  style: ElevatedButton.styleFrom(elevation: 0),
                  onPressed: () => controller.claim(task),
                  child: Text("领取".i18n),
                )
              : Text(
                  "进行中".i18n,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
    );
  }

  String _subtitle(UserTaskModel task) {
    var parts = <String>[];
    if (task.description.isNotEmpty) {
      parts.add(task.description.i18n);
    }
    if (task.credits > 0) {
      parts.add('+${task.credits} ${"积分".i18n}');
    }
    if (task.target > 0 && !task.received) {
      parts.add('${task.progress}/${task.target}');
    }
    return parts.join('  ');
  }
}
