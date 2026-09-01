import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// 「关于APP」弹窗底部的两个按钮由 Material 内建文案提供，
/// 需要 locale 切到 zh-TW 才会显示繁体。
void main() {
  test('zh-TW 的 Material 内建文案是繁体', () async {
    final tw = await GlobalMaterialLocalizations.delegate
        .load(const Locale('zh', 'TW'));
    final cn = await GlobalMaterialLocalizations.delegate
        .load(const Locale('zh', 'CN'));

    expect(tw.closeButtonLabel, isNot(cn.closeButtonLabel));
    expect(tw.viewLicensesButtonLabel, isNot(cn.viewLicensesButtonLabel));
    expect(tw.closeButtonLabel, '關閉');
  });
}
