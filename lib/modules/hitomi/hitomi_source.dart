import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;

class HitomiSource {
  static const categories = {
    '': '全部分类',
    'manga': '漫画',
    'doujinshi': '同人志',
    'artistcg': '画师 CG',
    'gamecg': '游戏 CG',
    'imageset': '图集',
  };

  Future<List<int>> filteredList(String query, String language, String category,
      {List<String> tags = const []}) async {
    if (!categories.containsKey(category)) throw ArgumentError.value(category);
    if (tags.isNotEmpty) {
      final terms = [
        if (query.trim().isNotEmpty) query,
        if (category.isNotEmpty) 'type:$category',
        ...tags.toSet().map((t) => 'tag:$t')
      ];
      List<int>? result;
      for (final term in terms) {
        final ids = await list(term, language);
        if (result == null) {
          result = ids;
        } else {
          final allowed = ids.toSet();
          result = result.where(allowed.contains).toList();
        }
        if (result.isEmpty) break;
      }
      return result ?? [];
    }
    if (category.isEmpty) return list(query, language);
    if (query.trim().isEmpty) return list('type:$category', language);
    final results = await Future.wait(
        [list(query, language), list('type:$category', language)]);
    final allowed = results[1].toSet();
    return results[0].where(allowed.contains).toList();
  }

  static const host = 'ltn.gold-usergeneratedcontent.net';
  final _tagCache = <String, List<String>>{};
  Future<List<String>>? _allTags;
  Future<List<String>> allTags() => _allTags ??= _loadAllTags();
  Future<List<String>> _loadAllTags() async {
    try {
      final letters = ['123', ...'abcdefghijklmnopqrstuvwxyz'.split('')];
      final result = <String>{};
      for (var i = 0; i < letters.length; i += 3) {
        final batches = await Future.wait(letters.skip(i).take(3).map(tags));
        for (final batch in batches) {
          result.addAll(batch);
        }
      }
      return result.toList()..sort();
    } catch (_) {
      _allTags = null;
      rethrow;
    }
  }

  Future<List<String>> tags(String letter) async {
    if (!RegExp(r'^(?:[a-z]|123)$').hasMatch(letter)) {
      throw ArgumentError.value(letter);
    }
    if (_tagCache.containsKey(letter)) return _tagCache[letter]!;
    final page =
        (await dio.get<String>('https://hitomi.la/alltags-$letter.html')).data!;
    final values = parseTags(page);
    if (values.isEmpty) throw const FormatException('Empty tag catalog');
    return _tagCache[letter] = values;
  }

  static List<String> parseTags(String page) {
    final values = <String>{};
    for (final node in html.parse(page).querySelectorAll('a[href]')) {
      final uri = Uri.tryParse(node.attributes['href']!);
      if (uri == null || (uri.hasAuthority && uri.host != 'hitomi.la')) {
        continue;
      }
      final parts = uri.pathSegments;
      if (parts.length != 2 ||
          parts[0] != 'tag' ||
          !parts[1].endsWith('-all.html')) {
        continue;
      }
      final tag = parts[1].substring(0, parts[1].length - '-all.html'.length);
      if (tag.isNotEmpty) values.add(tag);
    }
    return values.toList()..sort();
  }

  static const headers = {'Referer': 'https://hitomi.la/'};
  final Dio dio = Dio(BaseOptions(
    headers: headers,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));
  String? _base;
  int _defaultShard = 0;
  int _otherShard = 1;
  Set<int> _shards = {};
  DateTime? _rulesAt;

  Future<void> refreshRules({bool force = false}) async {
    if (!force &&
        _rulesAt != null &&
        DateTime.now().difference(_rulesAt!).inMinutes < 10) {
      return;
    }
    final js = (await dio.get<String>('https://$host/gg.js')).data!;
    final base = RegExp(r"b:\s*'([0-9]+/)'").firstMatch(js);
    final initial = RegExp(r'var o\s*=\s*([01])').firstMatch(js);
    final alternate = RegExp(r'o\s*=\s*([01]);\s*break').firstMatch(js);
    if (base == null || initial == null || alternate == null) {
      throw const FormatException('Image rules changed');
    }
    _base = base[1];
    _defaultShard = int.parse(initial[1]!);
    _otherShard = int.parse(alternate[1]!);
    _shards = RegExp(r'case (\d+):')
        .allMatches(js)
        .map((m) => int.parse(m[1]!))
        .toSet();
    _rulesAt = DateTime.now();
  }

  String image(Map file, {bool thumbnail = false}) {
    final hash = file['hash'] as String;
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
        (!thumbnail && _base == null)) {
      throw const FormatException('Invalid image metadata');
    }
    final tail = hash.substring(61, 63);
    final last = hash.substring(63);
    final number = int.parse('$last$tail', radix: 16);
    final shard = _shards.contains(number) ? _otherShard : _defaultShard;
    if (thumbnail) {
      return 'https://${String.fromCharCode(97 + shard)}tn.gold-usergeneratedcontent.net/webpbigtn/$last/$tail/$hash.webp';
    }
    return 'https://w${shard + 1}.gold-usergeneratedcontent.net/$_base$number/$hash.webp';
  }

  Future<Map<String, dynamic>> gallery(int id) async {
    final data =
        (await dio.get<String>('https://$host/galleries/$id.js')).data!;
    final start = data.indexOf('{');
    final end = data.lastIndexOf('}');
    if (start < 0 || end < start) {
      throw const FormatException('Invalid gallery');
    }
    return Map<String, dynamic>.from(
        jsonDecode(data.substring(start, end + 1)) as Map);
  }

  Future<List<int>> list(String query, String language) async {
    query = query.trim();
    final link = Uri.tryParse(query);
    if (link != null && link.host == 'hitomi.la') {
      final match = RegExp(r'(\d+)\.html$').firstMatch(link.path);
      if (match != null) return [int.parse(match[1]!)];
    }
    if (RegExp(r'^\d+$').hasMatch(query)) return [int.parse(query)];
    var area = 'tag';
    var tag = query;
    if (query.contains(':')) {
      final parts = query.split(':');
      if (['tag', 'artist', 'group', 'series', 'character', 'type']
          .contains(parts.first)) {
        area = parts.first;
        tag = query.substring(area.length + 1);
      }
    }
    final path = query.isEmpty
        ? 'index-$language.nozomi'
        : '$area/${Uri.encodeComponent(tag)}-$language.nozomi';
    try {
      final response = await dio.get<List<int>>('https://$host/n/$path',
          options: Options(responseType: ResponseType.bytes));
      return decodeIds(response.data!);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return [];
      rethrow;
    }
  }

  static List<int> decodeIds(List<int> bytes) {
    if (bytes.length % 4 != 0) throw const FormatException('Invalid index');
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    return List.generate(bytes.length ~/ 4, (i) => data.getUint32(i * 4));
  }
}
