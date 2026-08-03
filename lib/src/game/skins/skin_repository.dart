import 'package:flutter/material.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

class SkinRepository {
  final List<SnakeSkin> availableSkins = const [
    SnakeSkin(
      id: 'default',
      name: 'Clásico',
      gradientColors: [Color(0xFF22C55E), Color(0xFF16A34A)],
      accentColor: Color(0xFFE2E8F0),
    ),
    SnakeSkin(
      id: 'lava',
      name: 'Lava',
      gradientColors: [Color(0xFFFB7185), Color(0xFFF97316)],
      accentColor: Color(0xFFFDE68A),
    ),
    SnakeSkin(
      id: 'neon',
      name: 'Neón',
      gradientColors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
      accentColor: Color(0xFFAAFB8A),
    ),
  ];

  SnakeSkin get defaultSkin => availableSkins.first;

  SnakeSkin getSkinById(String id) {
    return availableSkins.firstWhere((skin) => skin.id == id, orElse: () => defaultSkin);
  }
}
