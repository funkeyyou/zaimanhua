import 'package:zai_x/models/comic/chapter_info.dart';

/// 上下滚动时同一条列表里的一话
class ReaderSegment {
  ReaderSegment({
    required this.chapterIndex,
    required this.detail,
    this.header = false,
  });

  /// 在章节列表里的位置
  final int chapterIndex;
  final ComicChapterDetail detail;

  /// 接在前一话后面时，开头放一条「第 N 话」分隔
  final bool header;

  int get itemCount => detail.pageUrls.length + (header ? 1 : 0);
}

/// 列表中某一项对应到哪一话的哪一页；[page] 为 -1 表示分隔条
class SegmentPosition {
  const SegmentPosition(this.segment, this.page);
  final int segment;
  final int page;
  bool get isHeader => page < 0;
}

/// 把多话的页面摊平成一条列表，并在「列表索引」与「第几话第几页」之间换算。
class ContinuousChapters {
  const ContinuousChapters(this.segments);

  final List<ReaderSegment> segments;

  int get itemCount =>
      segments.fold(0, (sum, segment) => sum + segment.itemCount);

  /// 第 [segment] 话第一项（含分隔条）在列表里的位置
  int startOf(int segment) {
    var start = 0;
    for (var i = 0; i < segment && i < segments.length; i++) {
      start += segments[i].itemCount;
    }
    return start;
  }

  /// 第 [segment] 话第 [page] 页在列表里的位置
  int indexOf(int segment, int page) {
    if (segment < 0 || segment >= segments.length) return 0;
    final s = segments[segment];
    final last = s.detail.pageUrls.isEmpty ? 0 : s.detail.pageUrls.length - 1;
    return startOf(segment) + (s.header ? 1 : 0) + page.clamp(0, last);
  }

  SegmentPosition? resolve(int index) {
    if (index < 0) return null;
    var start = 0;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (index < start + s.itemCount) {
        final offset = index - start;
        if (s.header) {
          return SegmentPosition(i, offset - 1);
        }
        return SegmentPosition(i, offset);
      }
      start += s.itemCount;
    }
    return null;
  }
}
