import 'package:serpiente_io/src/game/models/game_mode.dart';

enum GameModeStatus { available, upcoming, locked }

/// Representa la información de un modo de juego para ser mostrada en el menú.
class GameModeInfo {
  final GameMode mode;
  final String title;
  final String description;
  final String imagePath;
  final GameModeStatus status;
  final String iconLabel;

  const GameModeInfo({
    required this.mode,
    required this.title,
    required this.description,
    required this.imagePath,
    this.status = GameModeStatus.available,
    required this.iconLabel,
  });

  bool get isAvailable => status == GameModeStatus.available;
}
