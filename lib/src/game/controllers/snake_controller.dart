import 'dart:math';
import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/models/snake_direction.dart';

/// Controla el movimiento de una serpiente con ángulo continuo de 360°,
/// suavizado de giro por inercia y boost con consumo de masa.
///
/// Diseñado para ser usado tanto por el jugador como por los bots,
/// lo que permite escalar hacia un modo multijugador online en el futuro.
class SnakeController {
  /// Velocidad base de la serpiente (px/seg).
  final double speed;

  /// Distancia inter-segmento para el trail del cuerpo.
  final double segmentDistance;

  /// Multiplicador de velocidad al hacer boost.
  final double boostMultiplier;

  /// Velocidad máxima de giro en radianes/segundo.
  /// Cuanto menor, más largo el radio de giro (inercia más real).
  final double maxTurnSpeed;

  /// Ángulo objetivo (donde apunta el joystick / la IA).
  double _targetAngle;

  /// Ángulo actual suavizado (lo que realmente usa la serpiente).
  double _currentAngle;

  /// Si se está aplicando boost actualmente.
  bool isBoosting;

  /// Segmentos eliminados pendientes de convertir en orbes (para consumo de masa).
  int _pendingMassDrop = 0;

  SnakeController({
    this.speed = 140,
    this.segmentDistance = 14,
    this.boostMultiplier = 1.9,
    this.maxTurnSpeed = 4.5, // rad/s — ajusta la "agilidad"
    double initialAngle = 0,
    this.isBoosting = false,
  })  : _targetAngle = initialAngle,
        _currentAngle = initialAngle;

  /// Ángulo actual de movimiento de la serpiente.
  double get currentAngle => _currentAngle;

  /// Establece el ángulo objetivo (desde joystick o IA).
  void setTargetAngle(double angle) {
    _targetAngle = angle;
  }

  /// Activa o desactiva el boost.
  void setBoosting(bool value) {
    isBoosting = value;
  }

  /// Devuelve y resetea los segmentos pendientes de convertir en orbes.
  int consumePendingMassDrop() {
    final n = _pendingMassDrop;
    _pendingMassDrop = 0;
    return n;
  }

  /// Actualiza el ángulo actual acercándolo al objetivo respetando la
  /// velocidad de giro máxima. Retorna los segmentos actualizados.
  List<Vector2> move(List<Vector2> segments, double dt) {
    if (segments.isEmpty) return segments;

    // ── 1. Suavizar ángulo hacia el objetivo ───────────────────────────────
    final angleDiff = _angleDiff(_targetAngle, _currentAngle);
    final maxDelta = maxTurnSpeed * dt;
    final step = angleDiff.clamp(-maxDelta, maxDelta);
    _currentAngle = _normalizeAngle(_currentAngle + step);

    // ── 2. Calcular velocidad ───────────────────────────────────────────────
    final effectiveSpeed = isBoosting ? speed * boostMultiplier : speed;

    // ── 3. Mover cabeza en la dirección actual ─────────────────────────────
    final head = segments.first.clone();
    final direction = Vector2(cos(_currentAngle), sin(_currentAngle));
    head.addScaled(direction, effectiveSpeed * dt);

    // ── 4. Actualizar cadena de segmentos (trail system) ──────────────────
    final List<Vector2> next = [head];
    for (var i = 1; i < segments.length; i++) {
      final prev = next[i - 1];
      final cur = segments[i].clone();
      final separation = prev - cur;
      final dist = separation.length;
      if (dist > segmentDistance) {
        cur.setFrom(prev - separation.normalized() * segmentDistance);
      }
      next.add(cur);
    }

    // ── 5. Consumo de masa durante boost ──────────────────────────────────
    // Cada 0.35 segundos de boost se elimina 1 segmento de la cola.
    if (isBoosting && next.length > 6) {
      _boostMassTimer += dt;
      if (_boostMassTimer >= _kBoostMassInterval) {
        _boostMassTimer = 0;
        next.removeLast();
        _pendingMassDrop++;
      }
    } else {
      _boostMassTimer = 0;
    }

    return next;
  }

  // ── Privados ───────────────────────────────────────────────────────────────
  double _boostMassTimer = 0;
  static const double _kBoostMassInterval = 0.35;

  /// Diferencia angular mínima entre [target] y [current] en [-π, π].
  static double _angleDiff(double target, double current) {
    double diff = (target - current) % (2 * pi);
    if (diff > pi) diff -= 2 * pi;
    if (diff < -pi) diff += 2 * pi;
    return diff;
  }

  /// Normaliza un ángulo al rango [-π, π].
  static double _normalizeAngle(double a) {
    while (a > pi) a -= 2 * pi;
    while (a < -pi) a += 2 * pi;
    return a;
  }
}
