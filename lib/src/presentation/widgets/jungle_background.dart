import 'dart:math' as math;
import 'package:flutter/material.dart';

class JungleBackground extends StatefulWidget {
  final Widget? child;
  const JungleBackground({super.key, this.child});

  @override
  State<JungleBackground> createState() => _JungleBackgroundState();
}

class _JungleBackgroundState extends State<JungleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Capa de Cielo / Fondo lejano
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2D5A27), // Verde oscuro arriba
                Color(0xFF8DB600), // Manzana verde abajo
              ],
            ),
          ),
        ),

        // 2. Capa de Árboles lejanos (Siluetas)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _JunglePainter(
                animationValue: _controller.value,
                layer: _JungleLayer.background,
              ),
            );
          },
        ),

        // 3. Capa de Luces/Luciérnagas (Fireflies)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _FireflyPainter(animationValue: _controller.value),
            );
          },
        ),

        // 4. Capa de Arbustos y Plantas medias
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _JunglePainter(
                animationValue: _controller.value,
                layer: _JungleLayer.midground,
              ),
            );
          },
        ),

        // 5. Capa de Suelo y Vegetación frontal
        Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 120),
                painter: _JunglePainter(
                  animationValue: _controller.value,
                  layer: _JungleLayer.foreground,
                ),
              );
            },
          ),
        ),

        // Contenido del Menú
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

enum _JungleLayer { background, midground, foreground }

class _JunglePainter extends CustomPainter {
  final double animationValue;
  final _JungleLayer layer;

  _JunglePainter({required this.animationValue, required this.layer});

  @override
  void paint(Canvas canvas, Size size) {
    switch (layer) {
      case _JungleLayer.background:
        _paintBackgroundTrees(canvas, size);
        break;
      case _JungleLayer.midground:
        _paintBushes(canvas, size);
        break;
      case _JungleLayer.foreground:
        _paintFloor(canvas, size);
        break;
    }
  }

  void _paintBackgroundTrees(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF1B3D17).withOpacity(0.6);
    final wind = math.sin(animationValue * 2 * math.pi) * 5;

    for (int i = 0; i < 8; i++) {
      final x = size.width * (i / 7);
      final h = size.height * 0.7 + (i % 3) * 30;

      final path = Path();
      path.moveTo(x - 20, size.height);
      path.quadraticBezierTo(x + wind, size.height * 0.5, x, size.height - h);
      path.quadraticBezierTo(x + 30 + wind, size.height * 0.5, x + 40, size.height);
      canvas.drawPath(path, paint);
    }
  }

  void _paintBushes(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF3A6B35);
    final wind = math.cos(animationValue * 2 * math.pi) * 8;

    for (int i = 0; i < 12; i++) {
      final x = size.width * (i / 11);
      final r = 40.0 + (i % 4) * 15;

      canvas.drawCircle(
        Offset(x + wind * (i % 2 == 0 ? 1 : -1), size.height - 40),
        r,
        paint,
      );

      // Dibujar algunas hojas encima
      _drawLeaf(canvas, Offset(x + wind, size.height - 80), r * 0.8, paint);
    }
  }

  void _drawLeaf(Canvas canvas, Offset pos, double size, Paint paint) {
    final path = Path();
    path.moveTo(pos.dx, pos.dy);
    path.quadraticBezierTo(pos.dx + size, pos.dy - size, pos.dx + size * 2, pos.dy);
    path.quadraticBezierTo(pos.dx + size, pos.dy + size, pos.dx, pos.dy);
    canvas.drawPath(path, paint);
  }

  void _paintFloor(Canvas canvas, Size size) {
    // Tierra oscura
    final brownPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 40, size.width, 40), brownPaint);

    // Hierba superior (Serrado)
    final grassPaint = Paint()..color = const Color(0xFF4CAF50);
    final path = Path();
    path.moveTo(0, size.height - 40);
    for (double x = 0; x <= size.width; x += 15) {
      path.lineTo(x, size.height - 50 - (math.sin(x + animationValue * 10) * 5));
      path.lineTo(x + 7, size.height - 40);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    canvas.drawPath(path, grassPaint);

    // Rocas decorativas
    final rockPaint = Paint()..color = Colors.grey;
    canvas.drawOval(Rect.fromLTWH(size.width * 0.2, size.height - 35, 40, 25), rockPaint);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.75, size.height - 30, 30, 20), rockPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FireflyPainter extends CustomPainter {
  final double animationValue;
  _FireflyPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFFFB2).withOpacity(0.8);
    final rng = math.Random(42);

    for (int i = 0; i < 15; i++) {
      final basePos = Offset(
        rng.nextDouble() * size.width,
        rng.nextDouble() * size.height * 0.8,
      );

      // Movimiento flotante
      final offset = Offset(
        math.sin(animationValue * 2 * math.pi + i) * 20,
        math.cos(animationValue * 2 * math.pi * 0.5 + i) * 30,
      );

      // Parpadeo
      final opacity = (math.sin(animationValue * 4 * math.pi + i) + 1) / 2;
      paint.color = const Color(0xFFFFFFB2).withOpacity(0.3 + 0.6 * opacity);

      canvas.drawCircle(basePos + offset, 2.5, paint);
      // Glow exterior
      canvas.drawCircle(basePos + offset, 6.0, paint..color = paint.color.withOpacity(0.2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
