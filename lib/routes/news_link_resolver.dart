class NewsLinkResolver {
  static const String _articleBaseUrl =
      'https://v3api.zaimanhua.com/v3/article/show';

  /// Resolves a news link returned by the API.
  ///
  /// Homepage recommendations may identify news items only by [newsId] and
  /// return an empty URL. In that case, build the article URL from the ID.
  static String? resolve({required String url, required int newsId}) {
    final normalizedUrl = url.trim();
    final uri = Uri.tryParse(normalizedUrl);
    if (uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      return normalizedUrl;
    }

    if (newsId > 0) {
      return '$_articleBaseUrl/$newsId.html';
    }

    return null;
  }
}
