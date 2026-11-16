/// 条漫宽度模式（上下滚动阅读时生效）
class VerticalPageWidthMode {
  /// 铺满屏幕宽度
  static const int kFull = 0;

  /// 自动：直板手机铺满；方形折叠屏展开、平板、横屏时收窄到 9:16
  static const int kAuto = 1;

  /// 自定义：固定占屏宽的百分比
  static const int kCustom = 2;
}

/// 自定义宽度百分比的范围
const int kVerticalPageWidthMinPercent = 40;
const int kVerticalPageWidthMaxPercent = 100;

/// 自动模式下，屏幕宽高比达到这个值才开始收窄。
/// 直板手机约 0.45（9:20）～0.56（9:16），平板竖屏约 0.75，方形折叠屏展开约 0.83～0.9。
const double kVerticalPageAutoAspect = 0.7;

/// 计算上下滚动模式下图片的显示宽度。
///
/// 图片收窄后置中，两侧空白仍属于同一个滚动列表，在空白处滑动一样能翻页，
/// 这是与系统「16:9 显示」黑边最大的不同。
double verticalPageWidth({
  required double maxWidth,
  required double maxHeight,
  required int mode,
  required int percent,
}) {
  if (!maxWidth.isFinite || maxWidth <= 0) {
    return maxWidth;
  }
  switch (mode) {
    case VerticalPageWidthMode.kFull:
      return maxWidth;
    case VerticalPageWidthMode.kCustom:
      final p = percent
          .clamp(kVerticalPageWidthMinPercent, kVerticalPageWidthMaxPercent)
          .toDouble();
      return maxWidth * p / 100;
    default:
      if (!maxHeight.isFinite ||
          maxHeight <= 0 ||
          maxWidth / maxHeight < kVerticalPageAutoAspect) {
        return maxWidth;
      }
      final target = maxHeight * 9 / 16;
      return target
          .clamp(maxWidth * kVerticalPageWidthMinPercent / 100, maxWidth)
          .toDouble();
  }
}
