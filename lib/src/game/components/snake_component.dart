import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/interfaces/input_source.dart';
import 'package:serpiente_io/src/game/logic/snake_logic.dart';
import 'package:serpiente_io/src/game/models/snake_model.dart';
import 'package:serpiente_io/src/game/renderers/snake_renderer.dart';

/// Componente principal de la Serpiente que orquesta el Modelo, la Lógica y el Renderizado.
/// Sigue la arquitectura propuesta: una entidad modular y desacoplada.
class SnakeComponent extends Component {
  final SnakeModel model;
  final SnakeLogic logic;
  final SnakeRenderer renderer;
  final InputSource input;

  SnakeComponent({
    required this.model,
    required this.logic,
    required this.renderer,
    required this.input,
  }) {
    // Añadimos el renderer como hijo para que se encargue del dibujo.
    add(renderer);
  }

  @override
  void update(double dt) {
    super.update(dt);

    // 1. Obtener entrada
    model.targetAngle = input.getAngle();
    model.isBoosting = input.isBoosting();

    // 2. Procesar lógica de movimiento
    logic.update(model, dt);
  }

  /// Expone los segmentos para sistemas externos (colisiones, etc.)
  List<Vector2> get segments => model.segments;

  /// Expone el radio de los segmentos
  double get segmentRadius => model.segmentRadius;
}
