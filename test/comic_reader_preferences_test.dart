import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/services/comic_reader_preferences.dart';

void main() {
  late Directory dir;
  late Box box;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('zmh-reader-prefs-');
    box = await Hive.openBox('prefs', path: dir.path);
  });
  tearDown(() async {
    await box.close();
    await dir.delete(recursive: true);
  });
  test(
      'per-comic preferences persist independently and reset to inherited defaults',
      () async {
    final store = ComicReaderPreferencesStore(box);
    await store.write(
        1, const ComicReaderPreferences(direction: 2, dualPage: 0));
    await store.write(
        2, const ComicReaderPreferences(direction: 1, coverAlone: false));
    await box.close();
    box = await Hive.openBox('prefs', path: dir.path);
    final reopened = ComicReaderPreferencesStore(box);
    expect(reopened.read(1).direction, 2);
    expect(reopened.read(1).dualPage, 0);
    expect(reopened.read(2).direction, 1);
    expect(reopened.read(2).coverAlone, isFalse);
    expect(reopened.read(2).dualPage, isNull);
    await reopened.reset(1);
    expect(reopened.read(1).isCustom, isFalse);
    expect(reopened.read(2).isCustom, isTrue);
  });
  test('invalid preferences fall back without damaging other options',
      () async {
    await box.put('ComicReaderPreferencesV1:1',
        {'direction': 42, 'dualPage': 2, 'coverAlone': 'false'});
    final value = ComicReaderPreferencesStore(box).read(1);
    expect(value.direction, isNull);
    expect(value.dualPage, 2);
    expect(value.coverAlone, isNull);
    expect(value.copyWith(direction: 1).dualPage, 2);
  });
}
