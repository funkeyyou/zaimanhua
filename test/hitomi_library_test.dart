import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/modules/hitomi/hitomi_library.dart';
import 'package:zai_x/modules/hitomi/hitomi_source.dart';

void main() {
  test('index uses big endian IDs and rejects malformed responses', () {
    expect(HitomiSource.decodeIds([0, 0, 1, 0, 0, 0, 0, 2]), [256, 2]);
    expect(() => HitomiSource.decodeIds([1, 2, 3]), throwsFormatException);
  });
  test('source library keeps favorites and resume position after reopen',
      () async {
    final dir = await Directory.systemTemp.createTemp('hitomi-library-');
    var box = await Hive.openBox('hitomi_test', path: dir.path);
    try {
      final store = HitomiLibrary(box);
      final gallery = {'id': '123', 'title': 'Test', 'files': [], 'tags': []};
      await store.save(gallery, favorite: true);
      expect(store.entries(favorites: false), isEmpty);
      await store.save(gallery, page: 8);
      await store.save(gallery, favorite: false);
      await box.close();
      box = await Hive.openBox('hitomi_test', path: dir.path);
      final restored = HitomiLibrary(box);
      expect(restored.page(gallery), 8);
      expect(restored.favorite(gallery), isFalse);
      expect(restored.entries(favorites: false), hasLength(1));
      expect(restored.entries(favorites: true), isEmpty);
    } finally {
      await box.close();
      await dir.delete(recursive: true);
    }
  });
  test('desktop library stays with app data instead of Documents', () async {
    final documents = await Directory.systemTemp.createTemp('hitomi-docs-');
    final support = await Directory.systemTemp.createTemp('hitomi-support-');
    // Same default as Hive.initFlutter(), which is Documents on Windows.
    Hive.init(documents.path);
    final store = await HitomiLibrary.open(
        desktop: true, supportDirectory: () async => support);
    final file = '${HitomiLibrary.boxName}.hive';
    try {
      await store
          .save({'id': 1, 'title': 'Test', 'files': [], 'tags': []}, page: 1);
      expect(File('${support.path}${Platform.pathSeparator}$file').existsSync(),
          isTrue);
      expect(
          File('${documents.path}${Platform.pathSeparator}$file').existsSync(),
          isFalse);
    } finally {
      await store.box.close();
      await documents.delete(recursive: true);
      await support.delete(recursive: true);
    }
  });
  test('mobile library keeps its existing private location', () async {
    final documents = await Directory.systemTemp.createTemp('hitomi-mobile-');
    Hive.init(documents.path);
    var askedForSupport = false;
    final store = await HitomiLibrary.open(
        desktop: false,
        supportDirectory: () async {
          askedForSupport = true;
          return documents;
        });
    try {
      expect(askedForSupport, isFalse);
      expect(
          File('${documents.path}${Platform.pathSeparator}${HitomiLibrary.boxName}.hive')
              .existsSync(),
          isTrue);
    } finally {
      await store.box.close();
      await documents.delete(recursive: true);
    }
  });
}
