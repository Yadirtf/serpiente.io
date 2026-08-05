import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

class SnakeEditorButton extends StatelessWidget {
  final SnakeSkin currentSkin;
  final VoidCallback onPressed;
  final bool hasNotifications;

  const SnakeEditorButton({
    super.key,
    required this.currentSkin,
    required this.onPressed,
    this.hasNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Botón principal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vista previa de la skin
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: currentSkin.gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentSkin.accentColor.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.brush,
                    size: 16,
                    color: currentSkin.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'EDITAR SERPIENTE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Indicador de notificaciones
          if (hasNotifications)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
