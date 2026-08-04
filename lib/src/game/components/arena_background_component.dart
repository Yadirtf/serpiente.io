import 'dart:ui';
import 'package:flame/components.dart';

/// Componente que dibuja el fondo de la arena con cuadrícula neon
/// y borde rojo de peligro alrededor del mapa.
class ArenaBackgroundComponent extends PositionComponent {
  final double mapSize;

  ArenaBackgroundComponent({required this.mapSize})
      : super(
          position: Vector2.zero(),
          size: Vector2.all(mapSize),
        );

  final Paint _bgPaint = Paint()..color = const Color(0xFF0F1A2E);
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFFF2D55)
    ..strokeWidth = 8
    ..style = PaintingStyle.stroke;
  final Paint _gridPaint = Paint()
    ..color = const Color(0x1822C55E)
    ..strokeWidth = 1.2;

  @override
  void render(Canvas canvas) {
    // Fondo de la arena
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bgPaint);

    // Cuadrícula (grid lines)
    const step = 60.0;
    for (double x = 0; x <= size.x; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _gridPaint);
    }
    for (double y = 0; y <= size.y; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _gridPaint);
    }

    // Borde rojo exterior de peligro
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _borderPaint);
  }
}
