import 'dart:math';
import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';

/// Joystick virtual de 360° con diseño neon premium.
///
/// Características:
/// - Responde a cualquier ángulo continuo (sin limitación a 4 direcciones).
/// - Zona muerta configurable (no envía dirección si el pulgar está en el centro).
/// - Feedback visual inmediato — sin delay de animación en el stick.
/// - Efecto glow neon en la base y el stick.
class NeonJoystick extends StatefulWidget {
  /// Callback con el ángulo en radianes cada vez que el jugador mueve el stick.
  /// Se llama con `null` cuando el stick vuelve al centro (zona muerta).
  final void Function(double? angle) onAngleChanged;

  /// Tamaño total del widget (radio de la base × 2 + margen de glow).
  final double size;

  /// Radio de zona muerta en píxeles. Movimientos menores no envían input.
  final double deadZone;

  const NeonJoystick({
    super.key,
    required this.onAngleChanged,
    this.size = 160,
    this.deadZone = 10,
  });

  @override
  State<NeonJoystick> createState() => _NeonJoystickState();
}

class _NeonJoystickState extends State<NeonJoystick>
    with SingleTickerProviderStateMixin {
  Offset _stickOffset = Offset.zero;
  bool _active = false;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Radio máximo que puede viajar el stick
  double get _maxRadius => widget.size / 2 - 22;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    setState(() => _active = true);
    _processOffset(d.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails d) => _processOffset(d.localPosition);

  void _onPanEnd(DragEndDetails _) => _resetStick();
  void _onPanCancel() => _resetStick();

  void _processOffset(Offset local) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final raw = local - center;
    final dist = raw.distance;

    if (dist < widget.deadZone) {
      // Zona muerta — stick al centro, sin enviar ángulo
      setState(() => _stickOffset = Offset.zero);
      widget.onAngleChanged(null);
      return;
    }

    // Clampear al radio máximo
    final clamped = dist > _maxRadius ? raw / dist * _maxRadius : raw;
    setState(() => _stickOffset = clamped);

    final angle = atan2(raw.dy, raw.dx);
    widget.onAngleChanged(angle);
  }

  void _resetStick() {
    setState(() {
      _stickOffset = Offset.zero;
      _active = false;
    });
    widget.onAngleChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (ctx, _) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Base exterior con glow ─────────────────────────────
                Container(
                  width: widget.size * _pulseAnim.value,
                  height: widget.size * _pulseAnim.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (_active
                              ? AppColors.accent
                              : AppColors.accent.withOpacity(0.5))
                          .withOpacity(0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(_active ? 0.35 : 0.15),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                    color: Colors.transparent,
                  ),
                ),

                // ── Base interior rellena ──────────────────────────────
                Container(
                  width: widget.size * 0.82,
                  height: widget.size * 0.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.45),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                ),

                // ── Líneas de referencia (cruz sutil) ─────────────────
                CustomPaint(
                  size: Size(widget.size * 0.82, widget.size * 0.82),
                  painter: _CrossPainter(color: AppColors.accent.withOpacity(0.1)),
                ),

                // ── Stick ──────────────────────────────────────────────
                Transform.translate(
                  offset: _stickOffset,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          AppColors.accent,
                        ],
                        stops: const [0.2, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.7),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Dibuja una cruz de referencia sutil en la base del joystick.
class _CrossPainter extends CustomPainter {
  final Color color;
  _CrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), paint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter o) => o.color != color;
}
