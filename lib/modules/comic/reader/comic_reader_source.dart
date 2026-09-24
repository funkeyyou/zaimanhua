import 'package:get/get.dart';
import 'package:zai_x/models/comic/chapter_info.dart';

/// Non-Zaimanhua sources supply their own data and persistence boundaries.
class ComicReaderSource {
  ComicReaderSource(
      {required this.load,
      required this.readPage,
      required this.writePage,
      required this.headers,
      required this.preferencesNamespace,
      required this.favorite,
      required this.toggleFavorite});
  final Future<ComicChapterDetail> Function() load;
  final int Function() readPage;
  final Future<void> Function(int) writePage;
  final Map<String, String> headers;
  final String preferencesNamespace;
  final RxBool favorite;
  final Future<void> Function() toggleFavorite;
}
