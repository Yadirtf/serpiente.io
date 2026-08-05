import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors, TextStyle, FontWeight, TextAlign;
import 'package:serpiente_io/src/game/components/snake_component.dart';

/// Extensión de SnakeComponent que añade una etiqueta con el nombre del bot.
class BotSnakeComponent extends SnakeComponent {
  final String name;
  late final TextComponent _nameTag;

  BotSnakeComponent({
    required this.name,
    required super.model,
    required super.logic,
    required super.renderer,
    required super.input,
  }) {
    _nameTag = TextComponent(
      text: name,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      anchor: Anchor.center,
    );
    add(_nameTag);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Posicionar el nombre sobre la cabeza de la serpiente
    if (model.segments.isNotEmpty) {
      final head = model.segments.first;
      _nameTag.position = Vector2(head.x, head.y - model.segmentRadius - 15);
    }
  }
}
