/// Resolves image-viewer navigation emitted by a news article WebView.
class NewsImageNavigationResolver {
  /// Returns the requested image only when it belongs to the article body.
  ///
  /// News pages attach `dmzjimage://` navigation to every `<img>` element.
  /// MP3 players also render their controls as images, so their clicks must not
  /// be treated as requests to open the article image viewer.
  static String? resolve({
    required String navigationUrl,
    required Iterable<String> articleImages,
  }) {
    final uri = Uri.tryParse(navigationUrl);
    if (uri?.scheme != 'dmzjimage') {
      return null;
    }

    final source = uri?.queryParameters['src'];
    if (source == null || source.isEmpty || !articleImages.contains(source)) {
      return null;
    }

    return source;
  }
}
