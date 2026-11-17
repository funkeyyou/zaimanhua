import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/models/comic/chapter_info.dart';
import 'package:zai_x/modules/comic/reader/continuous_chapters.dart';

ComicChapterDetail chapter(int id, int pages, {bool tc = false}) =>
    ComicChapterDetail.empty()
      ..chapterId = id
      ..pageUrls = [
        for (var i = 0; i < pages; i++) 'u$id-$i',
        if (tc) 'TC',
      ];

void main() {
  test('单话时列表索引就是页码', () {
    final c = ContinuousChapters([
      ReaderSegment(chapterIndex: 3, detail: chapter(1, 5)),
    ]);
    expect(c.itemCount, 5);
    expect(c.indexOf(0, 4), 4);
    expect(c.resolve(2)!.page, 2);
    expect(c.resolve(5), isNull);
  });

  test('接上的话带分隔条，索引换算正确', () {
    final c = ContinuousChapters([
      ReaderSegment(chapterIndex: 3, detail: chapter(1, 5, tc: true)),
      ReaderSegment(chapterIndex: 4, detail: chapter(2, 3), header: true),
      ReaderSegment(chapterIndex: 5, detail: chapter(3, 2), header: true),
    ]);
    // 6 + (1+3) + (1+2)
    expect(c.itemCount, 13);
    expect(c.startOf(1), 6);
    expect(c.indexOf(1, 0), 7);
    expect(c.indexOf(2, 1), 12);

    final header = c.resolve(6)!;
    expect(header.segment, 1);
    expect(header.isHeader, isTrue);

    final page = c.resolve(9)!;
    expect(page.segment, 1);
    expect(page.page, 2);

    final tc = c.resolve(5)!;
    expect(tc.segment, 0);
    expect(tc.page, 5);
  });

  test('页码超出范围会夹住', () {
    final c = ContinuousChapters([
      ReaderSegment(chapterIndex: 0, detail: chapter(1, 3)),
    ]);
    expect(c.indexOf(0, 99), 2);
    expect(c.indexOf(0, -1), 0);
    expect(c.indexOf(5, 0), 0);
  });
}
