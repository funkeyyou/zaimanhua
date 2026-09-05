import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/services/db_service.dart';

/// 已读章节标记的存取回归测试
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late DBService db;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zmh-read-chapter-');
    db = DBService();
    db.comicReadChapterBox = await Hive.openBox(
      'comic-read-chapter',
      path: directory.path,
    );
  });

  tearDown(() async {
    await db.comicReadChapterBox.close();
    await directory.delete(recursive: true);
  });

  test('marks chapters read without duplicating', () async {
    expect(await db.markComicChaptersRead(7, [11, 12]), isTrue);
    expect(await db.markComicChaptersRead(7, [12]), isFalse);

    expect(db.getComicReadChapters(7), {11, 12});
    expect(db.isComicChapterRead(7, 11), isTrue);
    expect(db.isComicChapterRead(7, 99), isFalse);
  });

  test('keeps comics apart', () async {
    await db.markComicChaptersRead(7, [11]);
    await db.markComicChaptersRead(8, [21]);

    expect(db.getComicReadChapters(7), {11});
    expect(db.getComicReadChapters(8), {21});
  });

  test('unmark removes ids and clears empty entries', () async {
    await db.markComicChaptersRead(7, [11, 12, 13]);

    expect(await db.markComicChaptersUnread(7, [12]), isTrue);
    expect(db.getComicReadChapters(7), {11, 13});

    expect(await db.markComicChaptersUnread(7, [11, 13]), isTrue);
    expect(db.getComicReadChapters(7), isEmpty);
    expect(db.comicReadChapterBox.containsKey(7), isFalse);

    expect(await db.markComicChaptersUnread(7, [11]), isFalse);
  });

  test('ignores chapter id 0 and unreadable values', () async {
    await db.markComicChaptersRead(7, [0, 11]);
    expect(db.getComicReadChapters(7), {11});

    await db.comicReadChapterBox.put(9, 'not-a-list');
    expect(db.getComicReadChapters(9), isEmpty);
  });
}
