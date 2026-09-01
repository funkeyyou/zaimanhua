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
    // UI 字面量快路径（整句 s2twp 品质）
    final hit = kZhHantPhraseMap[text];
    if (hit != null) return hit;
    // 通用转换：OpenCC 全量词表最长词优先，适用于服务器内容与插值字串
    final sb = StringBuffer();
    final n = text.length;
    int i = 0;
    while (i < n) {
      final cu = text.codeUnitAt(i);
      // 非 CJK 直接复制（HTML 标签、数字、英文等）
      if (cu < 0x2E80) {
        sb.writeCharCode(cu);
        i++;
        continue;
      }
      var matched = false;
      var maxLen = n - i;
      if (maxLen > kZhHantMaxKeyLen) maxLen = kZhHantMaxKeyLen;
      for (var l = maxLen; l >= 1; l--) {
        final v = kZhHantConvMap[text.substring(i, i + l)];
        if (v != null) {
          sb.write(v);
          i += l;
          matched = true;
          break;
        }
      }
      if (!matched) {
        sb.writeCharCode(cu);
        i++;
      }
    }
    return sb.toString();
  }
}
