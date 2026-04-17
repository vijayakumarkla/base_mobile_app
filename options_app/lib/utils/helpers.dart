import 'package:flutter/material.dart';

String dateKey(DateTime d) =>
    "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

final List<Color> chartColors = [
  Colors.cyan,
  Colors.orange,
  Colors.green,
  Colors.pink,
  Colors.purple,
];
