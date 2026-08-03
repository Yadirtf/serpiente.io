import 'dart:math';
import 'dart:ui' show Offset;
import 'package:flame/components.dart';

/// Dirección continua a 360° expresada en radianes.
/// Reemplaza el antiguo enum de 4 direcciones cardinales.
class SnakeAngle {
  final double radians;

  const SnakeAngle(this.radians);

  factory SnakeAngle.right() => const SnakeAngle(0);
  factory SnakeAngle.left() => const SnakeAngle(pi);
  factory SnakeAngle.up() => const SnakeAngle(-pi / 2);
  factory SnakeAngle.down() => const SnakeAngle(pi / 2);

  factory SnakeAngle.fromOffset(Offset offset) {
    return SnakeAngle(atan2(offset.dy, offset.dx));
  }

  /// Convierte el ángulo a un vector unitario de movimiento.
  Vector2 toVector() => Vector2(cos(radians), sin(radians));

  /// Normaliza el ángulo al rango [-π, π].
  double get normalized {
    double a = radians % (2 * pi);
    if (a > pi) a -= 2 * pi;
    return a;
  }

  @override
  String toString() => 'SnakeAngle(${(radians * 180 / pi).toStringAsFixed(1)}°)';
}

/// Interpola angularmente entre dos ángulos tomando el camino más corto.
double lerpAngle(double from, double to, double t) {
  double diff = (to - from) % (2 * pi);
  if (diff > pi) diff -= 2 * pi;
  if (diff < -pi) diff += 2 * pi;
  return from + diff * t;
}
