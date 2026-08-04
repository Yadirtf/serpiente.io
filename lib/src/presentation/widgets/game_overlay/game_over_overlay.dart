import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';
import 'package:serpiente_io/src/presentation/widgets/game_overlay/gaming_icon.dart';
import 'package:serpiente_io/src/presentation/widgets/game_overlay/premium_button.dart';
import 'package:serpiente_io/src/presentation/widgets/game_overlay/score_card.dart';

/// Overlay de Game Over con animación slide-up, glassmorphism e iconos gaming.
class GameOverOverlay extends StatefulWidget {
  final int score;
  final int highScore;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.highScore,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
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

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

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
          // Fondo oscuro semitransparente
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

          // Icono difuso al fondo
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

          // Card principal
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
              GamingIcon(
                isNewRecord: isNewRecord,
                primaryColor: primaryColor,
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 8 : 14),

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

              ScoreCard(
                score: widget.score,
                highScore: widget.highScore,
                primaryColor: primaryColor,
                isCompact: isCompact,
              ),
              SizedBox(height: isCompact ? 12 : 20),

              PremiumButton(
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

              PremiumButton(
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
