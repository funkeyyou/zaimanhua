import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/app/i18n.dart';

/// 首页板块标题由服务器下发，必须走转换。
void main() {
  setUp(() => AppI18n.useTraditional = true);
  tearDown(() => AppI18n.useTraditional = false);

  test('服务器下发的板块标题会转成繁体', () {
    expect("热门连载".i18n, "熱門連載");
    expect("国漫也精彩".i18n, "國漫也精彩");
    expect("火热专题".i18n, "火熱專題");
    expect("近期必看".i18n, "近期必看");
    expect("连载中".i18n, "連載中");
  });
}
