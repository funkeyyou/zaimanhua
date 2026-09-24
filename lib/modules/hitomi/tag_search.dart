/// Rank exact, prefix, substring, unordered words, then small spelling errors.
List<String> searchTags(List<String> tags, String query) {
  String normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[_\-:\s]+'), ' ').trim();
  final q = normalize(query);
  if (q.isEmpty) return tags;
  final words = q.split(' ');
  final ranked = <({String tag, int score})>[];
  for (final tag in tags) {
    final value = normalize(tag);
    int? score;
    if (value == q) {
      score = 0;
    } else if (value.startsWith(q)) {
      score = 1;
    } else if (value.contains(q)) {
      score = 2;
    } else if (words.every(value.contains)) {
      score = 3;
    } else if (q.length >= 4) {
      final limit = q.length >= 8 ? 2 : 1;
      for (final candidate in [value, ...value.split(' ')]) {
        if ((candidate.length - q.length).abs() > limit) continue;
        var row = List.generate(q.length + 1, (i) => i);
        for (var i = 0; i < candidate.length; i++) {
          final next = [i + 1];
          for (var j = 0; j < q.length; j++) {
            final a = next[j] + 1;
            final b = row[j + 1] + 1;
            final c = row[j] + (candidate[i] == q[j] ? 0 : 1);
            next.add([a, b, c].reduce((a, b) => a < b ? a : b));
          }
          row = next;
        }
        if (row.last <= limit) {
          score = 4 + row.last;
          break;
        }
      }
    }
    if (score != null) ranked.add((tag: tag, score: score));
  }
  ranked.sort((a, b) {
    final order = a.score.compareTo(b.score);
    return order != 0 ? order : a.tag.compareTo(b.tag);
  });
  return ranked.map((e) => e.tag).toList();
}
