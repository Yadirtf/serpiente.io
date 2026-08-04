import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/components/bot_snake_component.dart';

/// Sistema centralizado de cálculo y verificación de colisiones para Serpiente.io.
class CollisionSystem {
  final double mapSize;

  /// Margen de gracia en píxeles: el jugador puede rozar 2 px sin morir.
  static const double playerGraceMargin = 2.0;

  /// Radio de segmento del jugador.
  static const double playerSegRadius = 12.0;

  /// Radio de segmento de un bot.
  static const double botSegRadius = 10.0;

  CollisionSystem({required this.mapSize});

  /// Verifica si la cabeza del jugador colisiona con el cuerpo de algún bot.
  bool collidesWithBotsPlayer(Vector2 head, List<BotEntry> bots, {Vector2? previousHead}) {
    return bots.any((bot) => collidesWithSnake(
          head,
          bot.component.segments,
          playerSegRadius,
          botSegRadius,
          graceMargin: playerGraceMargin,
          previousHead: previousHead,
        ));
  }

  /// Colisión genérica entre una cabeza y una lista de segmentos de cuerpo.
  bool collidesWithSnake(
    Vector2 head,
    List<Vector2> segs,
    double headRadius,
    double bodyRadius, {
    double graceMargin = 0,
    int skipFirst = 0,
    Vector2? previousHead,
  }) {
    if (segs.isEmpty) return false;

    final threshold = headRadius + bodyRadius - graceMargin;
    final start = previousHead ?? head;

    for (var i = skipFirst; i < segs.length; i++) {
      if (head.distanceTo(segs[i]) < threshold) return true;

      if (i > 0) {
        final distanceToSegment = _distanceToSegment(start, head, segs[i - 1], segs[i]);
        if (distanceToSegment < threshold) return true;
      }
    }
    return false;
  }

  double _distanceToSegment(Vector2 start, Vector2 end, Vector2 a, Vector2 b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return _distanceBetweenPoints(start, end, a);
    }

    final t = ((start.x - a.x) * dx + (start.y - a.y) * dy) / lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);
    final closestX = a.x + dx * clampedT;
    final closestY = a.y + dy * clampedT;

    return _distanceBetweenPoints(start, end, Vector2(closestX, closestY));
  }

  double _distanceBetweenPoints(Vector2 start, Vector2 end, Vector2 point) {
    final closestPoint = _closestPointOnSegment(start, end, point);
    return point.distanceTo(closestPoint);
  }

  Vector2 _closestPointOnSegment(Vector2 start, Vector2 end, Vector2 point) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return start;
    }

    final t = ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    return Vector2(start.x + dx * clampedT, start.y + dy * clampedT);
  }

  /// Comprueba si la posición está fuera de los límites para el JUGADOR (con margen de gracia).
  bool isOutOfBoundsPlayer(Vector2 pos) {
    const border = 5.0;
    final limit = border - playerGraceMargin; // 3 px
    return pos.x < limit ||
        pos.x > mapSize - limit ||
        pos.y < limit ||
        pos.y > mapSize - limit;
  }

  /// Comprueba si la posición está fuera de los límites para un BOT.
  bool isOutOfBoundsBot(Vector2 pos) {
    return pos.x < 5 || pos.x > mapSize - 5 || pos.y < 5 || pos.y > mapSize - 5;
  }
}
