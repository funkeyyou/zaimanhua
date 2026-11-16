import 'package:flutter_test/flutter_test.dart';
import 'package:zai_x/modules/comic/reader/vertical_page_width.dart';

void main() {
  double auto(double w, double h) => verticalPageWidth(
      maxWidth: w,
      maxHeight: h,
      mode: VerticalPageWidthMode.kAuto,
      percent: 70);

  test('自动：直板手机保持铺满', () {
    expect(auto(412, 915), 412); // 9:20
    expect(auto(360, 640), 360); // 9:16
  });

  test('自动：方形折叠屏展开时收窄到 9:16', () {
    // Galaxy Z Fold 内屏竖握约 904×1080 dp（逻辑像素，扣掉状态栏前）
    expect(auto(904, 1080), closeTo(1080 * 9 / 16, 0.001));
    // 横握
    expect(auto(1080, 904), closeTo(904 * 9 / 16, 0.001));
  });

  test('自动：不会窄于屏宽 40%', () {
    expect(auto(2000, 800), 800);
  });

  test('铺满与自定义', () {
    expect(
        verticalPageWidth(
            maxWidth: 900,
            maxHeight: 1000,
            mode: VerticalPageWidthMode.kFull,
            percent: 50),
        900);
    expect(
        verticalPageWidth(
            maxWidth: 900,
            maxHeight: 1000,
            mode: VerticalPageWidthMode.kCustom,
            percent: 60),
        closeTo(540, 0.001));
    // 超出范围的百分比会夹在 40～100
    expect(
        verticalPageWidth(
            maxWidth: 900,
            maxHeight: 1000,
            mode: VerticalPageWidthMode.kCustom,
            percent: 10),
        closeTo(360, 0.001));
  });

  test('宽度无限或为 0 时原样返回', () {
    expect(auto(double.infinity, 800), double.infinity);
    expect(auto(0, 800), 0);
  });
}
