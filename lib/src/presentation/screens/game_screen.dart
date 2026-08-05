import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:serpiente_io/src/data/persistence/game_preferences.dart';
import 'package:serpiente_io/src/game/models/game_mode.dart';
import 'package:serpiente_io/src/game/skins/skin_repository.dart';
import 'package:serpiente_io/src/game/snake_game.dart';
import 'package:serpiente_io/src/presentation/widgets/game_hud.dart';
import 'package:serpiente_io/src/presentation/widgets/game_overlay/boost_indicator.dart';
import 'package:serpiente_io/src/presentation/widgets/game_overlay/game_over_overlay.dart';
import 'package:serpiente_io/src/presentation/widgets/game_overlay/score_pill.dart';

/// Pantalla de juego principal en orientación landscape.
class GameScreen extends StatefulWidget {
  final String selectedSkinId;
  final GameMode mode;

  const GameScreen({
    super.key,
    this.selectedSkinId = 'default',
    this.mode = GameMode.offline,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late SnakeGame _game;
  bool _savedGameOver = false;
  double _energyLevel = 1.0;

  @override
  void initState() {
    super.initState();
    final skin = SkinRepository().getSkinById(widget.selectedSkinId);
    _game = SnakeGame(
      initialSkin: skin,
      mode: widget.mode,
      botCount: 8,
    );

    _game.segmentCountNotifier.addListener(_onSegmentCountChanged);
  }

  @override
  void dispose() {
    _game.segmentCountNotifier.removeListener(_onSegmentCountChanged);
    super.dispose();
  }

  void _onSegmentCountChanged() {
    final segs = _game.segmentCountNotifier.value;
    final minLength = _game.snakeController.minSegmentCount;
    final energy = segs <= minLength ? 0.0 : ((segs - minLength) / 60).clamp(0.0, 1.0);
    if (mounted) setState(() => _energyLevel = energy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Canvas del juego
          Positioned.fill(
            child: GameWidget(game: _game),
          ),

          // Píldora de puntaje
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: _game.scoreNotifier,
                builder: (_, score, __) => ScorePill(score: score),
              ),
            ),
          ),

          // HUD de Controles
          Positioned.fill(
            child: GameHud(
              energyLevel: _energyLevel,
              onAngleChanged: (angle) {
                if (angle != null) _game.setAngle(angle);
              },
              onBoostChanged: (isBoosting) {
                _game.setBoosting(isBoosting);
              },
            ),
          ),

          // Indicador de Boost Activo
          Positioned(
            top: 16,
            right: 120,
            child: ValueListenableBuilder<bool>(
              valueListenable: _game.isBoostingNotifier,
              builder: (_, boosting, __) => boosting
                  ? const BoostIndicator()
                  : const SizedBox.shrink(),
            ),
          ),

          // Overlay de Game Over
          Positioned.fill(
            child: ValueListenableBuilder<bool>(
              valueListenable: _game.isGameOverNotifier,
              builder: (_, isOver, __) {
                if (!isOver) return const SizedBox.shrink();

                if (!_savedGameOver) {
                  _savedGameOver = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final s = _game.score;
                    if (s > GamePreferences.highScore) {
                      await GamePreferences.setHighScore(s);
                    }
                    await GamePreferences.addCoins(s ~/ 20);
                  });
                }

                return GameOverOverlay(
                  score: _game.score,
                  highScore: GamePreferences.highScore,
                  onRetry: () {
                    _savedGameOver = false;
                    setState(() => _energyLevel = 0.0);
                    _game.respawn();
                  },
                  onMenu: () {
                    _game.reset();
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
