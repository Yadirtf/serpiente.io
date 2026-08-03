import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';
import 'package:serpiente_io/src/data/persistence/game_preferences.dart';
import 'package:serpiente_io/src/game/models/game_mode.dart';
import 'package:serpiente_io/src/game/skins/skin_repository.dart';
import 'package:serpiente_io/src/game/snake_game.dart';
import 'package:serpiente_io/src/presentation/widgets/game_hud.dart';

/// Pantalla de juego principal. Sin AppBar para aprovechar toda la
/// pantalla en modo landscape.
///
/// Gestiona:
/// - La instancia del motor de juego [SnakeGame].
/// - El HUD de controles táctiles (joystick + boost).
/// - El overlay de Game Over con diseño premium.
/// - Guardado automático del high score.
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

    // Escuchar score para actualizar energía del boost
    _game.scoreNotifier.addListener(_onScoreChanged);
  }

  @override
  void dispose() {
    _game.scoreNotifier.removeListener(_onScoreChanged);
    super.dispose();
  }

  void _onScoreChanged() {
    // Energía del boost proporcional al tamaño de la serpiente
    // Sin energía si tiene menos de 6 segmentos
    final segs = _game.snakeComponent.segments.length;
    final energy = ((segs - 6) / 60).clamp(0.0, 1.0);
    if (mounted) setState(() => _energyLevel = energy);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Sin AppBar — pantalla completa en landscape
      body: Stack(
        children: [
          // ── Motor de juego (canvas) ─────────────────────────────────
          Positioned.fill(
            child: GameWidget(game: _game),
          ),

          // ── Score en tiempo real ─────────────────────────────────────
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: _game.scoreNotifier,
                builder: (_, score, __) => _ScorePill(score: score),
              ),
            ),
          ),

          // ── HUD de controles ─────────────────────────────────────────
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

          // ── Indicador de boost activo ────────────────────────────────
          Positioned(
            top: 16,
            right: 120,
            child: ValueListenableBuilder<bool>(
              valueListenable: _game.isBoostingNotifier,
              builder: (_, boosting, __) => boosting
                  ? const _BoostIndicator()
                  : const SizedBox.shrink(),
            ),
          ),

          // ── Overlay Game Over ────────────────────────────────────────
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

                return _GameOverOverlay(
                  score: _game.score,
                  highScore: GamePreferences.highScore,
                  onRetry: () {
                    _savedGameOver = false;
                    setState(() => _energyLevel = 1.0);
                    _game.reset();
                  },
                  onMenu: () => Navigator.of(context).pop(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final int score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.hudBackground,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.hudBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: 6),
          Text(
            score.toString(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostIndicator extends StatefulWidget {
  const _BoostIndicator();

  @override
  State<_BoostIndicator> createState() => _BoostIndicatorState();
}

class _BoostIndicatorState extends State<_BoostIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.6, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.neonOrange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.neonOrange, width: 1.5),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flash_on_rounded, color: AppColors.neonOrange, size: 16),
            SizedBox(width: 4),
            Text(
              'BOOST',
              style: TextStyle(
                color: AppColors.neonOrange,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final int highScore;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const _GameOverOverlay({
    required this.score,
    required this.highScore,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final isNewRecord = score >= highScore && score > 0;

    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isNewRecord
                  ? AppColors.neonOrange
                  : AppColors.neonRed.withOpacity(0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isNewRecord
                        ? AppColors.neonOrange
                        : AppColors.neonRed)
                    .withOpacity(0.25),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji
              Text(
                isNewRecord ? '🏆' : '💀',
                style: const TextStyle(fontSize: 52),
              ),
              const SizedBox(height: 12),

              // Título
              Text(
                isNewRecord ? '¡NUEVO RÉCORD!' : '¡HAS MUERTO!',
                style: TextStyle(
                  color: isNewRecord ? AppColors.neonOrange : AppColors.neonRed,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      score.toString(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'PUNTOS',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    if (highScore > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Récord: $highScore',
                        style: const TextStyle(
                          color: AppColors.accentSoft,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botones
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('JUGAR DE NUEVO'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onMenu,
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('MENÚ PRINCIPAL'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
