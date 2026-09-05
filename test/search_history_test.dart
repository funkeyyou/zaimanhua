import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/app/app_constant.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/models/db/local_favorite.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/search_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late LocalStorageService storage;
  late DBService db;

  setUpAll(() {
    Hive.registerAdapter(ComicHistoryAdapter());
    Hive.registerAdapter(LocalFavoriteAdapter());
  });

  setUp(() async {
    Get.testMode = true;
    directory = await Directory.systemTemp.createTemp('zmh-search-history-');
    storage = LocalStorageService();
    storage.settingsBox = await Hive.openBox(
      'search-settings',
      path: directory.path,
    );
    db = DBService();
    db.comicHistoryBox = await Hive.openBox<ComicHistory>(
      'search-comic-history',
      path: directory.path,
    );
    db.localFavoriteBox = await Hive.openBox<LocalFavorite>(
      'search-favorite',
      path: directory.path,
    );
    Get.put<LocalStorageService>(storage);
    Get.put<DBService>(db);
  });

  tearDown(() async {
    Get.reset();
    await storage.settingsBox.close();
    await db.comicHistoryBox.close();
    await db.localFavoriteBox.close();
    await directory.delete(recursive: true);
  });

  test('newest keyword comes first and repeats are merged', () async {
    await SearchHistoryService.add(AppConstant.kTypeComic, '海賊');
    await SearchHistoryService.add(AppConstant.kTypeComic, '排球');
    await SearchHistoryService.add(AppConstant.kTypeComic, '海賊');

    expect(SearchHistoryService.get(AppConstant.kTypeComic), ['海賊', '排球']);
  });

  test('blank keywords are ignored and the list is capped', () async {
    await SearchHistoryService.add(AppConstant.kTypeComic, '   ');
    expect(SearchHistoryService.get(AppConstant.kTypeComic), isEmpty);

    var total = SearchHistoryService.kMaxItems + 5;
    for (var i = 0; i < total; i++) {
      await SearchHistoryService.add(AppConstant.kTypeComic, 'kw-$i');
    }
    var list = SearchHistoryService.get(AppConstant.kTypeComic);
    expect(list.length, SearchHistoryService.kMaxItems);
    expect(list.first, 'kw-' + (total - 1).toString());
  });

  test('comic and novel histories do not mix', () async {
    await SearchHistoryService.add(AppConstant.kTypeComic, '漫畫');
    await SearchHistoryService.add(AppConstant.kTypeNovel, '小說');

    expect(SearchHistoryService.get(AppConstant.kTypeComic), ['漫畫']);
    expect(SearchHistoryService.get(AppConstant.kTypeNovel), ['小說']);
  });

  test('remove and clear', () async {
    await SearchHistoryService.add(AppConstant.kTypeComic, 'a');
    await SearchHistoryService.add(AppConstant.kTypeComic, 'b');

    await SearchHistoryService.remove(AppConstant.kTypeComic, 'a');
    expect(SearchHistoryService.get(AppConstant.kTypeComic), ['b']);

    await SearchHistoryService.clear(AppConstant.kTypeComic);
    expect(SearchHistoryService.get(AppConstant.kTypeComic), isEmpty);
  });

  test('suggestions come from history and local favorites', () async {
    await db.putComicHistory(
      ComicHistory(
        comicId: 7,
        chapterId: 1,
        comicName: '進擊的巨人',
        comicCover: '',
        chapterName: '1',
        updateTime: DateTime.now(),
        page: 1,
      ),
    );
    db.putComicFavorite(title: '巨人族的新娘', cover: '', comicId: 8);

    var hits = SearchHistoryService.suggest(AppConstant.kTypeComic, '巨人');
    expect(hits.map((e) => e.id), containsAll(<int>[7, 8]));

    expect(SearchHistoryService.suggest(AppConstant.kTypeComic, ''), isEmpty);
    expect(
      SearchHistoryService.suggest(AppConstant.kTypeComic, '不存在的作品'),
      isEmpty,
    );
  });
}
