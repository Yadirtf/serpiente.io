import 'dart:math';
import 'package:flame/components.dart';

/// Controla el movimiento de una serpiente con ángulo continuo de 360°,
/// suavizado de giro por inercia y boost con consumo de masa.
///
/// ### Waypoint Trail System
/// En lugar de mover cada segmento hacia el anterior por distancia mínima
/// (lo que causaba "atajos" en los giros), ahora se mantiene un historial
/// de posiciones de la cabeza. Cada segmento del cuerpo se coloca en el
/// punto del historial donde el arco acumulado desde la cabeza supera
/// `segmentDistance * i`, garantizando que el cuerpo sigue **exactamente**
/// el mismo recorrido que trazó la cabeza.
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

  /// Segmentos mínimos que la serpiente puede mantener al boostear.
  int minSegmentCount;

  /// Velocidad de movimiento actual usada por la serpiente.
  double get currentSpeed {
    if (!isBoosting) return speed;
    final boostSpeed = speed * boostMultiplier;
    return (boostSpeed - _pendingMassDrop * 3.0).clamp(0.0, double.infinity);
  }

  // ── Waypoint Trail ────────────────────────────────────────────────────────
  /// Historial de posiciones de la cabeza, en orden cronológico desde la cola
  /// hasta la punta más reciente. Esto evita insertar en la cabeza de la lista
  /// cada frame, que es costoso y puede generar micro-parones al crecer la serpiente.
  final List<Vector2> _posHistory = [];

  /// Granularidad del historial: un punto se añade cada vez que la cabeza
  /// avanza esta distancia. Valores bajos → curvas más suaves pero más memoria.
  static const double _kHistoryGranularity = 2.0;

  /// Distancia acumulada desde el último punto del historial.
  double _sinceLastHistoryPoint = 0.0;

  SnakeController({
    this.speed = 165,
    this.segmentDistance = 14,
    this.boostMultiplier = 1.95,
    this.maxTurnSpeed = 6.2, // rad/s — respuesta más directa para sentir mejor el movimiento
    double initialAngle = 0,
    this.isBoosting = false,
    this.minSegmentCount = 7,
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

  /// Aplica el efecto de soltar orbes al acelerar: la velocidad disminuye 3 ms por cada orbe soltado.
  void applyMassDrop(int count) {
    if (count <= 0) return;
    _pendingMassDrop += count;
  }

  /// Reinicia el historial de posiciones (útil al hacer respawn).
  void resetHistory(List<Vector2> initialSegments) {
    _posHistory.clear();
    _sinceLastHistoryPoint = 0;
    minSegmentCount = initialSegments.length;
    // Precarga el historial con las posiciones iniciales para que el cuerpo
    // aparezca correctamente posicionado desde el primer frame.
    for (final seg in initialSegments) {
      _posHistory.add(seg.clone());
    }
  }

  /// Actualiza el ángulo actual acercándolo al objetivo respetando la
  /// velocidad de giro máxima. Retorna los segmentos actualizados.
  List<Vector2> move(List<Vector2> segments, double dt) {
    if (segments.isEmpty) return segments;

    // ── 1. Suavizar ángulo hacia el objetivo ──────────────────────────────
    final angleDiff = _angleDiff(_targetAngle, _currentAngle);
    final maxDelta = maxTurnSpeed * dt;
    final step = angleDiff.clamp(-maxDelta, maxDelta);
    _currentAngle = _normalizeAngle(_currentAngle + step);

    // ── 2. Calcular velocidad ─────────────────────────────────────────────
    final effectiveSpeed = currentSpeed;

    // ── 3. Mover cabeza en la dirección actual ────────────────────────────
    final head = segments.first.clone();
    final direction = Vector2(cos(_currentAngle), sin(_currentAngle));
    final frameDist = effectiveSpeed * dt;
    head.addScaled(direction, frameDist);

    // ── 4. Actualizar historial de posiciones de la cabeza ────────────────
    if (_posHistory.isEmpty) {
      _posHistory.add(head.clone());
    }

    _sinceLastHistoryPoint += frameDist;
    if (_sinceLastHistoryPoint >= _kHistoryGranularity) {
      _sinceLastHistoryPoint = 0;
      _posHistory.add(head.clone());
    } else if (_posHistory.isNotEmpty) {
      _posHistory[_posHistory.length - 1] = head.clone();
    }

    // ── 5. Colocar segmentos del cuerpo siguiendo el historial (trail) ────
    final List<Vector2> next = [head];
    int historyIdx = _posHistory.length - 1;
    double arcAccum = 0.0;

    for (var segI = 1; segI < segments.length; segI++) {
      final targetArc = segmentDistance * segI.toDouble();

      // Avanzar por el historial hasta alcanzar el arco acumulado deseado.
      while (historyIdx > 0) {
        final a = _posHistory[historyIdx];
        final b = _posHistory[historyIdx - 1];
        final d = a.distanceTo(b);
        if (arcAccum + d >= targetArc) {
          // Interpolación lineal para posicionamiento exacto.
          final t = (targetArc - arcAccum) / (d == 0 ? 1 : d);
          next.add(Vector2(
            a.x + (b.x - a.x) * t,
            a.y + (b.y - a.y) * t,
          ));
          break;
        }
        arcAccum += d;
        historyIdx--;
      }

      // Si el historial es más corto que la serpiente, usar el último punto.
      if (next.length <= segI) {
        next.add(_posHistory.last.clone());
      }
    }

    // ── 6. Podar el historial para no crecer indefinidamente ──────────────
    // Máximo de puntos necesarios = total de arco de la serpiente / granularidad + margen.
    final maxHistoryLen =
        ((segments.length * segmentDistance) / _kHistoryGranularity).ceil() + 60;
    if (_posHistory.length > maxHistoryLen) {
      _posHistory.removeRange(0, _posHistory.length - maxHistoryLen);
    }

    // ── 7. Consumo de masa durante boost ──────────────────────────────────
    // Cada 0.35 segundos de boost se elimina 1 segmento de la cola hasta el
    // mínimo definido por el tamaño inicial de la serpiente.
    if (isBoosting && next.length > minSegmentCount) {
      _boostMassTimer += dt;
      while (_boostMassTimer >= _kBoostMassInterval && next.length > minSegmentCount) {
        _boostMassTimer -= _kBoostMassInterval;
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
