import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// 上下滚动阅读用的双指缩放。
///
/// 整条列表一起放大，放大后单指上下照常滚动（交给底下的列表），
/// 左右拖动平移画面；双指缩放时暂停列表滚动，避免边捏边跑。
/// 只用原始指针事件，不进手势竞技场，所以不会抢走点按翻页与呼出菜单。
class VerticalZoomView extends StatefulWidget {
  const VerticalZoomView({
    super.key,
    required this.builder,
    this.maxScale = 4,
  });

  /// [scrollLocked] 为 true 时列表应停止滚动（双指缩放中）
  final Widget Function(BuildContext context, bool scrollLocked) builder;
  final double maxScale;

  @override
  State<VerticalZoomView> createState() => _VerticalZoomViewState();
}

class _VerticalZoomViewState extends State<VerticalZoomView> {
  final _pointers = <int, Offset>{};
  double _scale = 1;
  Offset _offset = Offset.zero;
  Size _size = Size.zero;

  // 双指开始时的状态
  double _startScale = 1;
  Offset _startOffset = Offset.zero;
  Offset _startFocal = Offset.zero;
  double _startSpan = 0;
  bool _pinching = false;

  Offset _focal() {
    final points = _pointers.values.take(2).toList();
    return (points[0] + points[1]) / 2;
  }

  double _span() {
    final points = _pointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _beginPinch() {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = _focal();
    _startSpan = math.max(_span(), 1);
    if (!_pinching) setState(() => _pinching = true);
  }

  /// 以 [focal] 为中心缩放到 [scale]，并把画面夹在可视范围内
  void _apply(double scale, Offset startFocal, Offset focal) {
    scale = scale.clamp(1.0, widget.maxScale).toDouble();
    // 起始时手指下的内容点，缩放后仍要留在手指下
    final content = (startFocal - _startOffset) / _startScale;
    var offset = focal - content * scale;
    setState(() {
      _scale = scale;
      _offset = _clamp(offset, scale);
    });
  }

  Offset _clamp(Offset offset, double scale) {
    final minX = _size.width - _size.width * scale;
    final minY = _size.height - _size.height * scale;
    return Offset(
      offset.dx.clamp(minX, 0.0).toDouble(),
      offset.dy.clamp(minY, 0.0).toDouble(),
    );
  }

  void _onDown(PointerDownEvent e) {
    if (e.kind != PointerDeviceKind.touch &&
        e.kind != PointerDeviceKind.stylus) {
      return;
    }
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 2) _beginPinch();
  }

  void _onMove(PointerMoveEvent e) {
    final last = _pointers[e.pointer];
    if (last == null) return;
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length >= 2) {
      _apply(_startScale * _span() / _startSpan, _startFocal, _focal());
    } else if (_scale > 1) {
      // 放大后单指左右平移；上下交给列表滚动
      final dx = e.localPosition.dx - last.dx;
      setState(() => _offset = _clamp(_offset.translate(dx, 0), _scale));
    }
  }

  void _onUp(PointerEvent e) {
    if (_pointers.remove(e.pointer) == null) return;
    if (_pointers.length == 2) {
      _beginPinch();
    } else if (_pointers.length < 2 && _pinching) {
      setState(() {
        _pinching = false;
        // 几乎没放大就当作还原，免得留下一点点偏移
        if (_scale < 1.05) {
          _scale = 1;
          _offset = Offset.zero;
        }
      });
    }
  }

  // 触控板双指缩放（Windows 精确式触控板、Mac）
  void _onPanZoomStart(PointerPanZoomStartEvent e) {
    _startScale = _scale;
    _startOffset = _offset;
    _startFocal = e.localPosition;
  }

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent e) {
    if ((e.scale - 1).abs() < 0.01) return;
    _apply(_startScale * e.scale, _startFocal, _startFocal);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      if (size != _size) {
        _size = size;
        _offset = _clamp(_offset, _scale);
      }
      return Listener(
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onUp,
        onPointerPanZoomStart: _onPanZoomStart,
        onPointerPanZoomUpdate: _onPanZoomUpdate,
        child: ClipRect(
          child: Transform(
            transform: Matrix4.identity()
              ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
              ..scaleByDouble(_scale, _scale, 1, 1),
            child: widget.builder(context, _pinching),
          ),
        ),
      );
    });
  }
}
