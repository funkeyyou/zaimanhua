import 'package:flutter/material.dart';

/// Keep both trees mounted when a foldable changes size or a detail opens.
class AdaptiveWorkspace extends StatelessWidget {
  const AdaptiveWorkspace({
    super.key,
    required this.primary,
    required this.detail,
    required this.showDetail,
  });

  final Widget primary;
  final Widget detail;
  final bool showDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final split = showDetail && constraints.maxWidth >= 1000;
      final primaryWidth = split
          ? (constraints.maxWidth * .38).clamp(360.0, 480.0)
          : constraints.maxWidth;
      return Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: primaryWidth,
            child: ExcludeFocus(
              excluding: showDetail && !split,
              child: ExcludeSemantics(
                excluding: showDetail && !split,
                child: TickerMode(
                  enabled: !showDetail || split,
                  child: primary,
                ),
              ),
            ),
          ),
          Positioned.fill(
            left: split ? primaryWidth : 0,
            child: Offstage(
              offstage: !showDetail,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: split
                      ? Border(
                          left:
                              BorderSide(color: Theme.of(context).dividerColor))
                      : null,
                ),
                child: detail,
              ),
            ),
          ),
        ],
      );
    });
  }
}
