import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/models/proto/comic.pb.dart';

/// protobuf 6 需要重新生成 .pb.dart，这里用手工拼出的 wire 格式做回归：
/// 只要字段号与线上一致，解码结果就必须与旧生成码相同。
void main() {
  test('comic chapter payload decodes field by field', () {
    final payload = <int>[
      ..._varintField(1, 4207), // chapterId
      ..._varintField(2, 51537), // comicId
      ..._stringField(3, '第 12 話'),
      ..._varintField(4, 12), // chapterOrder
      ..._varintField(5, 1), // direction: 右到左
      ..._stringField(6, 'https://example.com/1.jpg'),
      ..._stringField(6, 'https://example.com/2.jpg'),
      ..._varintField(7, 2), // picnum
      ..._stringField(8, 'https://example.com/hd/1.jpg'),
      ..._varintField(9, 7), // commentCount
    ];

    final chapter = ComicChapterDetailProto.fromBuffer(payload);

    expect(chapter.chapterId.toInt(), 4207);
    expect(chapter.comicId.toInt(), 51537);
    expect(chapter.title, '第 12 話');
    expect(chapter.chapterOrder, 12);
    expect(chapter.direction, 1);
    expect(chapter.pageUrl, [
      'https://example.com/1.jpg',
      'https://example.com/2.jpg',
    ]);
    expect(chapter.picnum, 2);
    expect(chapter.pageUrlHD, ['https://example.com/hd/1.jpg']);
    expect(chapter.commentCount, 7);
  });

  test('re-encoding keeps the same bytes', () {
    final chapter = ComicChapterDetailProto.fromBuffer(<int>[
      ..._varintField(1, 4207),
      ..._stringField(3, 'Chapter'),
      ..._stringField(6, 'https://example.com/1.jpg'),
    ]);

    expect(chapter.writeToBuffer(), <int>[
      ..._varintField(1, 4207),
      ..._stringField(3, 'Chapter'),
      ..._stringField(6, 'https://example.com/1.jpg'),
    ]);
  });
}

List<int> _varint(int value) {
  final out = <int>[];
  var rest = value;
  while (rest > 0x7f) {
    out.add((rest & 0x7f) | 0x80);
    rest >>= 7;
  }
  out.add(rest);
  return out;
}

/// varint 字段：key = 字段号 << 3 | 0
List<int> _varintField(int field, int value) =>
    <int>[..._varint(field << 3), ..._varint(value)];

/// 长度前缀字段：key = 字段号 << 3 | 2
List<int> _stringField(int field, String value) {
  final data = utf8.encode(value);
  return <int>[
    ..._varint((field << 3) | 2),
    ..._varint(data.length),
    ...data,
  ];
}
