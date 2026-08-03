import 'package:flutter/material.dart';

class SnakeSkin {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Color accentColor;

  const SnakeSkin({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.accentColor,
  });
}
