import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/app/i18n.dart';
import 'package:zai_x/modules/hitomi/hitomi_title.dart';

void main() {
  tearDown(() => AppI18n.useTraditional = false);
  test('Japanese galleries use Japanese name including stored metadata', () {
    expect(
        hitomiTitle({
          'language': 'japanese',
          'title': 'Romaji',
          'japanese_title': ' 日本語の題名 '
        }),
        '日本語の題名');
  });
  test('translated galleries keep translated titles', () {
    expect(
        hitomiTitle({
          'language': 'chinese',
          'title': '中文標題',
          'japanese_title': '日本語の題名'
        }),
        '中文標題');
    expect(
        hitomiTitle({
          'language': 'english',
          'title': 'English',
          'japanese_title': '日本語の題名'
        }),
        'English');
  });
  test('missing or blank Japanese name falls back without null strings', () {
    expect(
        hitomiTitle({
          'language': 'japanese',
          'title': 'Original',
          'japanese_title': ' '
        }),
        'Original');
    expect(
        hitomiTitle({'language': 'japanese', 'title': 'Original'}), 'Original');
    expect(hitomiTitle({'title': null, 'japanese_title': '原名'}), '原名');
    expect(hitomiTitle({}), '');
  });
  test('Chinese titles follow the interface language, Japanese ones do not',
      () {
    const chinese = {'language': 'chinese', 'title': '国王与爱人'};
    const japanese = {'language': 'japanese', 'japanese_title': '国のはなし'};
    expect(hitomiTitle(chinese), '国王与爱人');
    AppI18n.useTraditional = true;
    expect(hitomiTitle(chinese), '國王與愛人');
    expect(hitomiTitle(japanese), '国のはなし');
  });
}
