/// 任务中心的一条任务
///
/// 官方 H5（i.zaimanhua.com）用的是 GET /lpi/v1/task/list 与
/// GET /lpi/v1/task/get_reward，两边字段命名不完全一致，
/// 这里尽量宽松地解析，缺字段也不会炸掉整个列表。
class UserTaskModel {
  UserTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardText,
    required this.progress,
    required this.target,
    required this.finished,
    required this.received,
    required this.raw,
  });

  factory UserTaskModel.fromJson(Map json) {
    var id = _int(json, const ['task_id', 'taskId', 'id']);
    var progress = _int(json, const [
      'complete_num',
      'completeNum',
      'finish_num',
      'finishNum',
      'progress',
      'schedule',
    ]);
    var target = _int(json, const [
      'total_num',
      'totalNum',
      'need_num',
      'needNum',
      'target',
      'total',
    ]);
    var status = _int(json, const [
      'status',
      'task_status',
      'taskStatus',
      'state',
    ]);
    var receiveFlag = _int(json, const [
      'is_receive',
      'isReceive',
      'receive_status',
      'receiveStatus',
      'is_get',
      'isGet',
      'is_award',
    ]);

    // 常见约定：status 0=未完成 1=可领取 2=已领取
    var received = receiveFlag == 1 || status == 2;
    var finished = status >= 1 || (target > 0 && progress >= target);

    return UserTaskModel(
      id: id,
      title: _string(json, const ['title', 'name', 'task_name', 'taskName']),
      description: _string(json, const ['desc', 'description', 'sub_title', 'subTitle']),
      rewardText: _string(json, const ['reward', 'award', 'reward_desc', 'currency_name', 'gold']),
      progress: progress,
      target: target,
      finished: finished,
      received: received,
      raw: json,
    );
  }

  final int id;
  final String title;
  final String description;
  final String rewardText;
  final int progress;
  final int target;

  /// 条件已达成
  final bool finished;

  /// 奖励已领过
  final bool received;

  /// 原始资料，界面上可以摊开来看，方便对接口做后续调整
  final Map raw;

  /// 现在可以领奖
  bool get claimable => id != 0 && finished && !received;

  static int _int(Map json, List<String> keys) {
    for (var key in keys) {
      var value = json[key];
      if (value == null) continue;
      if (value is bool) return value ? 1 : 0;
      if (value is int) return value;
      var parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static String _string(Map json, List<String> keys) {
    for (var key in keys) {
      var value = json[key];
      if (value == null) continue;
      var text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return '';
  }
}

/// 从 task/list 的回应里把任务捞出来
///
/// 回应外层可能是 {data: {list: []}}、{data: []} 或直接分组，
/// 所以这里递归找出所有看起来像任务的物件。
List<UserTaskModel> parseUserTasks(dynamic data) {
  var result = <UserTaskModel>[];
  var seen = <int>{};

  void walk(dynamic node, int depth) {
    if (depth > 6) return;
    if (node is List) {
      for (var item in node) {
        walk(item, depth + 1);
      }
      return;
    }
    if (node is! Map) return;

    var looksLikeTask = node.keys.any(
          (k) => const ['title', 'name', 'task_name', 'taskName'].contains(k),
        ) &&
        node.keys.any(
          (k) => const ['task_id', 'taskId', 'id'].contains(k),
        );
    if (looksLikeTask) {
      var task = UserTaskModel.fromJson(node);
      if (task.id != 0 && task.title.isNotEmpty && seen.add(task.id)) {
        result.add(task);
        return;
      }
    }
    for (var value in node.values) {
      walk(value, depth + 1);
    }
  }

  walk(data, 0);
  return result;
}
