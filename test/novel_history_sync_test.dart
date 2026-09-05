import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/models/db/novel_history.dart';
import 'package:zai_x/models/user/novel_history_model.dart';
import 'package:zai_x/services/db_service.dart';

/// 小说端远端记录合并的回归测试。
///
/// 旧写法把本地时间换算成「秒」去跟远端的「毫秒」相比，远端几乎永远胜出，
/// 导致本机较新的阅读进度被旧记录覆盖。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late DBService db;

  setUpAll(() {
    Hive.registerAdapter(NovelHistoryAdapter());
  });

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zmh-novel-sync-');
    db = DBService();
    db.novelHistoryBox = await Hive.openBox<NovelHistory>(
      'novel-sync',
      path: directory.path,
    );
  });

  tearDown(() async {
    await db.novelHistoryBox.close();
    await directory.delete(recursive: true);
  });

  Future<void> save(int index, {required DateTime time}) => db.putNovelHistory(
        NovelHistory(
          novelId: 21,
          chapterId: 33,
          novelName: 'Test novel',
          novelCover: '',
          chapterName: 'Chapter 33',
          volumeId: 3,
          volumeName: 'Volume 3',
          total: 100,
          index: index,
          updateTime: time,
        ),
      );

  test('older remote record keeps local novel progress', () async {
    final readAt = DateTime.utc(2026, 9, 5, 10, 0);
    await save(4200, time: readAt);

    db.syncRemoteNovelHistory([
      _remote(index: 0, time: readAt.subtract(const Duration(hours: 6))),
    ]);
    await db.novelHistoryBox.flush();

    expect(db.getNovelHistory(21)!.index, 4200);
    expect(db.getNovelHistory(21)!.updateTime, readAt);
  });

  test('newer remote record replaces local novel progress', () async {
    final readAt = DateTime.utc(2026, 9, 5, 10, 0);
    await save(4200, time: readAt);

    db.syncRemoteNovelHistory([
      _remote(index: 9000, time: readAt.add(const Duration(minutes: 5))),
    ]);
    await db.novelHistoryBox.flush();

    expect(db.getNovelHistory(21)!.index, 9000);
  });

  test('unseen remote record is inserted', () async {
    final readAt = DateTime.utc(2026, 9, 5, 10, 0);

    db.syncRemoteNovelHistory([_remote(index: 120, time: readAt)]);
    await db.novelHistoryBox.flush();

    final saved = db.getNovelHistory(21);
    expect(saved, isNotNull);
    expect(saved!.index, 120);
    expect(saved.chapterId, 33);
  });
}

UserNovelHistoryModel _remote({required int index, required DateTime time}) =>
    UserNovelHistoryModel(
      lnovelId: 21,
      chapterId: 33,
      novelName: 'Test novel',
      cover: '',
      chapterName: 'Chapter 33',
      volumeId: 3,
      volumeName: 'Volume 3',
      totalNum: 100,
      record: index,
      viewingTime: time.millisecondsSinceEpoch ~/ 1000,
    );
