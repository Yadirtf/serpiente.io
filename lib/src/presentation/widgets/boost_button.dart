import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';

/// Botón de boost circular con diseño premium neon.
///
/// Características:
/// - Animación de pulso cuando está activo.
/// - Feedback háptico al activar y desactivar.
/// - Indicador visual de energía (barra circular integrada).
/// - Ícono de rayo con glow animado.
class BoostButton extends StatefulWidget {
  /// Callback cuando el estado de boost cambia.
  final void Function(bool isBoosting) onBoostChanged;

  /// Valor de energía entre 0.0 y 1.0 (se muestra como arco circular).
  final double energyLevel;

  /// Tamaño del botón.
  final double size;

  const BoostButton({
    super.key,
    required this.onBoostChanged,
    this.energyLevel = 1.0,
    this.size = 90,
  });

  @override
  State<BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<BoostButton>
    with SingleTickerProviderStateMixin {
  bool _pressing = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onPressDown() {
    if (_pressing) return;
    setState(() => _pressing = true);
    HapticFeedback.mediumImpact();
    _pulseCtrl.repeat(reverse: true);
    widget.onBoostChanged(true);
  }

  void _onPressUp() {
    if (!_pressing) return;
    setState(() => _pressing = false);
    HapticFeedback.lightImpact();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    widget.onBoostChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final energy = widget.energyLevel.clamp(0.0, 1.0);
    final canBoost = energy > 0.05;

    return GestureDetector(
      onTapDown: (_) { if (canBoost) _onPressDown(); },
      onTapUp: (_) => _onPressUp(),
      onTapCancel: _onPressUp,
      onPanEnd: (_) => _onPressUp(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Arco de energía ────────────────────────────────────
              CustomPaint(
                size: Size(widget.size + 16, widget.size + 16),
                painter: _EnergyArcPainter(
                  energy: energy,
                  color: _pressing
                      ? AppColors.neonOrange
                      : AppColors.accent,
                  isActive: _pressing,
                ),
              ),

              // ── Cuerpo del botón ────────────────────────────────────
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _pressing
                        ? [AppColors.neonOrange, const Color(0xFFCC4400)]
                        : [
                            canBoost
                                ? const Color(0xFF2A3F5F)
                                : const Color(0xFF1A2030),
                            const Color(0xFF0D1526),
                          ],
                    center: const Alignment(-0.3, -0.4),
                  ),
                  border: Border.all(
                    color: _pressing
                        ? AppColors.neonOrange.withOpacity(0.9)
                        : (canBoost
                            ? AppColors.accent.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3)),
                    width: 2.5,
                  ),
                  boxShadow: _pressing
                      ? [
                          BoxShadow(
                            color: AppColors.neonOrange.withOpacity(0.6),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(0.2),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícono de rayo
                    Icon(
                      Icons.flash_on_rounded,
                      color: _pressing
                          ? Colors.white
                          : (canBoost
                              ? AppColors.accent
                              : Colors.grey.shade600),
                      size: widget.size * 0.42,
                    ),
                    Text(
                      'BOOST',
                      style: TextStyle(
                        color: _pressing
                            ? Colors.white
                            : (canBoost
                                ? AppColors.accent
                                : Colors.grey.shade600),
                        fontSize: widget.size * 0.13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dibuja el arco de energía alrededor del botón boost.
class _EnergyArcPainter extends CustomPainter {
  final double energy;
  final Color color;
  final bool isActive;

  _EnergyArcPainter({
    required this.energy,
    required this.color,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;

    // Track (fondo del arco)
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.57, // -π/2 (arriba)
      2 * 3.14159,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    if (energy <= 0) return;

    // Arco de energía con glow
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.57,
      2 * 3.14159 * energy,
      false,
      Paint()
        ..color = color.withOpacity(isActive ? 1.0 : 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isActive ? 6 : 3),
    );
  }

  @override
  bool shouldRepaint(_EnergyArcPainter o) =>
      o.energy != energy || o.isActive != isActive || o.color != color;
}
