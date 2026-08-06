import 'dart:math';
import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/interfaces/input_source.dart';

/// Implementación de entrada basada en IA para Bots.
/// Contiene la lógica de toma de decisiones (anteriormente en BotController).
class BotInput implements InputSource {
  final double mapSize;
  final _rng = Random();

  double _angle = 0.0;
  bool _isBoosting = false;

  double _stateTimer = 0;
  double _boostCooldown = 0;
  double _activeBoostTimer = 0;
  _BotState _state = _BotState.roam;
  Vector2? _targetPos;
  final List<Vector2> _priorityOrbPositions = [];

  BotInput({
    required this.mapSize,
    double initialAngle = 0,
  }) : _angle = initialAngle;

  @override
  double getAngle() => _angle;

  @override
  bool isBoosting() => _isBoosting;

  void notifyOrbDrop(List<Vector2> positions) {
    _priorityOrbPositions.addAll(positions.map((p) => p.clone()));
    if (_state != _BotState.evadeEdge && _state != _BotState.evadeRival) {
      _state = _BotState.collectDrop;
      _stateTimer = 0;
    }
  }

  void triggerBoost(double durationInSeconds) {
    _isBoosting = true;
    _activeBoostTimer = durationInSeconds;
  }

  /// Procesa la lógica de la IA.
  void think({
    required Vector2 headPos,
    required List<Vector2> orbPositions,
    required List<Vector2> rivalSegments,
    List<Vector2> rivalHeads = const [],
    List<double> rivalHeadAngles = const [],
    int mySegmentCount = 0,
    required double dt,
    required double currentAngle,
  }) {
    _stateTimer += dt;
    if (_boostCooldown > 0) _boostCooldown -= dt;

    if (_activeBoostTimer > 0) {
      _activeBoostTimer -= dt;
      if (_activeBoostTimer <= 0) {
        _isBoosting = false;
      }
    }

    // --- 1. Evasión Proactiva (Lookahead) ---
    const edgeMargin = 120.0;
    final nearEdge = headPos.x < edgeMargin ||
        headPos.x > mapSize - edgeMargin ||
        headPos.y < edgeMargin ||
        headPos.y > mapSize - edgeMargin;

    if (nearEdge) {
      _state = _BotState.evadeEdge;
      _stateTimer = 0;
    }

    if (_state != _BotState.evadeEdge) {
      // Verificación de colisión futura proyectando puntos adelante
      bool collisionImminent = false;
      const lookaheadSteps = 4;
      const stepSize = 25.0;

      for (int i = 1; i <= lookaheadSteps; i++) {
        final checkPos = headPos + Vector2(cos(currentAngle), sin(currentAngle)) * (i * stepSize);
        if (rivalSegments.any((seg) => seg.distanceTo(checkPos) < 40)) {
          collisionImminent = true;
          break;
        }
      }

      if (collisionImminent) {
        _state = _BotState.evadeRival;
        _stateTimer = 0;
        // Boost táctico de escape
        if (_boostCooldown <= 0 && mySegmentCount > 10) {
          triggerBoost(0.6);
          _boostCooldown = 2.0;
        }
      } else if (_state == _BotState.evadeRival && _stateTimer > 0.5) {
        _state = _BotState.roam;
      }
    }

    // --- 2. Transiciones de Estado ---

    if (_stateTimer > 2.5 &&
        _state != _BotState.evadeEdge &&
        _state != _BotState.evadeRival &&
        _state != _BotState.collectDrop) {
      _state = _BotState.roam;
      _stateTimer = 0;
    }

    // Recolección prioritaria de drops
    if (_priorityOrbPositions.isNotEmpty) {
      _priorityOrbPositions.removeWhere((p) => !orbPositions.any((o) => o.distanceTo(p) < 30));

      if (_priorityOrbPositions.isNotEmpty &&
          _state != _BotState.evadeEdge &&
          _state != _BotState.evadeRival) {
        _state = _BotState.collectDrop;
        _targetPos = _priorityOrbPositions.reduce((curr, next) =>
          curr.distanceToSquared(headPos) < next.distanceToSquared(headPos) ? curr : next);
      } else if (_priorityOrbPositions.isEmpty && _state == _BotState.collectDrop) {
        _state = _BotState.roam;
      }
    }

    // Ataque Predictivo (Interceptar)
    if (_state != _BotState.evadeEdge &&
        _state != _BotState.evadeRival &&
        _state != _BotState.collectDrop &&
        mySegmentCount > 12 &&
        rivalHeads.isNotEmpty) {

      int bestTargetIdx = -1;
      double minDist = double.infinity;

      for (int i = 0; i < rivalHeads.length; i++) {
        final d = rivalHeads[i].distanceTo(headPos);
        if (d < 250 && d < minDist) {
          minDist = d;
          bestTargetIdx = i;
        }
      }

      if (bestTargetIdx != -1) {
        _state = _BotState.intercept;
        final rh = rivalHeads[bestTargetIdx];
        final ra = (bestTargetIdx < rivalHeadAngles.length) ? rivalHeadAngles[bestTargetIdx] : 0.0;

        // Apuntar a un punto por delante del rival basándose en su dirección
        final leadDist = 80.0 + (minDist * 0.2);
        _targetPos = rh + Vector2(cos(ra), sin(ra)) * leadDist;
        _stateTimer = 0;
      }
    }

    // Persecución de orbes normales
    if (_state == _BotState.roam && orbPositions.isNotEmpty) {
      Vector2? closest;
      double minDist = 350.0;
      for (final orb in orbPositions) {
        final d = orb.distanceTo(headPos);
        if (d < minDist) {
          minDist = d;
          closest = orb;
        }
      }
      if (closest != null) {
        _state = _BotState.chase;
        _targetPos = closest.clone();
      }
    }

    // --- 3. Lógica de Dirección y Boost ---
    double nextAngle = currentAngle;

    switch (_state) {
      case _BotState.chase:
      case _BotState.collectDrop:
        if (_targetPos != null) {
          final dir = _targetPos! - headPos;
          if (dir.length > 2) nextAngle = atan2(dir.y, dir.x);

          if (_state == _BotState.collectDrop && _boostCooldown <= 0 && dir.length < 200) {
             triggerBoost(0.8);
             _boostCooldown = 2.0;
          }
        }
        break;

      case _BotState.intercept:
        if (_targetPos != null) {
          final dir = _targetPos! - headPos;
          if (dir.length > 2) nextAngle = atan2(dir.y, dir.x);

          if (dir.length < 150 && _boostCooldown <= 0) {
            triggerBoost(1.0);
            _boostCooldown = 3.0;
          }
        }
        break;

      case _BotState.evadeEdge:
        final center = Vector2(mapSize / 2, mapSize / 2);
        final dir = center - headPos;
        nextAngle = atan2(dir.y, dir.x);
        break;

      case _BotState.evadeRival:
        var repulsion = Vector2.zero();
        for (final seg in rivalSegments) {
          final d = seg.distanceTo(headPos);
          if (d < 85 && d > 0) {
            final diff = headPos - seg;
            diff.normalize();
            repulsion.add(diff * (85 - d));
          }
        }
        if (repulsion.length > 0.1) {
          nextAngle = atan2(repulsion.y, repulsion.x);
        } else {
          // Si no hay repulsión directa pero seguimos en estado de evasión,
          // intentamos ir hacia el centro para evitar quedar atrapados en bordes.
          final center = Vector2(mapSize / 2, mapSize / 2);
          final toCenter = center - headPos;
          nextAngle = atan2(toCenter.y, toCenter.x);

          // Salir del estado de evasión si el temporizador ha pasado un mínimo
          if (_stateTimer > 0.3) {
            _state = _BotState.roam;
            _stateTimer = 0;
          }
        }
        break;

      case _BotState.roam:
        if (_stateTimer > 0.8) {
          nextAngle = currentAngle + (_rng.nextDouble() - 0.5) * 1.5;
          _stateTimer = 0;
        }
        break;
      default:
        break;
    }

    _angle = nextAngle;
  }

}

enum _BotState { roam, chase, intercept, evadeEdge, evadeRival, collectDrop }
