import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';
import 'package:serpiente_io/src/game/skins/skin_repository.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';
import 'package:serpiente_io/src/presentation/widgets/game_logo.dart';

class SkinSelectionScreen extends StatelessWidget {
  final String selectedSkinId;
  final ValueChanged<String> onSkinSelected;

  SkinSelectionScreen({
    super.key,
    required this.selectedSkinId,
    required this.onSkinSelected,
  });

  final SkinRepository _repository = SkinRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundStart,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con botón volver
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'SELECCIONAR SKIN',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Lista de skins en Grid Horizontal/Vertical
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _repository.availableSkins.length,
                  itemBuilder: (context, index) {
                    final skin = _repository.availableSkins[index];
                    final isSelected = skin.id == selectedSkinId;
                    return _SkinCard(
                      skin: skin,
                      isSelected: isSelected,
                      onTap: () {
                        onSkinSelected(skin.id);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkinCard extends StatelessWidget {
  final SnakeSkin skin;
  final bool isSelected;
  final VoidCallback onTap;

  const _SkinCard({
    required this.skin,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Círculo del color de la skin
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: skin.gradientColors),
              ),
              child: Icon(Icons.pets, color: skin.accentColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    skin.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSelected ? 'SELECCIONADA' : 'TOCAR PARA USAR',
                    style: TextStyle(
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 24),
          ],
        ),
      ),
    );
  }
}
