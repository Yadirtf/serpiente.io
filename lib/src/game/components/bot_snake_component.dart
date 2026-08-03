import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/components/snake_component.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

/// Componente visual de una serpiente bot. Extiende `SnakeComponent`
/// y añade renderizado del nombre del bot sobre la cabeza.
///
/// La lógica de IA está en `BotController`, separada del renderizado.
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

  // El nombre se dibuja en SnakeGame overlay para no mezclar UI con canvas.
}

/// Datos de un bot activo en la sala offline.
class BotEntry {
  final String id;
  final String name;
  late BotSnakeComponent component;
  late dynamic controller; // BotController — tipado como dynamic para evitar import circular

  BotEntry({required this.id, required this.name, required SnakeSkin skin, required List<Vector2> initialSegments}) {
    component = BotSnakeComponent(
      name: name,
      skin: skin,
      initialSegments: initialSegments,
    );
  }
}
