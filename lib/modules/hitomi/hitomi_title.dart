import 'package:zai_x/app/i18n.dart';

/// Use gallery language, so saved books retain their title across filters.
String hitomiTitle(Map gallery) {
  String value(String key) =>
      gallery[key] is String ? (gallery[key] as String).trim() : '';
  final language = value('language').toLowerCase();
  final original = value('japanese_title');
  final title = value('title');
  if (language == 'japanese' && original.isNotEmpty) {
    return original;
  }
  final resolved = title.isNotEmpty ? title : original;
  // Chinese titles follow the interface language like other server content.
  // Japanese titles stay untouched so their kanji are not rewritten.
  return language == 'chinese' ? resolved.i18n : resolved;
}
