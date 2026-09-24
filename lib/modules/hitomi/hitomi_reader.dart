import 'package:get/get.dart';
import 'package:zai_x/models/comic/chapter_info.dart';
import 'package:zai_x/models/comic/detail_info.dart';
import 'package:zai_x/modules/comic/reader/comic_reader_controller.dart';
import 'package:zai_x/modules/comic/reader/comic_reader_page.dart';
import 'package:zai_x/modules/comic/reader/comic_reader_source.dart';
import 'hitomi_library.dart';
import 'hitomi_source.dart';
import 'hitomi_title.dart';

Future<void> openHitomiReader(
    Map gallery, HitomiSource source, HitomiLibrary library) async {
  final id = int.parse(gallery['id'].toString());
  final files = gallery['files'] as List;
  final title = hitomiTitle(gallery);
  final chapter = ComicDetailChapterItem(
      chapterId: id,
      chapterTitle: title,
      updateTime: 0,
      fileSize: 0,
      chapterOrder: 0);
  final favorite = library.favorite(gallery).obs;
  final adapter = ComicReaderSource(
    headers: HitomiSource.headers,
    preferencesNamespace: 'HitomiReaderPreferencesV1',
    readPage: () => library.page(gallery),
    writePage: (page) => library.save(gallery, page: page),
    favorite: favorite,
    toggleFavorite: () async {
      final value = !favorite.value;
      await library.save(gallery, favorite: value);
      favorite.value = value;
    },
    load: () async {
      await source.refreshRules(force: true);
      return ComicChapterDetail(
          chapterId: id,
          comicId: id,
          chapterOrder: 0,
          direction: 0,
          chapterTitle: title,
          pageUrls: files.map((f) => source.image(f as Map)).toList(),
          picnum: files.length,
          commentCount: 0);
    },
  );
  await Get.to(() => const ComicReaderPage(), binding: BindingsBuilder(() {
    Get.put(ComicReaderController(
        comicId: id,
        comicTitle: title,
        comicCover: '',
        chapters: [chapter],
        chapter: chapter,
        isLongComic: false,
        externalSource: adapter));
  }));
}
