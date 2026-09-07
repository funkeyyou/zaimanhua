import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/app/utils.dart';
import 'package:zai_x/models/user/subscribe_comic_model.dart';

/// 样本取自实机抓下来的 GET /comic/sub/list（只留排序用得到的栏位）
Map<String, dynamic> _item({
  required int id,
  required String title,
  required int chapterId,
  required int updateTime,
}) =>
    {
      'id': id,
      'title': title,
      'cover': '',
      'sub_readed': 1,
      'last_update_chapter_id': chapterId,
      'last_update_chapter_name': '第01话',
      'comic_py': 'test',
      'status': '连载中',
      'last_updatetime': updateTime,
      'readingRecord': {
        'type_name': 'mh',
        'uid': 0,
        'source': 1,
        'biz_id': id,
        'chapter_id': 0,
        'viewing_time': 0,
        'record': 0,
        'volume_id': 0,
        'total_num': 0,
        'chapter_name': '',
        'volume_name': '',
      },
    };

void main() {
  test('订阅列表会读到 last_updatetime', () {
    var item = UserSubscribeComicItemModel.fromJson(
      _item(id: 1, title: 'A', chapterId: 190463, updateTime: 1788507226),
    );
    expect(item.lastUpdateTime, 1788507226);
    expect(item.updateSortKey, 1788507226);
  });

  test('没有 last_updatetime 时退回章节 id', () {
    var raw = _item(id: 2, title: 'B', chapterId: 12345, updateTime: 0)
      ..remove('last_updatetime');
    var item = UserSubscribeComicItemModel.fromJson(raw);
    expect(item.lastUpdateTime, 0);
    expect(item.updateSortKey, 12345);
  });

  test('更新时间排序不能用章节 id 代替', () {
    // 实机资料：轮回的花瓣章节 id 比较大，但更新时间比魔法少女201旧
    var older = UserSubscribeComicItemModel.fromJson(
      _item(id: 14883, title: '轮回的花瓣', chapterId: 190463, updateTime: 1788507226),
    );
    var newer = UserSubscribeComicItemModel.fromJson(
      _item(id: 60340, title: '魔法少女201', chapterId: 186156, updateTime: 1788758029),
    );
    var items = [older, newer];

    items.sort((a, b) => b.lastUpdateChapterId.compareTo(a.lastUpdateChapterId));
    expect(items.first.title, '轮回的花瓣', reason: '章节 id 排序会把旧的排到最前面');

    items.sort((a, b) => b.updateSortKey.compareTo(a.updateSortKey));
    expect(items.first.title, '魔法少女201');

    items.sort((a, b) => a.updateSortKey.compareTo(b.updateSortKey));
    expect(items.first.title, '轮回的花瓣');
  });

  test('上次更新时间显示成相对时间', () {
    var now = DateTime.now();
    int ts(Duration d) =>
        now.subtract(d).millisecondsSinceEpoch ~/ 1000;

    expect(Utils.friendlyTimestamp(0), '');
    expect(Utils.friendlyTimestamp(ts(const Duration(seconds: 5))), '刚刚');
    expect(Utils.friendlyTimestamp(ts(const Duration(minutes: 20))), '20分钟前');
    expect(Utils.friendlyTimestamp(ts(const Duration(hours: 6))), '6小时前');
    expect(Utils.friendlyTimestamp(ts(const Duration(days: 2))), '2天前');
  });
}
