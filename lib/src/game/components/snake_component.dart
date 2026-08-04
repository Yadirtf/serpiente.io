import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

/// Componente que renderiza una serpiente usando canvas directo para máximo
/// rendimiento. Dibuja el cuerpo como una polilínea gruesa con efecto glow
/// neon y la cabeza con un círculo brillante y ojos.
///
/// Extiende de [Component] (no de [PositionComponent]) porque maneja su propia
/// lista de segmentos en coordenadas absolutas de mundo.
class SnakeComponent extends Component {
  List<Vector2> segments;
  final double segmentRadius;
  final SnakeSkin skin;
  final bool isPlayer;

  late final Paint _glowPaint;
  late final Paint _bodyPaint;
  late final Paint _headPaint;
  late final Paint _eyePaint;
  late final Paint _headGlowPaint;

  SnakeComponent({
    required this.skin,
    required this.isPlayer,
    List<Vector2>? initialSegments,
    this.segmentRadius = 11,
  }) : segments = initialSegments == null
            ? []
            : initialSegments.map((s) => s.clone()).toList() {
    // Glow exterior (más grueso, semi-transparente)
    _glowPaint = Paint()
      ..color = skin.accentColor.withOpacity(0.25)
      ..strokeWidth = segmentRadius * 2 + 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Cuerpo principal
    _bodyPaint = Paint()
      ..shader = Gradient.linear(
        Offset.zero,
        const Offset(200, 0),
        [skin.gradientColors.first, skin.gradientColors.last],
      )
      ..strokeWidth = segmentRadius * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Cabeza
    _headPaint = Paint()
      ..color = skin.accentColor
      ..style = PaintingStyle.fill;

    // Ojos
    _eyePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    _headGlowPaint = Paint()
      ..color = skin.accentColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  }

  void updateSegments(List<Vector2> newSegments) {
    segments = newSegments;
  }

  @override
  void render(Canvas canvas) {
    if (segments.length < 2) return;

    final path = Path();
    path.moveTo(segments.first.x, segments.first.y);
    for (var i = 1; i < segments.length; i++) {
      path.lineTo(segments[i].x, segments[i].y);
    }

    // Dibujar glow
    canvas.drawPath(path, _glowPaint);

    // Dibujar cuerpo con gradiente dinámico desde cabeza hasta cola
    final head = segments.first;
    final tail = segments.last;
    _bodyPaint.shader = Gradient.linear(
      Offset(head.x, head.y),
      Offset(tail.x, tail.y),
      [skin.gradientColors.first, skin.gradientColors.last.withOpacity(0.6)],
    );
    canvas.drawPath(path, _bodyPaint);

    // ── Cabeza ──────────────────────────────────────────────────────────
    _drawHead(canvas, head);
  }

  void _drawHead(Canvas canvas, Vector2 head) {
    // Calcular ángulo de movimiento desde los primeros segmentos
    double angle = 0;
    if (segments.length >= 2) {
      final next = segments[1];
      angle = atan2(head.y - next.y, head.x - next.x);
    }

    canvas.save();
    canvas.translate(head.x, head.y);
    canvas.rotate(angle);

    // Glow de cabeza
    canvas.drawCircle(
      Offset.zero,
      segmentRadius + 5,
      _headGlowPaint,
    );

    // Cabeza principal
    canvas.drawCircle(Offset.zero, segmentRadius, _headPaint);

    // Ojos (relativos al ángulo de movimiento — siempre mirando hacia adelante)
    final eyeOffset = segmentRadius * 0.35;
    final eyeRadius = segmentRadius * 0.22;
    canvas.drawCircle(Offset(segmentRadius * 0.3, -eyeOffset), eyeRadius, _eyePaint);
    canvas.drawCircle(Offset(segmentRadius * 0.3, eyeOffset), eyeRadius, _eyePaint);

    // Brillo en los ojos
    canvas.drawCircle(
      Offset(segmentRadius * 0.3 + eyeRadius * 0.3, -eyeOffset - eyeRadius * 0.3),
      eyeRadius * 0.35,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(segmentRadius * 0.3 + eyeRadius * 0.3, eyeOffset - eyeRadius * 0.3),
      eyeRadius * 0.35,
      Paint()..color = Colors.white,
    );

    canvas.restore();
  }
}
