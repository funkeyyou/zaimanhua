import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/models/user/task_model.dart';

/// 样本取自实机抓下来的 GET /lpi/v1/task/list（帐号资料已简化）
Map<String, dynamic> _sample() => {
      'errno': 0,
      'errmsg': '',
      'data': {
        'task': {
          'dayTask': [
            {
              'id': 13,
              'title': '海螺小姐',
              'desc': '累计观看十分钟漫画',
              'currency': {'credits': 1, 'silver': 0, 'stars': 0},
              'status': 1,
              'target_count': 1,
              'progress_count': 0,
            },
            {
              'id': 16,
              'title': 'VIP福利',
              'desc': 'VIP会员每日积分福利',
              'currency': {'credits': 2, 'silver': 0, 'stars': 0},
              'status': 3,
              'target_count': 1,
              'progress_count': 1,
            },
          ],
          'newUserTask': [
            {
              'id': 7,
              'title': '初来乍到',
              'desc': '完成绑定手机',
              'currency': {'credits': 2},
              'status': 3,
              'target_count': 1,
              'progress_count': 1,
            },
          ],
          'signInfo': {
            'currentDay': 7,
            'currentSign': true,
            'list': [
              {'id': 1, 'title': '1天', 'desc': '', 'currency': {'credits': 1}},
              {'id': 2, 'title': '2天', 'desc': '', 'currency': {'credits': 2}},
            ],
          },
          'sumSignTask': {
            'continuousSignDays': 21,
            'sumSignDays': 153,
            'list': [
              {
                'id': 1,
                'title': '3天',
                'currency': {'credits': 3},
                'status': 3,
                'target_count': 1,
                'progress_count': 1,
              },
            ],
          },
        },
        'userCurrency': {'credits': 539, 'silver': 0, 'stars': 0},
      },
    };

void main() {
  test('groups follow the official layout', () {
    var groups = parseUserTaskGroups(_sample());

    expect(groups.map((e) => e.title), ['每日任务', '新人任务']);
    expect(groups.first.tasks.map((e) => e.id), [13, 16]);
  });

  test('sign calendar and milestones are not listed as tasks', () {
    var tasks = parseUserTasks(_sample());

    // signInfo.list 的「1天」「2天」没有 status，sumSignTask 用的是另一套 id
    expect(tasks.map((e) => e.title), isNot(contains('1天')));
    expect(tasks.map((e) => e.title), isNot(contains('3天')));
    expect(tasks.length, 3);
  });

  test('status decides the state', () {
    var tasks = parseUserTasks(_sample());
    var running = tasks.firstWhere((e) => e.id == 13);
    var vip = tasks.firstWhere((e) => e.id == 16);

    expect(running.status, UserTaskModel.kStatusRunning);
    expect(running.claimable, isFalse);
    expect(running.received, isFalse);
    expect(running.progress, 0);
    expect(running.target, 1);
    expect(running.credits, 1);

    expect(vip.received, isTrue);
    expect(vip.claimable, isFalse);
  });

  test('status 2 is the claimable state', () {
    var task = UserTaskModel.fromJson({
      'id': 13,
      'title': '海螺小姐',
      'status': 2,
      'target_count': 1,
      'progress_count': 1,
      'currency': {'credits': 1},
    });

    expect(task.claimable, isTrue);
    expect(task.received, isFalse);
  });

  test('reads credits and sign summary', () {
    expect(parseUserCredits(_sample()), 539);

    var sign = parseSignSummary(_sample());
    expect(sign.continuousDays, 21);
    expect(sign.totalDays, 153);
  });

  test('falls back to a global search when the shape changes', () {
    var moved = {
      'data': {
        'somethingNew': [
          {'id': 21, 'title': 'A', 'status': 2, 'currency': {'credits': 5}},
        ],
      },
    };

    var tasks = parseUserTasks(moved);
    expect(tasks.single.id, 21);
    expect(tasks.single.claimable, isTrue);
  });

  test('ignores error responses', () {
    expect(parseUserTasks({'errno': 99, 'errmsg': '请先登录'}), isEmpty);
    expect(parseUserTasks(null), isEmpty);
  });
}
