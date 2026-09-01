import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:remixicon/remixicon.dart';

/// 一個載入圖示會旋轉的載入按鈕。載入圖示（[Remix.refresh_line]）在左，文字（[text])在
/// 右。
///
/// 在點選widget時會在執行[onRefresh]函式的同時旋轉載入圖示。載入圖示會一直旋轉直到該函式
/// 返還。
///
/// 載入圖示會旋轉不小於1秒的時間，即如果[onRefresh]函式在1秒之內執行完畢，載入圖示會繼續旋
/// 轉直到距離onRefresh函式開始執行已經過了1秒。
class RefreshUntilWidget extends StatefulWidget {
  final Future Function() onRefresh;
  final String text;

  const RefreshUntilWidget({
    super.key,
    required this.onRefresh,
    required this.text,
  });

  @override
  State<RefreshUntilWidget> createState() => _RefreshUntilWidgetState();
}

class _RefreshUntilWidgetState extends State<RefreshUntilWidget>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(seconds: 1),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.linear,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        _controller.repeat();
        // 確保在網路很好的情況下，動畫不會太快結束（至少1秒）
        await Future.wait([
          widget.onRefresh(),
          Future.delayed(const Duration(seconds: 1)),
        ]);
        _controller.stop(canceled: false);
      },
      child: Row(
        children: [
          RotationTransition(
            turns: _animation,
            child: const Icon(Remix.refresh_line, size: 18, color: Colors.grey),
          ),
          AppStyle.hGap4,
          Text(
            widget.text,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
