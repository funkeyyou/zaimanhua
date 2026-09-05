/// 任务中心的一条任务
///
/// 结构取自实机抓下来的 GET /lpi/v1/task/list：
/// data.task 下分 dayTask（每日）、newUserTask（新人）、sumSignTask.list（累计签到），
/// 每条带 id / title / desc / status / target_count / progress_count / currency。
/// status：1=未完成，2=可领取，3=已领取。
class UserTaskModel {
  UserTaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.progress,
    required this.target,
    required this.credits,
    required this.raw,
  });

  factory UserTaskModel.fromJson(Map json) {
    var currency = json['currency'];
    return UserTaskModel(
      id: _int(json, const ['id', 'task_id', 'taskId']),
      title: _string(json, const ['title', 'name']),
      description: _string(json, const ['desc', 'description']),
      status: _int(json, const ['status']),
      progress: _int(json, const ['progress_count', 'progress']),
      target: _int(json, const ['target_count', 'target']),
      credits: currency is Map ? _int(currency, const ['credits']) : 0,
      raw: json,
    );
  }

  final int id;
  final String title;
  final String description;

  /// 1=未完成，2=可领取，3=已领取
  final int status;
  final int progress;
  final int target;

  /// 奖励积分
  final int credits;

  /// 原始资料，界面长按可以摊开来看
  final Map raw;

  static const int kStatusRunning = 1;
  static const int kStatusClaimable = 2;
  static const int kStatusReceived = 3;

  bool get received => status >= kStatusReceived;

  /// 现在可以领奖；status 缺失时退回用进度判断
  bool get claimable {
    if (id == 0 || received) {
      return false;
    }
    if (status == kStatusClaimable) {
      return true;
    }
    return status == 0 && target > 0 && progress >= target;
  }
}

/// 任务分组，对应官方页面的「每日任务」「新人任务」
class UserTaskGroup {
  UserTaskGroup({required this.title, required this.tasks});

  final String title;
  final List<UserTaskModel> tasks;
}

/// 解析 task/list
///
/// 优先照实际结构取三个分组；结构若有变动，退回全域搜寻带 status 的任务物件
/// （签到日历 signInfo.list 没有 status，会被这层过滤掉）。
List<UserTaskGroup> parseUserTaskGroups(dynamic response) {
  var groups = <UserTaskGroup>[];

  List<UserTaskModel> build(dynamic list) {
    if (list is! List) {
      return [];
    }
    return list
        .whereType<Map>()
        .map(UserTaskModel.fromJson)
        .where((e) => e.id != 0 && e.title.isNotEmpty)
        .toList();
  }

  void add(String title, dynamic list) {
    var tasks = build(list);
    if (tasks.isNotEmpty) {
      groups.add(UserTaskGroup(title: title, tasks: tasks));
    }
  }

  var data = response is Map ? response['data'] : null;
  var task = data is Map ? data['task'] : null;
  if (task is Map) {
    add('每日任务', task['dayTask']);
    add('新人任务', task['newUserTask']);
  }
  if (groups.isNotEmpty) {
    return groups;
  }

  var fallback = <UserTaskModel>[];
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
    if (node.containsKey('status') &&
        (node.containsKey('title') || node.containsKey('name'))) {
      var item = UserTaskModel.fromJson(node);
      if (item.id != 0 && item.title.isNotEmpty && seen.add(item.id)) {
        fallback.add(item);
        return;
      }
    }
    for (var value in node.values) {
      walk(value, depth + 1);
    }
  }

  walk(response, 0);
  if (fallback.isNotEmpty) {
    groups.add(UserTaskGroup(title: '任务', tasks: fallback));
  }
  return groups;
}

/// 展平所有分组
List<UserTaskModel> parseUserTasks(dynamic response) =>
    parseUserTaskGroups(response).expand((e) => e.tasks).toList();

/// 目前拥有的积分，取不到就是 null
int? parseUserCredits(dynamic response) {
  var data = response is Map ? response['data'] : null;
  var currency = data is Map ? data['userCurrency'] : null;
  if (currency is Map) {
    var value = currency['credits'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }
  return null;
}

/// 累计签到概况
///
/// 官方页面把它画成里程碑进度条，不是可领取的任务列；
/// 而且它的 id 是另一套编号，不能拿去 task/get_reward。
class SignSummary {
  SignSummary({required this.continuousDays, required this.totalDays});

  final int continuousDays;
  final int totalDays;

  bool get isEmpty => continuousDays == 0 && totalDays == 0;
}

SignSummary parseSignSummary(dynamic response) {
  var data = response is Map ? response['data'] : null;
  var task = data is Map ? data['task'] : null;
  var sumSign = task is Map ? task['sumSignTask'] : null;
  if (sumSign is Map) {
    return SignSummary(
      continuousDays: _int(sumSign, const ['continuousSignDays']),
      totalDays: _int(sumSign, const ['sumSignDays']),
    );
  }
  return SignSummary(continuousDays: 0, totalDays: 0);
}

int _int(Map json, List<String> keys) {
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

String _string(Map json, List<String> keys) {
  for (var key in keys) {
    var value = json[key];
    if (value == null) continue;
    var text = value.toString().trim();
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}
