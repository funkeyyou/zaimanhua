import 'dart:io';
import 'dart:ui';

import 'package:zai_x/app/i18n_dict.g.dart';

/// UI 简繁转换：
/// 源码字面量一律为简体；显示时依语言设置转换为繁体（台湾用语）。
/// 整句对照表由 tools/i18n/gen_dict.py 生成（OpenCC s2twp 品质）；
/// 插值组合出的字串走逐字备援表。
extension I18nString on String {
  String get i18n => AppI18n.convert(this);
}

class AppI18n {
  AppI18n._();

  /// 当前是否显示繁体
  static bool useTraditional = false;

  /// 语言设置
  /// * [0] 跟随系统
  /// * [1] 简体中文
  /// * [2] 繁体中文
  static void apply(int mode) {
    if (mode == 1) {
      useTraditional = false;
    } else if (mode == 2) {
      useTraditional = true;
    } else {
      useTraditional = _systemIsTraditional();
    }
  }

  static bool _systemIsTraditional() {
    try {
      final locale = PlatformDispatcher.instance.locale;
      if (locale.scriptCode == 'Hant') return true;
      const hantRegions = {'TW', 'HK', 'MO'};
      if (locale.languageCode == 'zh' &&
          hantRegions.contains(locale.countryCode)) {
        return true;
      }
      final name = Platform.localeName;
      if (name.startsWith('zh') &&
          (name.contains('Hant') ||
              hantRegions.any((r) => name.contains(r)))) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static String convert(String text) {
    if (!useTraditional || text.isEmpty) return text;
    final hit = kZhHantPhraseMap[text];
    if (hit != null) return hit;
    // 逐字备援：处理插值组合出的字串
    final sb = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      sb.write(kZhHantCharMap[ch] ?? ch);
    }
    return sb.toString();
  }
}
