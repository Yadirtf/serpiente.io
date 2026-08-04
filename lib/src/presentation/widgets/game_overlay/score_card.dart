import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';

class ScoreCard extends StatelessWidget {
  final int score;
  final int highScore;
  final Color primaryColor;
  final bool isCompact;

  const ScoreCard({
    super.key,
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
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
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
