import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/components/snake_component.dart';
import 'package:serpiente_io/src/game/controllers/bot_controller.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

/// Componente visual de una serpiente bot. Extiende `SnakeComponent`
/// y añade renderizado del nombre del bot sobre la cabeza.
class BotSnakeComponent extends SnakeComponent {
  final String name;

  BotSnakeComponent({
    required this.name,
    required super.skin,
    required List<Vector2> initialSegments,
    super.segmentRadius = 10,
  }) : super(
          isPlayer: false,
          initialSegments: initialSegments,
        );
}

/// Datos de un bot activo en la sala offline con tipado fuerte.
class BotEntry {
  final String id;
  final String name;
  late BotSnakeComponent component;
  late BotController controller;

  BotEntry({
    required this.id,
    required this.name,
    required SnakeSkin skin,
    required List<Vector2> initialSegments,
    required this.controller,
  }) {
    component = BotSnakeComponent(
      name: name,
      skin: skin,
      initialSegments: initialSegments,
    );
  }
}
