import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

/// Modelo que contiene únicamente el estado de una serpiente.
/// No contiene lógica de movimiento ni de renderizado.
class SnakeModel {
  final String id;
  final bool isPlayer;
  final SnakeSkin skin;

  List<Vector2> segments;
  double segmentRadius;

  double currentAngle;
  double targetAngle;
  double speed;
  bool isBoosting;

  int minSegmentCount;
  int score;

  // Historial de posiciones para el sistema de trail (waypoint)
  final List<Vector2> posHistory = [];
  double sinceLastHistoryPoint = 0.0;
  double boostMassTimer = 0.0;
  int pendingMassDrop = 0;

  SnakeModel({
    required this.id,
    required this.isPlayer,
    required this.skin,
    required this.segments,
    this.segmentRadius = 11.0,
    this.currentAngle = 0.0,
    this.targetAngle = 0.0,
    this.speed = 165.0,
    this.isBoosting = false,
    this.minSegmentCount = 7,
    this.score = 0,
  });

  /// Crea una copia del modelo (útil para sincronización en red futura).
  SnakeModel copyWith({
    List<Vector2>? segments,
    double? currentAngle,
    double? targetAngle,
    bool? isBoosting,
    int? score,
  }) {
    return SnakeModel(
      id: id,
      isPlayer: isPlayer,
      skin: skin,
      segments: segments ?? this.segments,
      segmentRadius: segmentRadius,
      currentAngle: currentAngle ?? this.currentAngle,
      targetAngle: targetAngle ?? this.targetAngle,
      speed: speed,
      isBoosting: isBoosting ?? this.isBoosting,
      minSegmentCount: minSegmentCount,
      score: score ?? this.score,
    );
  }
}
