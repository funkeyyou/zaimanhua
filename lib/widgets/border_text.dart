import 'package:flutter/material.dart';

class BorderText extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  final Color color;
  final double fontSize;
  final double strokeWidth;
  const BorderText(
    this.text, {
    this.textAlign = TextAlign.left,
    this.color = Colors.white,
    this.fontSize = 16,
    this.strokeWidth = 2.0,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Text(
          text,
          softWrap: false,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round
              ..color = getBorderColor(color),
          ),
        ),
        Text(
          text,
          softWrap: false,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            color: color,
          ),
        ),
      ],
    );
  }

  Color getBorderColor(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    var brightness = ((r * 299) + (g * 587) + (b * 114)) / 1000;
    return brightness > 70 ? Colors.black : Colors.white;
  }
}
