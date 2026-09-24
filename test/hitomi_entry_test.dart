import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:zai_x/modules/index/index_controller.dart';
import 'package:zai_x/modules/hitomi/hitomi_page.dart';
import 'package:zai_x/services/local_storage_service.dart';

class _Index extends IndexController {
  @override
  void showFirstRun() {}
}

void main() {
  test(
      'hidden source stays lazy, persists unlock, and exits selected tab on hide',
      () async {
    Get.testMode = true;
    final dir = await Directory.systemTemp.createTemp('hitomi-entry-');
    final box = await Hive.openBox('entry_test', path: dir.path);
    Get.put(LocalStorageService()..settingsBox = box);
    try {
      final index = _Index()..onInit();
      expect(index.hitomiEnabled.value, isFalse);
      expect(index.navigationOrder, [0, 1, 2, 3, 4]);
      index.setIndex(5);
      expect(index.index.value, 0);
      expect(index.pages[5], isA<SizedBox>());
      await index.setHitomiEnabled(true);
      final restored = _Index()..onInit();
      expect(restored.hitomiEnabled.value, isTrue);
      expect(restored.navigationOrder, [0, 5, 1, 2, 3, 4]);
      expect(restored.pages[5], isA<SizedBox>());
      restored.setIndex(5);
      expect(restored.pages[5], isA<HitomiPage>());
      await restored.setHitomiEnabled(false);
      expect(restored.index.value, 4);
      expect(restored.navigationOrder, [0, 1, 2, 3, 4]);
      expect(restored.pages[5], isA<SizedBox>());
      expect(box.get('HitomiEnabledV1'), false);
    } finally {
      Get.reset();
      await box.close();
      await dir.delete(recursive: true);
    }
  });
}
