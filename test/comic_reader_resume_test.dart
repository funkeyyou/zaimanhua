import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/models/comic/chapter_info.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/models/db/comic_history.dart';
import 'package:zai_x/models/user/comic_history_model.dart';
import 'package:zai_x/modules/comic/reader/comic_reader_controller.dart';
import 'package:zai_x/requests/comic_request.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/db_service.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/user_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late DBService db;
  late AppSettingsService settings;

  setUpAll(() {
    Hive.registerAdapter(ComicHistoryAdapter());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
      'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
      (_) async => const StandardMessageCodec().encodeMessage([null]),
    );
  });

  setUp(() async {
    Get.testMode = true;
    directory = await Directory.systemTemp.createTemp('zmh-reader-resume-');
    db = DBService();
    db.comicHistoryBox = await Hive.openBox<ComicHistory>(
      'comic-resume',
      path: directory.path,
    );
    Get.put<DBService>(db);
    Get.put<LocalStorageService>(LocalStorageService());
    Get.put<UserService>(_OfflineUserService());
    settings = Get.put<AppSettingsService>(_TestSettings());
  });

  tearDown(() async {
    Get.reset();
    await db.comicHistoryBox.close();
    await directory.delete(recursive: true);
  });

  Future<void> save(int page, {DateTime? time}) => db.putComicHistory(
        ComicHistory(
          comicId: 7,
          chapterId: 10,
          comicName: 'Test comic',
          comicCover: '',
          chapterName: 'Chapter 10',
          updateTime: time ?? DateTime.now(),
          page: page,
        ),
      );

  // Exercise the real controller, storage and offline UserService. Only the
  // chapter request and platform view are replaced, so no login/network is used.
  for (final page in [8, 20]) {
    test('exit and continue keeps page $page of 20', () async {
      settings.comicReaderShowViewPoint.value = false;
      final first = _Reader(_ChapterRequest());
      first.loadDetail();
      await _settleReader();
      first.currentIndex.value = page - 1;
      first.onDelete();
      await db.comicHistoryBox.flush();
      expect(db.getComicHistory(7)!.page, page);

      final resumed = _Reader(_ChapterRequest());
      resumed.loadDetail();
      await _settleReader();
      expect(resumed.currentIndex.value, page - 1);
      expect(resumed.lastJump, page - 1);
      expect(db.getComicHistory(7)!.page, page);
      resumed.onDelete();
    });
  }

  test('comment page resumes at the last comic image', () async {
    await save(21);
    settings.comicReaderShowViewPoint.value = true;
    final reader = _Reader(_ChapterRequest());
    reader.loadDetail();
    await _settleReader();
    expect(reader.currentIndex.value, 19);
    expect(db.getComicHistory(7)!.page, 20);
    reader.onDelete();
  });

  test('a shorter image list clamps progress to its last image', () async {
    await save(25);
    final reader = _Reader(_ChapterRequest());
    reader.loadDetail();
    await _settleReader();
    expect(reader.currentIndex.value, 19);
    reader.onDelete();
  });

  test('closing during loading cannot erase progress or save a late response',
      () async {
    await save(8);
    final pending = Completer<ComicChapterDetail>();
    final request = _ChapterRequest()..pending = pending.future;
    final reader = _Reader(request);
    reader.loadDetail();
    reader.onDelete();
    await db.comicHistoryBox.flush();
    expect(db.getComicHistory(7)!.page, 8);

    pending.complete(_chapter());
    await _settleReader();
    expect(reader.lastJump, isNull);
    expect(db.getComicHistory(7)!.page, 8);
  });

  test('closing before the delayed page restore cannot save transient page 1',
      () async {
    await save(8);
    final reader = _Reader(_ChapterRequest());
    reader.loadDetail();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    // PageView can report its initial page while it is being rebuilt.
    reader.currentIndex.value = 0;
    reader.onDelete();
    await db.comicHistoryBox.flush();
    expect(db.getComicHistory(7)!.page, 8);
    await _settleReader();
    expect(db.getComicHistory(7)!.page, 8);
  });

  test('empty chapter response cannot overwrite saved progress', () async {
    await save(8);
    final request = _ChapterRequest()
      ..pending = Future.value(_chapter(pageCount: 0));
    final reader = _Reader(request);
    reader.loadDetail();
    await _settleReader();
    reader.onDelete();
    await db.comicHistoryBox.flush();
    expect(db.getComicHistory(7)!.page, 8);
  });

  test('entering the comment page saves the last image, not a synthetic page',
      () async {
    final reader = _Reader(_ChapterRequest());
    reader.loadDetail();
    await _settleReader();
    reader.currentIndex.value = 20;
    reader.onDelete();
    await db.comicHistoryBox.flush();
    expect(db.getComicHistory(7)!.page, 20);
  });

  test(
      'older or equal remote first-page progress cannot replace local progress',
      () async {
    final readAt = DateTime.utc(2026, 9, 5, 10, 0);
    for (final delta in [const Duration(hours: -1), Duration.zero]) {
      await save(8, time: readAt);
      db.syncRemoteComicHistory([
        _remote(page: 1, time: readAt.add(delta)),
      ]);
      await db.comicHistoryBox.flush();
      expect(db.getComicHistory(7)!.page, 8);
      expect(db.getComicHistory(7)!.updateTime, readAt);
    }
  });

  test('newer remote progress still replaces local progress', () async {
    final readAt = DateTime.utc(2026, 9, 5, 10, 0);
    await save(8, time: readAt);
    db.syncRemoteComicHistory([
      _remote(page: 15, time: readAt.add(const Duration(minutes: 1))),
    ]);
    await db.comicHistoryBox.flush();
    expect(db.getComicHistory(7)!.page, 15);
  });
}

Future<void> _settleReader() =>
    Future<void>.delayed(const Duration(milliseconds: 160));

UserComicHistoryModel _remote({required int page, required DateTime time}) =>
    UserComicHistoryModel(
      comicId: 7,
      chapterId: 10,
      comicName: 'Test comic',
      cover: '',
      chapterName: 'Chapter 10',
      record: page,
      viewingTime: time.millisecondsSinceEpoch ~/ 1000,
    );

ComicChapterDetail _chapter({int pageCount = 20}) => ComicChapterDetail(
      chapterId: 10,
      comicId: 7,
      chapterOrder: 1,
      direction: 0,
      chapterTitle: 'Chapter 10',
      pageUrls: List.generate(pageCount, (i) => 'page-$i'),
      picnum: pageCount,
      commentCount: 0,
    );

class _ChapterRequest extends ComicRequest {
  Future<ComicChapterDetail>? pending;

  @override
  Future<ComicChapterDetail> chapterDetail({
    required int comicId,
    required int chapterId,
    required bool useHD,
  }) =>
      pending ?? Future.value(_chapter());
}

class _Reader extends ComicReaderController {
  _Reader(this._request)
      : super(
          comicId: 7,
          comicTitle: 'Test comic',
          comicCover: '',
          chapter: _item,
          chapters: [_item],
          isLongComic: false,
        );

  static final _item = ComicDetailChapterItem(
    chapterId: 10,
    chapterTitle: 'Chapter 10',
    updateTime: 0,
    fileSize: 0,
    chapterOrder: 1,
  );

  final ComicRequest _request;

  @override
  ComicRequest get request => _request;

  int? lastJump;

  @override
  void loadViewPoints() {}

  @override
  void setShowControls() {}

  @override
  void jumpToPage(int page, {bool anime = false}) {
    lastJump = page;
    currentIndex.value = page;
  }
}

class _TestSettings extends AppSettingsService {
  // Skip production disk/plugin initialization in this offline fixture.
  @override
  // ignore: must_call_super
  void onInit() {}
}

class _OfflineUserService extends UserService {
  // Skip production login/network initialization in this offline fixture.
  @override
  // ignore: must_call_super
  void onInit() {}
}
