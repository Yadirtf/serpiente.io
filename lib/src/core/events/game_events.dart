import 'package:flame/components.dart';

/// Clase base para todos los eventos del juego.
abstract class GameEvent {}

/// Evento disparado cuando una serpiente muere.
class SnakeDeadEvent extends GameEvent {
  final String snakeId;
  final bool isPlayer;
  final Vector2 deathPosition;

  SnakeDeadEvent({
    required this.snakeId,
    required this.isPlayer,
    required this.deathPosition,
  });
}

/// Evento disparado cuando se recolecta un orbe.
class OrbCollectedEvent extends GameEvent {
  final String collectorId;
  final bool isPlayer;
  final int value;

  OrbCollectedEvent({
    required this.collectorId,
    required this.isPlayer,
    required this.value,
  });
}

/// Evento disparado cuando la puntuación cambia.
class ScoreChangedEvent extends GameEvent {
  final int newScore;
  final int delta;

  ScoreChangedEvent({
    required this.newScore,
    required this.delta,
  });
}
