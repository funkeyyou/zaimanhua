import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/routes/news_image_navigation_resolver.dart';

void main() {
  group('NewsImageNavigationResolver.resolve', () {
    const articleImage =
        'https://images.zaimanhua.com/resource/news/2026/08/12/article.jpg';

    test('opens an image collected from the article body', () {
      expect(
        NewsImageNavigationResolver.resolve(
          navigationUrl: 'dmzjimage://?src=$articleImage',
          articleImages: const [articleImage],
        ),
        articleImage,
      );
    });

    test('ignores MP3 player control images', () {
      expect(
        NewsImageNavigationResolver.resolve(
          navigationUrl: 'dmzjimage://?src=/static/audio/12.png',
          articleImages: const [articleImage],
        ),
        isNull,
      );
    });

    test('ignores malformed image navigation URLs', () {
      expect(
        NewsImageNavigationResolver.resolve(
          navigationUrl: 'dmzjimage://',
          articleImages: const [articleImage],
        ),
        isNull,
      );
    });
  });
}
