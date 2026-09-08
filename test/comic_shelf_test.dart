import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/modules/user/subscribe/comic/comic_subscribe_controller.dart';
import 'package:zai_x/requests/user_request.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/comic_completion_service.dart';
import 'package:zai_x/services/comic_shelf_repository.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/subscribe_tag_service.dart';
import 'package:zai_x/services/user_service.dart';
import 'support/comic_shelf_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late Box box;
  late ComicShelfRepository repository;
  late _User user;
  final controllers = <ComicSubscribeController>[];

  setUp(() async {
    Get.testMode = true;
    dir = await Directory.systemTemp.createTemp('zmh-shelf-test-');
    box = await Hive.openBox('shelf', path: dir.path);
    Get.put(LocalStorageService()..settingsBox = box);
    Get.put<AppSettingsService>(_Settings());
    user = _User()..logined.value = true;
    Get.put<UserService>(user);
    repository = ComicShelfRepository(box);
    // Public tag fixtures avoid all network traffic in these tests.
    SubscribeTagService.cache.clear();
    for (var i = 1; i <= 700; i++) {
      SubscribeTagService.cache['$i'] = ['冒险'];
    }
  });

  tearDown(() async {
    for (final controller in controllers) {
      controller.onDelete();
    }
    controllers.clear();
    Get.reset();
    await box.close();
    await dir.delete(recursive: true);
  });

  ComicSubscribeController controller(_Request request) {
    final value = ComicSubscribeController(request: request)..onInit();
    controllers.add(value);
    return value;
  }

  test('cache survives a new repository and stays isolated by account',
      () async {
    await repository.save(
        'A', ComicShelfSnapshot([shelfComic(1)], DateTime(2026)));
    final reopened = ComicShelfRepository(box);
    expect(reopened.read('A')!.items.single.id, 1);
    expect(reopened.read('B'), isNull);
    expect(reopened.read(''), isNull);
    await box.put('ComicShelfV1:B', '{broken');
    expect(reopened.read('B'), isNull);
  });

  test('fetches the entire shelf including subscriptions beyond 500', () async {
    final all = List.generate(620, (i) => shelfComic(i + 1));
    var calls = 0;
    final result = await repository.fetch((page) async {
      calls++;
      return ComicSubscriptionPage(all.skip((page - 1) * 50).take(50).toList(),
          total: 620);
    });
    expect(result.items.length, 620);
    expect(calls, 13);
  });

  test(
      'repeated or interrupted pagination never replaces the last complete cache',
      () async {
    await repository.save(
        'A', ComicShelfSnapshot([shelfComic(7)], DateTime(2026)));
    var calls = 0;
    await expectLater(repository.fetch((page) async {
      calls++;
      return ComicSubscriptionPage([shelfComic(1)], total: 3);
    }), throwsA(anything));
    expect(calls, 2);
    await expectLater(repository.fetch((page) async {
      if (page == 2) throw const SocketException('offline');
      return ComicSubscriptionPage([shelfComic(1)], total: 3);
    }), throwsA(isA<SocketException>()));
    expect(repository.read('A')!.items.single.id, 7);
  });

  test('cached order is immediate and remains visible during failed refresh',
      () async {
    await repository.save(
        'A',
        ComicShelfSnapshot([
          shelfComic(1, time: 100),
          shelfComic(2, time: 300),
        ], DateTime(2026)));
    final pending = Completer<ComicSubscriptionPage>();
    final c = controller(_Request((_) => pending.future));
    expect(c.list.map((e) => e.id), [2, 1]);
    final refreshing = c.refreshData();
    expect(c.preparing.value, isFalse);
    expect(c.list.map((e) => e.id), [2, 1]);
    pending.completeError(const SocketException('offline'));
    await refreshing;
    expect(c.refreshFailed.value, isTrue);
    expect(c.pageError.value, isFalse);
    expect(c.list.map((e) => e.id), [2, 1]);
  });

  test('new results are published only after all pages are sorted', () async {
    await repository.save(
        'A', ComicShelfSnapshot([shelfComic(7)], DateTime(2026)));
    final last = Completer<ComicSubscriptionPage>();
    final c = controller(_Request((page) async => page == 1
        ? ComicSubscriptionPage([shelfComic(1, time: 100)], total: 2)
        : await last.future));
    final job = c.refreshData();
    await Future<void>.delayed(Duration.zero);
    expect(c.list.single.id, 7);
    last.complete(ComicSubscriptionPage([shelfComic(2, time: 300)], total: 2));
    await job;
    expect(c.list.map((e) => e.id), [2, 1]);
    expect(repository.read('A')!.items.length, 2);
    await Future<void>.delayed(Duration.zero);
  });

  test('recent reading does not remove subscriptions or change update ordering',
      () async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ComicHistoryAdapter());
    }
    final historyBox =
        await Hive.openBox<ComicHistory>('recent-order', path: dir.path);
    final db = Get.put(DBService()..comicHistoryBox = historyBox);
    await db.putComicHistory(ComicHistory(
        comicId: 1,
        chapterId: 10,
        comicName: 'Comic 1',
        comicCover: '',
        chapterName: 'Chapter 10',
        updateTime: DateTime(2026, 9, 9),
        page: 17));
    await repository.save(
        'A',
        ComicShelfSnapshot([
          shelfComic(1, time: 100),
          shelfComic(2, time: 300),
        ], DateTime(2026)));
    final c = controller(
        _Request((_) async => const ComicSubscriptionPage([], total: 0)));
    expect(c.sort.value, AppSettingsService.kSubscribeSortDefault);
    expect(db.getComicHistoryList().first.comicId, 1);
    expect(c.list.map((book) => book.id), [2, 1]);
    c.setType(3);
    expect(c.list, isEmpty);
    c.resetFilters();
    expect(c.list.map((book) => book.id), [2, 1]);
    expect(db.getComicHistoryList().first.page, 17);
    await historyBox.close();
  });

  test('account change discards in-flight results from the previous user',
      () async {
    await repository.save(
        'A', ComicShelfSnapshot([shelfComic(7)], DateTime(2026)));
    await repository.save(
        'B', ComicShelfSnapshot([shelfComic(8)], DateTime(2026)));
    final pending = Completer<ComicSubscriptionPage>();
    final nextUser = Completer<ComicSubscriptionPage>();
    final c = controller(
        _Request((_) => user.owner == 'A' ? pending.future : nextUser.future));
    final job = c.refreshData();
    user.owner = 'B';
    UserService.loginedStreamController.add(true);
    await Future<void>.delayed(Duration.zero);
    pending.complete(ComicSubscriptionPage([shelfComic(1)], total: 1));
    await job;
    await Future<void>.delayed(Duration.zero);
    expect(repository.read('A')!.items.single.id, 7);
    expect(repository.read('B')!.items.single.id, 8);
    expect(c.list.single.id, 8);
    nextUser.complete(ComicSubscriptionPage([shelfComic(2)], total: 1));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.list.single.id, 2);
  });

  test('read filters react to completion and a newer chapter becomes unread',
      () async {
    await repository.save('A',
        ComicShelfSnapshot([shelfComic(1), shelfComic(2)], DateTime(2026)));
    final c = controller(
        _Request((_) async => const ComicSubscriptionPage([], total: 0)));
    final completion = ComicCompletionService(box, 'A');
    c.setReadFilter(1);
    expect(c.list.length, 2);
    await completion.setChapters(1, [10], completed: true);
    await Future<void>.delayed(Duration.zero);
    expect(c.list.single.id, 2);
    c.setReadFilter(2);
    expect(c.list.single.id, 1);
    expect(
        completion.stateOf(shelfComic(1, latest: 11)), ComicUpdateState.unread);
  });

  test(
      'background changes wait for review while editing and do not replace selection',
      () async {
    await repository.save(
        'A', ComicShelfSnapshot([shelfComic(7)], DateTime(2026)));
    final c = controller(_Request(
        (_) async => ComicSubscriptionPage([shelfComic(2)], total: 1)));
    c.editMode.value = true;
    c.list.single.isChecked.value = true;
    await c.refreshInBackground();
    expect(c.list.single.id, 7);
    expect(c.list.single.isChecked.value, isTrue);
    expect(c.hasPendingUpdate.value, isTrue);
    c.showPendingUpdate();
    expect(c.list.single.id, 7);
    c.cancelEdit();
    c.showPendingUpdate();
    expect(c.list.single.id, 2);
    expect(c.hasPendingUpdate.value, isFalse);
    await Future<void>.delayed(Duration.zero);
  });

  test('opening details and visiting a chapter are not proof of completion',
      () async {
    final completion = ComicCompletionService(box, 'A');
    expect(completion.stateOf(shelfComic(1)), ComicUpdateState.unread);
    expect(
        completion.stateOf(shelfComic(1, history: {
          'chapter_id': 10,
          'record': 1,
          'total_num': 20,
        })),
        ComicUpdateState.unread);
    expect(
        completion.stateOf(shelfComic(1, history: {
          'chapter_id': 10,
          'record': 20,
          'total_num': 0,
        })),
        ComicUpdateState.unread);
    final finished = shelfComic(1,
        history: {'chapter_id': 10, 'record': 20, 'total_num': 20});
    expect(completion.stateOf(finished), ComicUpdateState.caughtUp);
    await completion.setChapters(1, [10], completed: false);
    expect(completion.stateOf(finished), ComicUpdateState.unread);
    expect(ComicCompletionService(box, 'B').stateOf(finished),
        ComicUpdateState.caughtUp);
  });
}

class _Request extends UserRequest {
  _Request(this.loader);
  final Future<ComicSubscriptionPage> Function(int) loader;
  @override
  Future<ComicSubscriptionPage> comicSubscriptionPage(
          {int subType = 1, int page = 1, String letter = ''}) =>
      loader(page);
}

class _User extends UserService {
  String owner = 'A';
  @override
  String get userId => owner;
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _Settings extends AppSettingsService {
  @override
  // ignore: must_call_super
  void onInit() {}
}
