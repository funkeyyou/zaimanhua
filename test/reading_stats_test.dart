import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/services/reading_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ReadingStatsService stats;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('zmh-reading-stats-');
    stats = ReadingStatsService();
    stats.statsBox = await Hive.openBox('reading-stats', path: directory.path);
  });

  tearDown(() async {
    await stats.statsBox.close();
    await directory.delete(recursive: true);
  });

  test('counts comic and novel chapters separately', () async {
    await stats.addChapter(AppConstant.kTypeComic);
    await stats.addChapter(AppConstant.kTypeComic);
    await stats.addChapter(AppConstant.kTypeNovel);

    var today = stats.today;
    expect(today.comicChapters, 2);
    expect(today.novelChapters, 1);
    expect(today.chapters, 3);
  });

  test('very short sessions are not counted as reading time', () async {
    await stats.addSeconds(3);
    expect(stats.today.seconds, 0);

    await stats.addSeconds(120);
    await stats.addSeconds(60);
    expect(stats.today.seconds, 180);
  });

  test('recentDays returns the requested window in order', () async {
    var yesterday = DateTime.now().subtract(const Duration(days: 1));
    await stats.addChapter(AppConstant.kTypeComic, at: yesterday);
    await stats.addChapter(AppConstant.kTypeComic);

    var week = stats.recentDays(7);
    expect(week.length, 7);
    expect(week.last.chapters, 1);
    expect(week[week.length - 2].chapters, 1);
    expect(week.first.isEmpty, isTrue);
  });

  test('streak counts back from today and survives an unread today', () async {
    var now = DateTime.now();
    await stats.addChapter(
      AppConstant.kTypeComic,
      at: now.subtract(const Duration(days: 1)),
    );
    await stats.addChapter(
      AppConstant.kTypeComic,
      at: now.subtract(const Duration(days: 2)),
    );

    expect(stats.streak, 2);

    await stats.addChapter(AppConstant.kTypeComic);
    expect(stats.streak, 3);
  });

  test('streak breaks on a missing day', () async {
    var now = DateTime.now();
    await stats.addChapter(AppConstant.kTypeComic);
    await stats.addChapter(
      AppConstant.kTypeComic,
      at: now.subtract(const Duration(days: 3)),
    );

    expect(stats.streak, 1);
  });

  test('total sums every day and clear wipes it', () async {
    var now = DateTime.now();
    await stats.addChapter(AppConstant.kTypeComic);
    await stats.addChapter(
      AppConstant.kTypeNovel,
      at: now.subtract(const Duration(days: 5)),
    );
    await stats.addSeconds(300);

    expect(stats.total.chapters, 2);
    expect(stats.total.seconds, 300);
    expect(stats.activeDays, 2);

    await stats.clear();
    expect(stats.total.chapters, 0);
    expect(stats.activeDays, 0);
  });
}
