import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/models/comic/chapter_info.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/modules/comic/reader/comic_reader_controller.dart';
import 'package:zai_x/modules/comic/reader/comic_reader_source.dart';
import 'package:zai_x/services/app_settings_service.dart';
import 'package:zai_x/services/local_storage_service.dart';
import 'package:zai_x/services/comic_reader_preferences.dart';

class _Settings extends AppSettingsService {
  @override
  // Skip production settings initialization in the isolated fixture.
  // ignore: must_call_super
  void onInit() {}
}

class _Reader extends ComicReaderController {
  _Reader(ComicReaderSource source)
      : super(
            comicId: 7,
            comicTitle: 'Test',
            comicCover: '',
            chapter: item,
            chapters: [item],
            isLongComic: false,
            externalSource: source);
  static final item = ComicDetailChapterItem(
      chapterId: 7,
      chapterTitle: 'Test',
      updateTime: 0,
      fileSize: 0,
      chapterOrder: 0);
  @override
  void jumpToPage(int page, {bool anime = false}) {
    currentIndex.value = page;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'shared reader resumes and writes external progress without Zaimanhua services',
      () async {
    Get.testMode = true;
    final dir = await Directory.systemTemp.createTemp('external-reader-');
    final box = await Hive.openBox('external_settings', path: dir.path);
    Get.put(LocalStorageService()..settingsBox = box);
    Get.put<AppSettingsService>(_Settings());
    var saved = -1;
    final reader = _Reader(ComicReaderSource(
      load: () async => ComicChapterDetail(
          chapterId: 7,
          comicId: 7,
          chapterOrder: 0,
          direction: 0,
          chapterTitle: 'Test',
          pageUrls: ['1', '2', '3', '4', '5'],
          picnum: 5,
          commentCount: 0),
      readPage: () => 3,
      writePage: (page) async {
        saved = page;
      },
      headers: const {'Referer': 'https://hitomi.la/'},
      preferencesNamespace: 'HitomiReaderPreferencesV1',
      favorite: false.obs,
      toggleFavorite: () async {},
    ));
    try {
      reader.loadDetail();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(reader.pageError.value, false);
      expect(reader.currentIndex.value, 3);
      expect(reader.detail.value.pageUrls, hasLength(5));
      expect(saved, 3);
      // Windows keyboard input turns pages inside the external gallery.
      expect(reader.consumesKey(LogicalKeyboardKey.arrowRight), isTrue);
      reader.keyDown(LogicalKeyboardKey.arrowRight);
      expect(reader.currentIndex.value, 4);
      reader.keyDown(LogicalKeyboardKey.arrowLeft);
      expect(reader.currentIndex.value, 3);
      reader.currentIndex.value = 4;
      reader.uploadHistory();
      reader.loadViewPoints();
      reader.setShowViewPoint(true);
      reader.markCompletedIfVisible();
      expect(saved, 4);
      expect(reader.detail.value.pageUrls, hasLength(5));
      reader.setDirection(1);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(ComicReaderPreferencesStore(box).read(7).direction, isNull);
      expect(
          ComicReaderPreferencesStore(box,
                  namespace: 'HitomiReaderPreferencesV1')
              .read(7)
              .direction,
          1);
    } finally {
      reader.focusNode.dispose();
      reader.preloadPageController.dispose();
      Get.reset();
      await box.close();
      await dir.delete(recursive: true);
    }
  });
}
