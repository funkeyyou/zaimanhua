import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Recognizes a normal page-turn gesture that starts at a chapter boundary.
/// Observes pointers without competing with image zoom or the page view.
class ChapterSwipeBoundary extends StatefulWidget {
  const ChapterSwipeBoundary({
    super.key,
    required this.child,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    this.reverse = false,
    this.enabled = true,
  });

  final Widget child;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool reverse;
  final bool enabled;

  @override
  State<ChapterSwipeBoundary> createState() => _ChapterSwipeBoundaryState();
}

class _ChapterSwipeBoundaryState extends State<ChapterSwipeBoundary> {
  final Set<int> _pointers = {};
  VelocityTracker? _velocity;
  Offset? _start;
  bool _previous = false;
  bool _next = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        _pointers.add(event.pointer);
        if (_pointers.length != 1 || !widget.enabled) {
          _start = null;
          return;
        }
        _start = event.position;
        _previous = widget.canGoPrevious;
        _next = widget.canGoNext;
        _velocity = VelocityTracker.withKind(event.kind)
          ..addPosition(event.timeStamp, event.position);
      },
      onPointerMove: (event) {
        _velocity?.addPosition(event.timeStamp, event.position);
      },
      onPointerCancel: (event) {
        _pointers.remove(event.pointer);
        _start = null;
      },
      onPointerUp: (event) {
        _pointers.remove(event.pointer);
        final start = _start;
        _start = null;
        if (start == null || !widget.enabled) return;
        _velocity?.addPosition(event.timeStamp, event.position);
        final delta = event.position - start;
        if (delta.dx.abs() <= kTouchSlop || delta.dx.abs() <= delta.dy.abs()) {
          return;
        }
        final speed = _velocity?.getVelocity().pixelsPerSecond.dx ?? 0;
        final width = context.size?.width ?? double.infinity;
        final fling =
            speed.abs() >= kMinFlingVelocity && speed.sign == delta.dx.sign;
        if (!fling && delta.dx.abs() <= width / 2) return;
        final next = widget.reverse ? delta.dx > 0 : delta.dx < 0;
        if (next && _next && widget.canGoNext) widget.onNext();
        if (!next && _previous && widget.canGoPrevious) widget.onPrevious();
      },
      child: widget.child,
    );
  }
}
