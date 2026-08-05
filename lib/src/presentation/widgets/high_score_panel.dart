import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';

class HighScorePanel extends StatelessWidget {
  final int score;

  const HighScorePanel({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'MEJOR PUNTUACIÓN',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        Text(
          score.toString(),
          style: const TextStyle(
            color: AppColors.neonOrange,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 1.1,
            shadows: [
              Shadow(
                color: AppColors.neonOrange,
                blurRadius: 15,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
