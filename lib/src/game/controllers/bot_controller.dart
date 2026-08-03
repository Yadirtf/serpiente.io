import 'dart:math';
import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/controllers/snake_controller.dart';

/// IA para serpientes bot en modo offline.
///
/// Comportamientos implementados:
/// 1. Navegación hacia orbes cercanos.
/// 2. Evasión de bordes del mapa.
/// 3. Evasión de colisión con cuerpos rivales.
/// 4. Boost táctico (aleatorio con cooldown).
///
/// La lógica está encapsulada aquí y es completamente independiente del
/// renderizado, lo que facilita sustituirla por decisiones del servidor en el
/// modo online futuro.
class BotController extends SnakeController {
  final String botName;
  final double mapSize;
  final _rng = Random();

  double _stateTimer = 0;
  double _boostCooldown = 0;
  _BotState _state = _BotState.roam;

  /// Target position (orb o punto de evasión) hacia donde navega el bot.
  Vector2? _targetPos;

  BotController({
    required this.botName,
    required this.mapSize,
    double initialAngle = 0,
  }) : super(
          speed: 120 + Random().nextDouble() * 30,
          initialAngle: initialAngle,
          maxTurnSpeed: 3.0 + Random().nextDouble() * 1.5,
        );

  /// Decide la siguiente acción del bot dado su estado y el entorno.
  ///
  /// [headPos]: posición actual de la cabeza del bot.
  /// [orbPositions]: posiciones de todos los orbes en el mapa.
  /// [rivalSegments]: lista de segmentos de TODOS los rivales (incluye player).
  void think({
    required Vector2 headPos,
    required List<Vector2> orbPositions,
    required List<Vector2> rivalSegments,
    required double dt,
  }) {
    _stateTimer += dt;
    if (_boostCooldown > 0) _boostCooldown -= dt;

    // ── Evasión de bordes (prioridad alta) ───────────────────────────────
    const edgeMargin = 80.0;
    final nearEdge = headPos.x < edgeMargin ||
        headPos.x > mapSize - edgeMargin ||
        headPos.y < edgeMargin ||
        headPos.y > mapSize - edgeMargin;

    if (nearEdge) {
      _state = _BotState.evadeEdge;
      _stateTimer = 0;
    }

    // ── Evasión de colisión rival (prioridad media) ────────────────────
    if (_state != _BotState.evadeEdge) {
      final danger = rivalSegments.any((seg) => seg.distanceTo(headPos) < 40);
      if (danger) {
        _state = _BotState.evadeRival;
        _stateTimer = 0;
      }
    }

    // ── Tiempo de estado agotado → transición ─────────────────────────
    if (_stateTimer > 2.0 && _state != _BotState.chase) {
      _state = _BotState.roam;
      _stateTimer = 0;
    }

    // ── Buscar orbe más cercano para cazar ───────────────────────────
    if (_state == _BotState.roam && orbPositions.isNotEmpty) {
      Vector2? closest;
      double minDist = double.infinity;
      for (final orb in orbPositions) {
        final d = orb.distanceTo(headPos);
        if (d < minDist) {
          minDist = d;
          closest = orb;
        }
      }
      if (closest != null && minDist < 200) {
        _state = _BotState.chase;
        _targetPos = closest;
      }
    }

    // ── Calcular ángulo según estado ─────────────────────────────────
    double angle = currentAngle;

    switch (_state) {
      case _BotState.chase:
        if (_targetPos != null) {
          final dir = _targetPos! - headPos;
          if (dir.length > 2) angle = atan2(dir.y, dir.x);
        }
        // Boost cuando está cerca del objetivo
        if (_targetPos != null &&
            _targetPos!.distanceTo(headPos) < 80 &&
            _boostCooldown <= 0) {
          setBoosting(true);
          _boostCooldown = 3.0;
          Future.delayed(const Duration(milliseconds: 600), () => setBoosting(false));
        }
        break;

      case _BotState.evadeEdge:
        // Girar hacia el centro del mapa
        final center = Vector2(mapSize / 2, mapSize / 2);
        final dir = center - headPos;
        angle = atan2(dir.y, dir.x);
        break;

      case _BotState.evadeRival:
        // Girar 90° a la derecha para esquivar
        angle = currentAngle + pi / 2;
        break;

      case _BotState.roam:
        // Pequeña variación aleatoria del ángulo
        if (_stateTimer > 0.8) {
          angle = currentAngle + (_rng.nextDouble() - 0.5) * 1.2;
          _stateTimer = 0;
        }
        break;
    }

    setTargetAngle(angle);
  }
}

enum _BotState { roam, chase, evadeEdge, evadeRival }
