import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:serpiente_io/src/core/constants/app_colors.dart';

class GameLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final List<Color>? bodyColors;
  final bool isAppIcon;

  const GameLogo({
    super.key,
    this.size = 120,
    this.showText = false,
    this.bodyColors,
    this.isAppIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    // We'll use a vibrant turquoise/cyan palette as default to differ from the reference
    final colors = bodyColors ?? [const Color(0xFF00F2FE), const Color(0xFF4FACFE)];

    Widget logo = CustomPaint(
      size: Size(size, size),
      painter: _SnakeCharacterPainter(
        colors: colors,
      ),
    );

    if (isAppIcon) {
      logo = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)], // Distinct purple gradient
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: size * 0.1,
              offset: Offset(0, size * 0.05),
            ),
          ],
        ),
        padding: EdgeInsets.all(size * 0.1),
        child: logo,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        if (showText) ...[
          SizedBox(height: size * 0.1),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [colors.first, colors.last, colors.first],
            ).createShader(bounds),
            child: Text(
              'SERPIENTE.IO',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.22,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                fontFamily: 'Arial',
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SnakeCharacterPainter extends CustomPainter {
  final List<Color> colors;

  _SnakeCharacterPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final secondaryColor = colors.length > 1 ? colors[1] : colors[0].withOpacity(0.7);

    // ── 1. Draw Body Segments (Curved Path) ───────────────────────────
    // We draw circles along a path to simulate the volume and segments
    final List<Offset> points = [];
    for (double t = 0; t <= 1.0; t += 0.02) {
      // Quadratic Bezier for a nice curve
      double x = _lerpBezier(w * 0.8, w * 0.1, w * 0.9, t);
      double y = _lerpBezier(h * 0.1, h * 0.5, h * 0.8, t);
      points.add(Offset(x, y));
    }

    for (int i = 0; i < points.length; i++) {
      final t = i / points.length;
      final radius = (w * 0.12) + (math.sin(t * math.pi) * w * 0.03);

      // Striped pattern logic
      final isStripe = (i ~/ 4) % 2 == 0;
      bodyPaint.color = isStripe ? colors[0] : secondaryColor;

      canvas.drawCircle(points[i], radius, bodyPaint);
    }

    // ── 2. Draw Head ──────────────────────────────────────────────────
    final headPos = points.first;
    final headRadius = w * 0.18;

    // Head main shape
    bodyPaint.color = colors[0];
    canvas.drawCircle(headPos, headRadius, bodyPaint);

    // Head spots (freckles) - Distinct from reference
    final spotPaint = Paint()..color = secondaryColor.withOpacity(0.6);
    canvas.drawCircle(headPos + Offset(-w * 0.05, -h * 0.08), w * 0.02, spotPaint);
    canvas.drawCircle(headPos + Offset(0, -h * 0.1), w * 0.025, spotPaint);
    canvas.drawCircle(headPos + Offset(w * 0.05, -h * 0.08), w * 0.02, spotPaint);

    // ── 3. Face Details ───────────────────────────────────────────────
    // Eyes (Kawaii style)
    final eyeRadius = w * 0.07;
    final leftEye = headPos + Offset(-w * 0.06, h * 0.02);
    final rightEye = headPos + Offset(w * 0.08, h * 0.02);

    final blackPaint = Paint()..color = const Color(0xFF1A1A1A);
    final whitePaint = Paint()..color = Colors.white;

    // Draw Black Iris
    canvas.drawCircle(leftEye, eyeRadius, blackPaint);
    canvas.drawCircle(rightEye, eyeRadius, blackPaint);

    // Highlights
    canvas.drawCircle(leftEye + Offset(-w * 0.02, -h * 0.02), w * 0.025, whitePaint);
    canvas.drawCircle(leftEye + Offset(w * 0.015, h * 0.015), w * 0.012, whitePaint);

    canvas.drawCircle(rightEye + Offset(-w * 0.02, -h * 0.02), w * 0.025, whitePaint);
    canvas.drawCircle(rightEye + Offset(w * 0.015, h * 0.015), w * 0.012, whitePaint);

    // Happy Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFFE91E63)
      ..style = PaintingStyle.fill;

    final mouthRect = Rect.fromCenter(
      center: headPos + Offset(w * 0.02, h * 0.1),
      width: w * 0.08,
      height: h * 0.06,
    );
    canvas.drawArc(mouthRect, 0, math.pi, true, mouthPaint);

    // ── 4. The Crown (Distinct Design) ────────────────────────────────
    final crownPaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final crownPath = Path();
    final cp = headPos + Offset(0, -h * 0.16); // Crown position
    final cw = w * 0.12; // Crown width
    final ch = h * 0.1; // Crown height

    crownPath.moveTo(cp.dx - cw, cp.dy);
    crownPath.lineTo(cp.dx - cw * 1.2, cp.dy - ch);
    crownPath.lineTo(cp.dx - cw * 0.4, cp.dy - ch * 0.6);
    crownPath.lineTo(cp.dx, cp.dy - ch * 1.2); // Center point taller
    crownPath.lineTo(cp.dx + cw * 0.4, cp.dy - ch * 0.6);
    crownPath.lineTo(cp.dx + cw * 1.2, cp.dy - ch);
    crownPath.lineTo(cp.dx + cw, cp.dy);
    crownPath.close();

    // Add small circles at the tips of the crown
    canvas.drawPath(crownPath, crownPaint);
    canvas.drawCircle(Offset(cp.dx - cw * 1.2, cp.dy - ch), w * 0.015, crownPaint);
    canvas.drawCircle(Offset(cp.dx, cp.dy - ch * 1.2), w * 0.015, crownPaint);
    canvas.drawCircle(Offset(cp.dx + cw * 1.2, cp.dy - ch), w * 0.015, crownPaint);

    // Crown jewels
    final jewelPaint = Paint()..color = Colors.cyanAccent;
    canvas.drawCircle(cp + Offset(0, -ch * 0.4), w * 0.01, jewelPaint);
  }

  double _lerpBezier(double start, double control, double end, double t) {
    return (1 - t) * (1 - t) * start + 2 * (1 - t) * t * control + t * t * end;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
