import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/modules/hitomi/tag_search.dart';

void main() {
  test('ranks exact before prefix and substring independent of letter', () {
    expect(searchTags(['zebra art', 'artwork', 'art', 'smart'], 'ART'),
        ['art', 'artwork', 'smart', 'zebra art']);
  });
  test('normalizes separators, supports unordered words and typo', () {
    expect(searchTags(['blue_hair', 'red hair'], 'hair blue'), ['blue_hair']);
    expect(searchTags(['female:glasses', 'blue hair'], 'glases'),
        ['female:glasses']);
    expect(searchTags(['abc', 'xyz'], 'a'), ['abc']);
  });
}
