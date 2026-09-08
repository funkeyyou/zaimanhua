import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:zai_x/main.dart' as app;

/// flutter build apk --profile -t tools/profile_app.dart
/// adb logcat -s flutter | Select-String ZMH_PROFILE
/// 只记录耗时、帧数与内存；不采集账号、请求、书名或阅读内容。
void main() {
  if (!kProfileMode) {
    throw StateError('Use --profile for this diagnostic entrypoint');
  }
  final frames = <FrameTiming>[];
  WidgetsFlutterBinding.ensureInitialized().addTimingsCallback(frames.addAll);
  var sample = 0;
  Timer.periodic(const Duration(seconds: 10), (_) {
    if (frames.isEmpty) return;
    final build = frames.map((e) => e.buildDuration.inMicroseconds).toList()
      ..sort();
    final raster = frames.map((e) => e.rasterDuration.inMicroseconds).toList()
      ..sort();
    double p95(List<int> values) =>
        values[((values.length - 1) * .95).round()] / 1000;
    final cache = PaintingBinding.instance.imageCache;
    debugPrint('ZMH_PROFILE ${jsonEncode({
          'sample': ++sample,
          'frames': frames.length,
          'build_p95_ms': p95(build),
          'raster_p95_ms': p95(raster),
          'over_16ms': frames
              .where((e) =>
                  e.buildDuration.inMicroseconds > 16667 ||
                  e.rasterDuration.inMicroseconds > 16667)
              .length,
          'image_cache_bytes': cache.currentSizeBytes,
          'live_images': cache.liveImageCount,
          'rss_bytes': ProcessInfo.currentRss,
        })}');
    frames.clear();
  });
  app.main();
}
