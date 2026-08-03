import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';
import 'package:serpiente_io/src/data/persistence/game_preferences.dart';
import 'package:serpiente_io/src/game/models/game_mode.dart';
import 'package:serpiente_io/src/game/skins/skin_repository.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';
import 'package:serpiente_io/src/presentation/screens/game_screen.dart';
import 'package:serpiente_io/src/presentation/screens/skin_selection_screen.dart';

/// Pantalla del menú principal optimizada para dispositivos móviles en modo landscape.
/// Todo el contenido cabe perfectamente en pantalla sin necesidad de scroll.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final SkinRepository _skinRepository = SkinRepository();
  String _selectedSkinId = GamePreferences.selectedSkinId;

  void _openSkinSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkinSelectionScreen(
          selectedSkinId: _selectedSkinId,
          onSkinSelected: (skinId) async {
            await GamePreferences.setSelectedSkinId(skinId);
            setState(() {
              _selectedSkinId = skinId;
            });
          },
        ),
      ),
    );
  }

  SnakeSkin get _selectedSkin => _skinRepository.getSkinById(_selectedSkinId);

  void _startGame(GameMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          selectedSkinId: _selectedSkinId,
          mode: mode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // ── Barra Superior (User Info + Stats) ──────────────────────────
                _buildTopBar(context),
                const SizedBox(height: 12),

                // ── Centro Principal (Tarjeta del juego & Selección de Skin) ─────
                Expanded(
                  child: Row(
                    children: [
                      // Panel Izquierdo: Tarjeta de partida rápida
                      Expanded(
                        flex: 3,
                        child: _buildPlayCard(context),
                      ),
                      const SizedBox(width: 14),

                      // Panel Derecho: Visualizador de Skin actual
                      Expanded(
                        flex: 2,
                        child: _buildSkinPreviewCard(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        // Avatar + Nombre de usuario
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: 8),
              const Text(
                'Jugador',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Stats: High Score & Monedas
        _buildHeaderStat(Icons.emoji_events_rounded, '${GamePreferences.highScore}', AppColors.neonOrange),
        const SizedBox(width: 10),
        _buildHeaderStat(Icons.monetization_on_rounded, '${GamePreferences.coins}', AppColors.accent),
      ],
    );
  }

  Widget _buildHeaderStat(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'SERPIENTE.IO',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                ),
                child: const Text(
                  'MODO OFFLINE',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            '¡Comite a los orbes, destruye las serpientes rivales y conviértete en el líder de la arena!',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const Spacer(),

          // Botón Jugar Offline
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startGame(GameMode.offline),
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text('JUGAR AHORA (BOTS)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 6,
                shadowColor: AppColors.accent.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Vista previa visual de la skin seleccionada
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: _selectedSkin.gradientColors),
              boxShadow: [
                BoxShadow(
                  color: _selectedSkin.accentColor.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.pets_rounded,
              color: _selectedSkin.accentColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedSkin.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Skin Activa',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: _openSkinSelection,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'CAMBIAR SKIN',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
