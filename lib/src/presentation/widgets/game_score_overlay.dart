import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';

class GameScoreOverlay extends StatelessWidget {
  final int score;

  const GameScoreOverlay({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withAlpha(220),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.star, color: AppColors.accent, size: 20),
            const SizedBox(width: 10),
            Text(
              'Puntaje: $score',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
