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

    // Evasión de bordes
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
      final danger = rivalSegments.any((seg) => seg.distanceTo(headPos) < 45);
      if (danger) {
        _state = _BotState.evadeRival;
        _stateTimer = 0;
      }
    }

    if (_stateTimer > 2.0 &&
        _state != _BotState.chase &&
        _state != _BotState.intercept &&
        _state != _BotState.collectDrop) {
      _state = _BotState.roam;
      _stateTimer = 0;
    }

    if (_state == _BotState.collectDrop) {
      _priorityOrbPositions.removeWhere((p) => !orbPositions.any((o) => o.distanceTo(p) < 25));
      if (_priorityOrbPositions.isEmpty) {
        _state = _BotState.roam;
        _stateTimer = 0;
      }
    }

    // Intercept
    if (_state != _BotState.evadeEdge &&
        _state != _BotState.evadeRival &&
        mySegmentCount > 15 &&
        rivalHeads.isNotEmpty) {
      Vector2? closestHead;
      double minDist = double.infinity;
      for (final rh in rivalHeads) {
        final d = rh.distanceTo(headPos);
        if (d < 180 && d < minDist) {
          minDist = d;
          closestHead = rh;
        }
      }
      if (closestHead != null && _state != _BotState.collectDrop) {
        _state = _BotState.intercept;
        _targetPos = closestHead.clone();
        _stateTimer = 0;
      }
    }

    // Chase orbs
    if (_state == _BotState.roam && orbPositions.isNotEmpty) {
      Vector2? closest;
      double minDist = double.infinity;
      for (final orb in orbPositions) {
        final d = orb.distanceTo(headPos);
        if (d < 300 && d < minDist) {
          minDist = d;
          closest = orb;
        }
      }
      if (closest != null) {
        _state = _BotState.chase;
        _targetPos = closest.clone();
        _stateTimer = 0;
      }
    }

    double nextAngle = currentAngle;

    switch (_state) {
      case _BotState.chase:
        if (_targetPos != null) {
          final dir = _targetPos! - headPos;
          if (dir.length > 2) nextAngle = atan2(dir.y, dir.x);
        }
        if (_targetPos != null && _targetPos!.distanceTo(headPos) < 80 && _boostCooldown <= 0) {
          triggerBoost(0.7);
          _boostCooldown = 3.0;
        }
        break;
      case _BotState.intercept:
        if (_targetPos != null) {
          final interceptPoint = _targetPos! + Vector2(cos(atan2(_targetPos!.y - headPos.y, _targetPos!.x - headPos.x)) * 80, sin(atan2(_targetPos!.y - headPos.y, _targetPos!.x - headPos.x)) * 80);
          final dir = interceptPoint - headPos;
          if (dir.length > 2) nextAngle = atan2(dir.y, dir.x);
          if (headPos.distanceTo(_targetPos!) < 120 && _boostCooldown <= 0) {
            triggerBoost(0.9);
            _boostCooldown = 2.5;
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
          if (d < 70 && d > 0) {
            final diff = headPos - seg;
            diff.normalize();
            repulsion.add(diff * (70 - d));
          }
        }
        if (repulsion.length > 0.1) nextAngle = atan2(repulsion.y, repulsion.x);
        break;
      case _BotState.roam:
        if (_stateTimer > 0.8) {
          nextAngle = currentAngle + (_rng.nextDouble() - 0.5) * 1.2;
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
