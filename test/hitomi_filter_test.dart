import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/modules/hitomi/hitomi_source.dart';

class _Source extends HitomiSource {
  final calls = <String>[];
  @override
  Future<List<int>> list(String query, String language) async {
    calls.add('$query|$language');
    return query.startsWith('type:') ? [3, 7, 1] : [9, 7, 4, 3, 1];
  }
}

void main() {
  test('category intersects all IDs before pagination without changing order',
      () async {
    final source = _Source();
    expect(await source.filteredList('sample', 'japanese', 'manga'), [7, 3, 1]);
    expect(source.calls, ['sample|japanese', 'type:manga|japanese']);
    source.dio.close();
  });
  test('category-only request avoids full global index and all resets category',
      () async {
    final source = _Source();
    expect(await source.filteredList('', 'chinese', 'doujinshi'), [3, 7, 1]);
    expect(source.calls, ['type:doujinshi|chinese']);
    expect(await source.filteredList('sample', 'all', ''), [9, 7, 4, 3, 1]);
    expect(source.calls.last, 'sample|all');
    source.dio.close();
  });
}
