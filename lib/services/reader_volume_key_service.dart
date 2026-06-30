import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ReaderVolumeKeyService {
  ReaderVolumeKeyService._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static final ReaderVolumeKeyService instance = ReaderVolumeKeyService._();

  static const MethodChannel _channel =
      MethodChannel('zai_x/reader_volume_key');

  VoidCallback? _onVolumeUp;
  VoidCallback? _onVolumeDown;
  bool _active = false;

  Future<void> start({
    required bool enabled,
    required VoidCallback onVolumeUp,
    required VoidCallback onVolumeDown,
  }) async {
    _active = true;
    _onVolumeUp = onVolumeUp;
    _onVolumeDown = onVolumeDown;
    await _setEnabled(enabled);
  }

  Future<void> stop() async {
    _active = false;
    _onVolumeUp = null;
    _onVolumeDown = null;
    await _setEnabled(false);
  }

  Future<void> setEnabled(bool enabled) async {
    if (!_active) {
      return;
    }
    await _setEnabled(enabled);
  }

  Future<void> _setEnabled(bool enabled) async {
    if (!Platform.isAndroid) {
      return;
    }
    try {
      await _channel.invokeMethod('setEnabled', enabled);
    } catch (_) {
      // Non-Android targets or older embeddings can safely ignore this.
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (!_active) {
      return;
    }
    switch (call.method) {
      case 'volumeUp':
        _onVolumeUp?.call();
        break;
      case 'volumeDown':
        _onVolumeDown?.call();
        break;
    }
  }
}
