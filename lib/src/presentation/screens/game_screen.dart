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
/// - El overlay de Game Over con diseño premium y animación de slide-up.
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
    // Energía del boost proporcional al tamaño de la serpiente.
    // Proteger contra acceso cuando la serpiente está muerta (segments.clear).
    final segs = _game.snakeComponent.segments.length;
    final energy = segs < 6 ? 0.0 : ((segs - 6) / 60).clamp(0.0, 1.0);
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
          // IMPORTANTE: Positioned.fill es obligatorio — los widgets
          // Positioned/BackdropFilter dentro del overlay DEBEN tener un
          // ancestro Positioned directo en el Stack padre.
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

// ─────────────────────────────────────────────────────────────────────────────
// Game Over Overlay — Premium con slide-up + glassmorphism + iconos gaming
// ─────────────────────────────────────────────────────────────────────────────

class _GameOverOverlay extends StatefulWidget {
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
  State<_GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<_GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    // Slide-up: el modal entra desde abajo (Offset(0, 0.25) → Offset.zero).
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Fade-in del fondo oscuro.
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Ligero scale-up del card para sensación de "pop".
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNewRecord = widget.score >= widget.highScore && widget.score > 0;
    final primaryColor = isNewRecord ? AppColors.neonOrange : AppColors.neonRed;
    final glowColor = isNewRecord
        ? AppColors.neonOrange.withOpacity(0.35)
        : AppColors.neonRed.withOpacity(0.30);

    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.height < 450;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Stack(
        children: [
          // ── Fondo oscuro semitransparente ─────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.80),
                  ],
                ),
              ),
            ),
          ),

          // ── Decoración: icono de gaming difuso al fondo ───────────────
          Center(
            child: Opacity(
              opacity: 0.04,
              child: Icon(
                Icons.sports_esports_rounded,
                size: isCompact ? 200 : 320,
                color: primaryColor,
              ),
            ),
          ),

          // ── Card principal ────────────────────────────────────────────
          Center(
            child: SlideTransition(
              position: _slideAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: _buildCard(
                  isNewRecord,
                  primaryColor,
                  glowColor,
                  isCompact,
                  screenSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    bool isNewRecord,
    Color primaryColor,
    Color glowColor,
    bool isCompact,
    Size screenSize,
  ) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: (screenSize.width * 0.9).clamp(280.0, 340.0),
        maxHeight: screenSize.height * 0.92,
      ),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 18 : 28,
          isCompact ? 16 : 28,
          isCompact ? 18 : 28,
          isCompact ? 16 : 24,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A).withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: primaryColor.withOpacity(0.7),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor,
              blurRadius: isCompact ? 24 : 48,
              spreadRadius: isCompact ? 3 : 6,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 16,
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icono principal (gaming) ────────────────────────────────
              _GamingIcon(
                isNewRecord: isNewRecord,
                primaryColor: primaryColor,
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 8 : 14),

              // ── Título ──────────────────────────────────────────────────
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isNewRecord
                      ? [const Color(0xFFFFD700), AppColors.neonOrange]
                      : [AppColors.neonRed, const Color(0xFFFF6B8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  isNewRecord ? '¡NUEVO RÉCORD!' : '¡HAS MUERTO!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isCompact ? 18 : 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: isCompact ? 1.2 : 2,
                  ),
                ),
              ),

              if (isNewRecord) ...[
                const SizedBox(height: 4),
                Text(
                  'MEJOR PUNTUACIÓN SUPERADA',
                  style: TextStyle(
                    color: AppColors.neonOrange.withOpacity(0.75),
                    fontSize: isCompact ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
              SizedBox(height: isCompact ? 10 : 18),

              // ── Score ────────────────────────────────────────────────────
              _ScoreCard(
                score: widget.score,
                highScore: widget.highScore,
                primaryColor: primaryColor,
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 12 : 20),

              // ── Botón Respawn ────────────────────────────────────────────
              _PremiumButton(
                onPressed: widget.onRetry,
                icon: Icons.restart_alt_rounded,
                label: 'RESPAWN',
                subtitle: 'Continuar en este mundo',
                backgroundColor: primaryColor,
                glowColor: glowColor,
                isPrimary: true,
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 6 : 10),

              // ── Botón Menú ───────────────────────────────────────────────
              _PremiumButton(
                onPressed: widget.onMenu,
                icon: Icons.exit_to_app_rounded,
                label: 'MENÚ PRINCIPAL',
                subtitle: 'Salir y reiniciar',
                backgroundColor: Colors.transparent,
                glowColor: Colors.transparent,
                isPrimary: false,
                isCompact: isCompact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icono animado de videojuego (gaming) para el Game Over.
class _GamingIcon extends StatefulWidget {
  final bool isNewRecord;
  final Color primaryColor;
  final bool isCompact;

  const _GamingIcon({
    required this.isNewRecord,
    required this.primaryColor,
    this.isCompact = false,
  });

  @override
  State<_GamingIcon> createState() => _GamingIconState();
}

class _GamingIconState extends State<_GamingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isCompact ? 54.0 : 80.0;
    final iconSize = widget.isCompact ? 28.0 : 38.0;

    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.primaryColor.withOpacity(0.12),
          border: Border.all(
            color: widget.primaryColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withOpacity(0.3),
              blurRadius: widget.isCompact ? 12 : 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          widget.isNewRecord
              ? Icons.emoji_events_rounded   // Trofeo para récord
              : Icons.videogame_asset_rounded, // Control gaming para muerte
          color: widget.primaryColor,
          size: iconSize,
        ),
      ),
    );
  }
}

/// Card de puntuación con diseño premium.
class _ScoreCard extends StatelessWidget {
  final int score;
  final int highScore;
  final Color primaryColor;
  final bool isCompact;

  const _ScoreCard({
    required this.score,
    required this.highScore,
    required this.primaryColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Etiqueta
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: primaryColor, size: isCompact ? 12 : 14),
              const SizedBox(width: 4),
              Text(
                'PUNTUACIÓN',
                style: TextStyle(
                  color: primaryColor.withOpacity(0.8),
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: isCompact ? 2 : 3,
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 4 : 8),
          // Score grande
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white70],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              score.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 36 : 52,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          if (highScore > 0) ...[
            SizedBox(height: isCompact ? 6 : 10),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.08),
            ),
            SizedBox(height: isCompact ? 6 : 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard_rounded,
                  color: AppColors.accentSoft,
                  size: isCompact ? 12 : 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Récord: $highScore',
                  style: TextStyle(
                    color: AppColors.accentSoft,
                    fontSize: isCompact ? 11 : 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Botón premium con glow, icono y subtítulo.
class _PremiumButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color backgroundColor;
  final Color glowColor;
  final bool isPrimary;
  final bool isCompact;

  const _PremiumButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.backgroundColor,
    required this.glowColor,
    required this.isPrimary,
    this.isCompact = false,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _hoverCtrl;
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _hoverCtrl.reverse(),
        onTapUp: (_) {
          _hoverCtrl.forward();
          widget.onPressed();
        },
        onTapCancel: () => _hoverCtrl.forward(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: widget.isCompact ? 9 : 14,
            horizontal: widget.isCompact ? 14 : 20,
          ),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? widget.backgroundColor
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isPrimary
                  ? widget.backgroundColor
                  : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: widget.glowColor,
                      blurRadius: widget.isCompact ? 12 : 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
                size: widget.isCompact ? 18 : 22,
              ),
              SizedBox(width: widget.isCompact ? 6 : 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isPrimary
                          ? Colors.white
                          : Colors.white.withOpacity(0.75),
                      fontSize: widget.isCompact ? 12 : 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: widget.isCompact ? 1 : 1.5,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: widget.isPrimary
                          ? Colors.white.withOpacity(0.65)
                          : Colors.white.withOpacity(0.4),
                      fontSize: widget.isCompact ? 9 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
