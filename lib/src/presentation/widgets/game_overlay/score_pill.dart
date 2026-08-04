import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';

class ScorePill extends StatelessWidget {
  final int score;
  const ScorePill({super.key, required this.score});

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
