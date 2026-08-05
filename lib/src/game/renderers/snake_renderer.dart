import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:serpiente_io/src/game/models/snake_model.dart';

/// Encargado únicamente de dibujar el [SnakeModel] en el Canvas.
class SnakeRenderer extends Component {
  final SnakeModel model;

  late final Paint _glowPaint;
  late final Paint _bodyPaint;
  late final Paint _headPaint;
  late final Paint _eyePaint;
  late final Paint _headGlowPaint;

  SnakeRenderer(this.model) {
    _glowPaint = Paint()
      ..color = model.skin.accentColor.withOpacity(0.25)
      ..strokeWidth = model.segmentRadius * 2 + 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    _bodyPaint = Paint()
      ..strokeWidth = model.segmentRadius * 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _headPaint = Paint()
      ..color = model.skin.accentColor
      ..style = PaintingStyle.fill;

    _eyePaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    _headGlowPaint = Paint()
      ..color = model.skin.accentColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  }

  @override
  void render(Canvas canvas) {
    if (model.segments.length < 2) return;

    final path = Path();
    path.moveTo(model.segments.first.x, model.segments.first.y);
    for (var i = 1; i < model.segments.length; i++) {
      path.lineTo(model.segments[i].x, model.segments[i].y);
    }

    // Dibujar glow
    canvas.drawPath(path, _glowPaint);

    // Dibujar cuerpo con gradiente dinámico
    final head = model.segments.first;
    final tail = model.segments.last;
    _bodyPaint.shader = Gradient.linear(
      Offset(head.x, head.y),
      Offset(tail.x, tail.y),
      [model.skin.gradientColors.first, model.skin.gradientColors.last.withOpacity(0.6)],
    );
    canvas.drawPath(path, _bodyPaint);

    // Dibujar cabeza
    _drawHead(canvas, head);
  }

  void _drawHead(Canvas canvas, Vector2 head) {
    double angle = 0;
    if (model.segments.length >= 2) {
      final next = model.segments[1];
      angle = atan2(head.y - next.y, head.x - next.x);
    }

    canvas.save();
    canvas.translate(head.x, head.y);
    canvas.rotate(angle);

    canvas.drawCircle(Offset.zero, model.segmentRadius + 5, _headGlowPaint);
    canvas.drawCircle(Offset.zero, model.segmentRadius, _headPaint);

    final eyeOffset = model.segmentRadius * 0.35;
    final eyeRadius = model.segmentRadius * 0.22;
    canvas.drawCircle(Offset(model.segmentRadius * 0.3, -eyeOffset), eyeRadius, _eyePaint);
    canvas.drawCircle(Offset(model.segmentRadius * 0.3, eyeOffset), eyeRadius, _eyePaint);

    // Brillo ojos
    canvas.drawCircle(
      Offset(model.segmentRadius * 0.3 + eyeRadius * 0.3, -eyeOffset - eyeRadius * 0.3),
      eyeRadius * 0.35,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(model.segmentRadius * 0.3 + eyeRadius * 0.3, eyeOffset - eyeRadius * 0.3),
      eyeRadius * 0.35,
      Paint()..color = Colors.white,
    );

    canvas.restore();
  }
}
