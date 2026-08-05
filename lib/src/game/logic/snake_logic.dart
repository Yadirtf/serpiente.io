import 'dart:math';
import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/models/snake_model.dart';

/// Lógica pura para el movimiento y comportamiento de la serpiente.
/// Opera directamente sobre un [SnakeModel].
class SnakeLogic {
  static const double kSegmentDistance = 14.0;
  static const double kBoostMultiplier = 1.95;
  static const double kMaxTurnSpeed = 6.2;
  static const double kHistoryGranularity = 2.0;
  static const double kBoostMassInterval = 0.35;

  /// Actualiza el estado del modelo basado en el tiempo transcurrido.
  void update(SnakeModel model, double dt) {
    if (model.segments.isEmpty) return;

    // 1. Suavizar ángulo hacia el objetivo
    final angleDiff = _angleDiff(model.targetAngle, model.currentAngle);
    final maxDelta = kMaxTurnSpeed * dt;
    final step = angleDiff.clamp(-maxDelta, maxDelta);
    model.currentAngle = _normalizeAngle(model.currentAngle + step);

    // 2. Calcular velocidad efectiva
    double effectiveSpeed = model.speed;
    if (model.isBoosting && model.segments.length > model.minSegmentCount) {
      effectiveSpeed = model.speed * kBoostMultiplier;
      // Penalización ligera por boost si es necesario (según SnakeController original)
      effectiveSpeed = (effectiveSpeed - model.pendingMassDrop * 3.0).clamp(0.0, double.infinity);
    }

    // 3. Mover cabeza
    final head = model.segments.first.clone();
    final direction = Vector2(cos(model.currentAngle), sin(model.currentAngle));
    final frameDist = effectiveSpeed * dt;
    head.addScaled(direction, frameDist);

    // 4. Actualizar historial (Waypoint Trail)
    if (model.posHistory.isEmpty) {
      model.posHistory.add(head.clone());
    }

    model.sinceLastHistoryPoint += frameDist;
    if (model.sinceLastHistoryPoint >= kHistoryGranularity) {
      model.sinceLastHistoryPoint = 0;
      model.posHistory.add(head.clone());
    } else if (model.posHistory.isNotEmpty) {
      model.posHistory[model.posHistory.length - 1] = head.clone();
    }

    // 5. Posicionar segmentos siguiendo el trail
    final List<Vector2> nextSegments = [head];
    int historyIdx = model.posHistory.length - 1;
    double arcAccum = 0.0;

    for (var i = 1; i < model.segments.length; i++) {
      final targetArc = kSegmentDistance * i.toDouble();

      while (historyIdx > 0) {
        final a = model.posHistory[historyIdx];
        final b = model.posHistory[historyIdx - 1];
        final d = a.distanceTo(b);
        if (arcAccum + d >= targetArc) {
          final t = (targetArc - arcAccum) / (d == 0 ? 1 : d);
          nextSegments.add(Vector2(
            a.x + (b.x - a.x) * t,
            a.y + (b.y - a.y) * t,
          ));
          break;
        }
        arcAccum += d;
        historyIdx--;
      }

      if (nextSegments.length <= i) {
        nextSegments.add(model.posHistory.last.clone());
      }
    }

    model.segments = nextSegments;

    // 6. Podar historial
    final maxHistoryLen = ((model.segments.length * kSegmentDistance) / kHistoryGranularity).ceil() + 60;
    if (model.posHistory.length > maxHistoryLen) {
      model.posHistory.removeRange(0, model.posHistory.length - maxHistoryLen);
    }

    // 7. Consumo de masa en boost
    if (model.isBoosting && model.segments.length > model.minSegmentCount) {
      model.boostMassTimer += dt;
      while (model.boostMassTimer >= kBoostMassInterval && model.segments.length > model.minSegmentCount) {
        model.boostMassTimer -= kBoostMassInterval;
        model.segments.removeLast();
        model.pendingMassDrop++;
      }
    } else {
      model.boostMassTimer = 0;
    }
  }

  /// Inicializa el historial de posiciones.
  void resetHistory(SnakeModel model) {
    model.posHistory.clear();
    model.sinceLastHistoryPoint = 0;
    for (final seg in model.segments) {
      model.posHistory.add(seg.clone());
    }
  }

  double _angleDiff(double target, double current) {
    double diff = (target - current) % (2 * pi);
    if (diff > pi) diff -= 2 * pi;
    if (diff < -pi) diff += 2 * pi;
    return diff;
  }

  double _normalizeAngle(double a) {
    while (a > pi) a -= 2 * pi;
    while (a < -pi) a += 2 * pi;
    return a;
  }
}
