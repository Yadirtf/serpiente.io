import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, Colors;

/// Orbe visual que aparece en el mapa. Tiene efecto glow neon y pulsa
/// suavemente para llamar la atención del jugador.
class OrbComponent extends PositionComponent {
  final Color color;
  final double radius;
  final int value;

  double _pulseTimer = 0;

  late final Paint _glowPaint;
  late final Paint _corePaint;

  OrbComponent({
    required Vector2 position,
    Color? color,
    this.radius = 7,
    this.value = 1,
  })  : color = color ?? _randomOrbColor(),
        super(
          position: position,
          size: Vector2.all(radius * 2 + 12),
          anchor: Anchor.center,
        ) {
    _glowPaint = Paint()
      ..color = this.color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..style = PaintingStyle.fill;

    _corePaint = Paint()
      ..color = this.color
      ..style = PaintingStyle.fill;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 0.85 + 0.15 * sin(_pulseTimer * 2.5);
    final r = radius * pulse;
    final center = Offset(size.x / 2, size.y / 2);

    // Glow exterior
    canvas.drawCircle(center, r + 6, _glowPaint);

    // Núcleo brillante
    canvas.drawCircle(center, r, _corePaint);

    // Brillo interior
    canvas.drawCircle(
      Offset(center.dx - r * 0.25, center.dy - r * 0.25),
      r * 0.3,
      Paint()..color = Colors.white.withOpacity(0.55),
    );
  }

  static Color _randomOrbColor() {
    const colors = [
      Color(0xFFFF6B6B),
      Color(0xFFFFD93D),
      Color(0xFF6BCB77),
      Color(0xFF4D96FF),
      Color(0xFFFF6BFF),
      Color(0xFF00FFEA),
      Color(0xFFFF9A3C),
    ];
    return colors[Random().nextInt(colors.length)];
  }
}
