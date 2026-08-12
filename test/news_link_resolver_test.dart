import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/routes/news_link_resolver.dart';

void main() {
  group('NewsLinkResolver.resolve', () {
    test('uses the supplied HTTP URL', () {
      expect(
        NewsLinkResolver.resolve(
          url: ' https://news.zaimanhua.com/article/87553.html ',
          newsId: 87553,
        ),
        'https://news.zaimanhua.com/article/87553.html',
      );
    });

    test('builds an article URL when a homepage banner only has a news ID', () {
      expect(
        NewsLinkResolver.resolve(url: '', newsId: 87553),
        'https://v3api.zaimanhua.com/v3/article/show/87553.html',
      );
    });

    test('rejects an invalid URL when no news ID is available', () {
      expect(
        NewsLinkResolver.resolve(url: 'not-a-link', newsId: 0),
        isNull,
      );
    });
  });
}
