import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/models/user/task_model.dart';

/// 任务中心的字段命名没有公开文件，解析必须容得下几种常见写法
void main() {
  test('reads snake_case fields', () {
    var task = UserTaskModel.fromJson({
      'task_id': 12,
      'title': '阅读 3 话漫画',
      'desc': '每日任务',
      'complete_num': 3,
      'total_num': 3,
      'status': 1,
    });

    expect(task.id, 12);
    expect(task.title, '阅读 3 话漫画');
    expect(task.progress, 3);
    expect(task.target, 3);
    expect(task.finished, isTrue);
    expect(task.received, isFalse);
    expect(task.claimable, isTrue);
  });

  test('reads camelCase fields', () {
    var task = UserTaskModel.fromJson({
      'taskId': 5,
      'name': '签到',
      'finishNum': 1,
      'totalNum': 1,
      'isReceive': 1,
    });

    expect(task.id, 5);
    expect(task.title, '签到');
    expect(task.received, isTrue);
    expect(task.claimable, isFalse);
  });

  test('unfinished task is not claimable', () {
    var task = UserTaskModel.fromJson({
      'id': 9,
      'title': '看 10 话',
      'progress': 2,
      'target': 10,
      'status': 0,
    });

    expect(task.finished, isFalse);
    expect(task.claimable, isFalse);
  });

  test('finds tasks however the response nests them', () {
    var wrapped = {
      'errno': 0,
      'data': {
        'daily': {
          'list': [
            {'task_id': 1, 'title': 'A', 'status': 1},
            {'task_id': 2, 'title': 'B', 'status': 2},
          ],
        },
        'growth': [
          {'task_id': 3, 'title': 'C', 'status': 0},
          {'task_id': 1, 'title': 'A 重复', 'status': 1},
        ],
      },
    };

    var tasks = parseUserTasks(wrapped);
    expect(tasks.map((e) => e.id), [1, 2, 3]);
    expect(tasks.where((e) => e.claimable).map((e) => e.id), [1]);
  });

  test('ignores entries that are not tasks', () {
    expect(parseUserTasks({'errno': 99, 'errmsg': '请先登录'}), isEmpty);
    expect(parseUserTasks(null), isEmpty);
    expect(parseUserTasks([1, 2, 3]), isEmpty);
  });
}
