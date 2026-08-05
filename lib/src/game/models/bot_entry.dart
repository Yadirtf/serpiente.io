import 'package:serpiente_io/src/game/components/bot_snake_component.dart';
import 'package:serpiente_io/src/game/input/bot_input.dart';
import 'package:serpiente_io/src/game/logic/snake_logic.dart';
import 'package:serpiente_io/src/game/models/snake_model.dart';

/// Datos de un bot activo en la sala.
class BotEntry {
  final String id;
  final String name;
  final BotSnakeComponent component;
  final BotInput input;
  final SnakeLogic logic;
  final SnakeModel model;

  BotEntry({
    required this.id,
    required this.name,
    required this.component,
    required this.input,
    required this.logic,
    required this.model,
  });
}
