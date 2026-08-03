import 'dart:math';
import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/controllers/snake_controller.dart';

/// IA para serpientes bot en modo offline.
///
/// ### Máquina de estados ampliada:
///
/// ```
/// roam ──► chase ──► intercept
///   ▲         │          │
///   └─────────┘          │
///        evadeEdge ◄─────┘
///        evadeRival (emergencia)
///        collectDrop (orbes prioritarios tras muerte de bot)
/// ```
///
/// 1. **roam** — deambular buscando orbes cercanos.
/// 2. **chase** — navegar hacia el orbe más cercano y recogerlo.
/// 3. **intercept** — cortar el camino a un rival (agresivo).
/// 4. **evadeEdge** — alejarse del borde con boost de emergencia.
/// 5. **evadeRival** — evasión por repulsión vectorial de segmentos cercanos.
/// 6. **collectDrop** — recoger orbes prioritarios dejados por un bot muerto.
class BotController extends SnakeController {
  final String botName;
  final double mapSize;
  final _rng = Random();

  double _stateTimer = 0;
  double _boostCooldown = 0;
  _BotState _state = _BotState.roam;

  /// Target position (orb o punto de evasión) hacia donde navega el bot.
  Vector2? _targetPos;

  /// Orbes prioritarios (caída de bot muerto) a recoger antes que cualquier otro.
  final List<Vector2> _priorityOrbPositions = [];

  BotController({
    required this.botName,
    required this.mapSize,
    double initialAngle = 0,
  }) : super(
          speed: 120 + Random().nextDouble() * 30,
          initialAngle: initialAngle,
          maxTurnSpeed: 3.0 + Random().nextDouble() * 1.5,
        );

  /// Notifica al bot de orbes prioritarios (drop de bot muerto).
  /// El bot abandonará su estado actual para ir a recogerlos.
  void notifyOrbDrop(List<Vector2> positions) {
    _priorityOrbPositions.addAll(positions.map((p) => p.clone()));
    if (_state != _BotState.evadeEdge && _state != _BotState.evadeRival) {
      _state = _BotState.collectDrop;
      _stateTimer = 0;
    }
  }

  /// Decide la siguiente acción del bot dado su estado y el entorno.
  ///
  /// [headPos]: posición actual de la cabeza del bot.
  /// [orbPositions]: posiciones de todos los orbes en el mapa.
  /// [rivalSegments]: lista de segmentos de TODOS los rivales (incluye player).
  /// [rivalHeads]: posiciones de las cabezas de rivales (para intercept).
  /// [mySegmentCount]: número de segmentos propios (para decidir agresividad).
  void think({
    required Vector2 headPos,
    required List<Vector2> orbPositions,
    required List<Vector2> rivalSegments,
    List<Vector2> rivalHeads = const [],
    int mySegmentCount = 0,
    required double dt,
  }) {
    _stateTimer += dt;
    if (_boostCooldown > 0) _boostCooldown -= dt;

    // ── Evasión de bordes (prioridad máxima) ─────────────────────────────
    const edgeMargin = 120.0;
    final nearEdge = headPos.x < edgeMargin ||
        headPos.x > mapSize - edgeMargin ||
        headPos.y < edgeMargin ||
        headPos.y > mapSize - edgeMargin;

    if (nearEdge) {
      _state = _BotState.evadeEdge;
      _stateTimer = 0;
    }

    // ── Evasión de colisión rival (prioridad alta) ────────────────────
    if (_state != _BotState.evadeEdge) {
      // Calcular vector de repulsión de todos los segmentos cercanos.
      final danger = rivalSegments.any((seg) => seg.distanceTo(headPos) < 45);
      if (danger) {
        _state = _BotState.evadeRival;
        _stateTimer = 0;
      }
    }

    // ── Tiempo de estado agotado → transición ─────────────────────────
    if (_stateTimer > 2.0 &&
        _state != _BotState.chase &&
        _state != _BotState.intercept &&
        _state != _BotState.collectDrop) {
      _state = _BotState.roam;
      _stateTimer = 0;
    }

    // ── Limpiar orbes prioritarios ya consumidos ───────────────────────
    if (_state == _BotState.collectDrop) {
      _priorityOrbPositions.removeWhere(
          (p) => !orbPositions.any((o) => o.distanceTo(p) < 25));
      if (_priorityOrbPositions.isEmpty) {
        _state = _BotState.roam;
        _stateTimer = 0;
      }
    }

    // ── Modo intercept: intentar cortar el paso a un rival ─────────────
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

    // ── Buscar orbe más cercano para cazar ───────────────────────────
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

    // ── Verificar que el target de chase aún existe ────────────────────
    if (_state == _BotState.chase && _targetPos != null) {
      final stillExists =
          orbPositions.any((o) => o.distanceTo(_targetPos!) < 20);
      if (!stillExists) {
        _state = _BotState.roam;
        _targetPos = null;
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
        // Boost cuando está cerca del objetivo para recogerlo rápido.
        if (_targetPos != null &&
            _targetPos!.distanceTo(headPos) < 80 &&
            _boostCooldown <= 0) {
          setBoosting(true);
          _boostCooldown = 3.0;
          Future.delayed(
              const Duration(milliseconds: 700), () => setBoosting(false));
        }
        break;

      case _BotState.intercept:
        if (_targetPos != null) {
          // Predecir posición futura del rival (80 px adelante en su dirección).
          // Usamos _targetPos como aproximación de su posición actual.
          // El punto de intercepción es 80 px delante del rival.
          final interceptPoint = Vector2(
            _targetPos!.x + cos(atan2(
                    _targetPos!.y - headPos.y, _targetPos!.x - headPos.x)) *
                80,
            _targetPos!.y + sin(atan2(
                    _targetPos!.y - headPos.y, _targetPos!.x - headPos.x)) *
                80,
          );
          final dir = interceptPoint - headPos;
          if (dir.length > 2) angle = atan2(dir.y, dir.x);

          final distToTarget = headPos.distanceTo(_targetPos!);
          if (distToTarget < 120 && _boostCooldown <= 0) {
            setBoosting(true);
            _boostCooldown = 2.5;
            Future.delayed(
                const Duration(milliseconds: 900), () => setBoosting(false));
          }
          // Abandonar intercept si el rival se fue lejos.
          if (distToTarget > 250) {
            _state = _BotState.roam;
            _targetPos = null;
          }
        }
        break;

      case _BotState.collectDrop:
        if (_priorityOrbPositions.isNotEmpty) {
          // Ir al orbe prioritario más cercano.
          Vector2? closest;
          double minD = double.infinity;
          for (final p in _priorityOrbPositions) {
            final d = p.distanceTo(headPos);
            if (d < minD) {
              minD = d;
              closest = p;
            }
          }
          if (closest != null) {
            final dir = closest - headPos;
            if (dir.length > 2) angle = atan2(dir.y, dir.x);
            // Boost para llegar antes que otro bot.
            if (minD < 200 && _boostCooldown <= 0) {
              setBoosting(true);
              _boostCooldown = 2.0;
              Future.delayed(
                  const Duration(milliseconds: 800), () => setBoosting(false));
            }
          }
        }
        break;

      case _BotState.evadeEdge:
        // Girar hacia el centro del mapa con boost de emergencia.
        final center = Vector2(mapSize / 2, mapSize / 2);
        final dir = center - headPos;
        angle = atan2(dir.y, dir.x);
        // Boost si está muy cerca del borde.
        final distToBorder = [
          headPos.x,
          headPos.y,
          mapSize - headPos.x,
          mapSize - headPos.y,
        ].reduce(min);
        if (distToBorder < 60 && _boostCooldown <= 0) {
          setBoosting(true);
          _boostCooldown = 2.0;
          Future.delayed(
              const Duration(milliseconds: 500), () => setBoosting(false));
        }
        // Salir de evadeEdge cuando está suficientemente lejos del borde.
        if (distToBorder > 150) {
          _state = _BotState.roam;
          _stateTimer = 0;
        }
        break;

      case _BotState.evadeRival:
        // Calcular vector de repulsión sumando fuerzas de todos los segmentos
        // cercanos (< 70 px) → resultado más natural que girar 90° siempre.
        var repulsion = Vector2.zero();
        for (final seg in rivalSegments) {
          final d = seg.distanceTo(headPos);
          if (d < 70 && d > 0) {
            final push = (headPos - seg)..normalize();
            repulsion.add(push * (70 - d));
          }
        }
        if (repulsion.length > 0.1) {
          angle = atan2(repulsion.y, repulsion.x);
        } else {
          // Fallback: girar 90° si no hay datos de repulsión.
          angle = currentAngle + pi / 2;
        }
        if (_stateTimer > 1.2) {
          _state = _BotState.roam;
          _stateTimer = 0;
        }
        break;

      case _BotState.roam:
        // Pequeña variación aleatoria del ángulo.
        if (_stateTimer > 0.8) {
          angle = currentAngle + (_rng.nextDouble() - 0.5) * 1.2;
          _stateTimer = 0;
        }
        break;
    }

    setTargetAngle(angle);
  }
}

enum _BotState { roam, chase, intercept, evadeEdge, evadeRival, collectDrop }
