class AppConstant {
  /// 定義平板寬度，當大於此寬度時APP進入雙欄模式
  static const double kTabletWidth = 1000;

  /// 型別ID-漫畫
  static const int kTypeComic = 4;

  /// 型別ID-新聞
  static const int kTypeNews = 6;

  /// 型別ID-專題
  static const int kTypeSpecial = 2;

  /// 型別ID-輕小說
  static const int kTypeNovel = 1;
}

class ReaderDirection {
  /// 左右 0
  static const int kLeftToRight = 0;

  /// 上下 1
  static const int kUpToDown = 1;

  /// 右左 2
  static const int kRightToLeft = 2;
}
