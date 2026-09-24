int hitomiColumns(double width) => (width / 145).floor().clamp(2, 10);

int hitomiBatchEnd(int offset, int total, int columns,
    {bool fillRowOnly = false}) {
  final target = fillRowOnly ? offset : offset + 18;
  return (((target + columns - 1) ~/ columns) * columns).clamp(0, total);
}
