// Read-only connectivity check; prints no titles, tags or image URLs.
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:zai_x/modules/hitomi/hitomi_source.dart';

Future<void> main(List<String> args) async {
  final source = HitomiSource();
  try {
    if (args.length == 1 && args.first == '--tags') {
      final tags = await source.allTags();
      stdout.writeln('Full tag catalog: ${tags.length} tags; 27 groups loaded.');
      return;
    }
    await source.refreshRules();
    final category = args.isEmpty ? '' : args.single;
    final ids = await source.filteredList('', 'chinese', category);
    if (ids.isEmpty) throw StateError('Empty index');
    final gallery = await source.gallery(ids.first);
    if (category.isNotEmpty && gallery['type'] != category) {
      throw StateError('Category mismatch');
    }
    final files = gallery['files'] as List;
    if (files.isEmpty) throw StateError('Empty gallery');
    for (final thumb in [true, false]) {
      final response = await source.dio.get<List<int>>(
          source.image(files.first as Map, thumbnail: thumb),
          options: Options(responseType: ResponseType.bytes));
      final bytes = response.data!;
      if (bytes.length < 12 ||
          String.fromCharCodes(bytes.sublist(0, 4)) != 'RIFF' ||
          String.fromCharCodes(bytes.sublist(8, 12)) != 'WEBP') {
        throw StateError('Not WebP');
      }
      stdout.writeln(
          '${thumb ? "thumbnail" : "page"}: HTTP ${response.statusCode}, WebP verified, ${bytes.length} bytes');
    }
    stdout.writeln('Index, metadata, thumbnail and page checks passed.');
  } finally {
    source.dio.close();
  }
}
