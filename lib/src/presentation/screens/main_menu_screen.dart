import 'package:flutter/material.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';
import 'package:serpiente_io/src/data/persistence/game_preferences.dart';
import 'package:serpiente_io/src/domain/models/game_mode_info.dart';
import 'package:serpiente_io/src/domain/models/user_profile.dart';
import 'package:serpiente_io/src/game/models/game_mode.dart';
import 'package:serpiente_io/src/game/skins/skin_repository.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';
import 'package:serpiente_io/src/presentation/screens/game_screen.dart';
import 'package:serpiente_io/src/presentation/screens/skin_selection_screen.dart';
import 'package:serpiente_io/src/presentation/widgets/game_mode_carousel.dart';
import 'package:serpiente_io/src/presentation/widgets/high_score_panel.dart';
import 'package:serpiente_io/src/presentation/widgets/jungle_background.dart';
import 'package:serpiente_io/src/presentation/widgets/profile_panel.dart';
import 'package:serpiente_io/src/presentation/widgets/snake_editor_button.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final SkinRepository _skinRepository = SkinRepository();
  String _selectedSkinId = GamePreferences.selectedSkinId;
  int _selectedModeIndex = 0;

  final List<GameModeInfo> _availableModes = const [
    GameModeInfo(
      mode: GameMode.offline,
      title: 'Offline',
      description: 'Juega contra bots sin conexión a internet.',
      imagePath: 'assets/images/modes/offline.png',
      iconLabel: 'BOTS',
    ),
    GameModeInfo(
      mode: GameMode.online,
      title: 'Online',
      description: 'Compite contra jugadores de todo el mundo.',
      imagePath: 'assets/images/modes/online.png',
      status: GameModeStatus.upcoming,
      iconLabel: 'LIVE',
    ),
    GameModeInfo(
      mode: GameMode.lan,
      title: 'Red Local',
      description: 'Crea partidas en tu Wi-Fi local para amigos.',
      imagePath: 'assets/images/modes/lan.png',
      status: GameModeStatus.upcoming,
      iconLabel: 'WIFI',
    ),
  ];

  SnakeSkin get _selectedSkin => _skinRepository.getSkinById(_selectedSkinId);
  GameModeInfo get _selectedMode => _availableModes[_selectedModeIndex];

  void _openSkinSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SkinSelectionScreen(
          selectedSkinId: _selectedSkinId,
          onSkinSelected: (skinId) async {
            await GamePreferences.setSelectedSkinId(skinId);
            setState(() => _selectedSkinId = skinId);
          },
        ),
      ),
    );
  }

  void _startGame() {
    if (!_selectedMode.isAvailable) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          selectedSkinId: _selectedSkinId,
          mode: _selectedMode.mode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: JungleBackground(
        child: SafeArea(
          child: Stack(
            children: [
              // 1. Panel de Perfil (Esquina superior izquierda)
              Positioned(
                top: 20,
                left: 20,
                child: ProfilePanel(
                  profile: UserProfile.defaultProfile(),
                  onSettingsPressed: () {
                    // TODO: Implementar ajustes
                  },
                  onEditPressed: () {
                    // TODO: Implementar edición de perfil
                  },
                ),
              ),

              // 2. Panel de Mejor Puntaje (Centrado superior)
              const Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: HighScorePanel(score: 12500), // Ejemplo estático por ahora
                ),
              ),

              // 3. Carrusel Central de Modos
              Positioned(
                top: 130,
                bottom: 110,
                left: 0,
                right: 0,
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: GameModeCarousel(
                    modes: _availableModes,
                    onModeChanged: (index) {
                      setState(() => _selectedModeIndex = index);
                    },
                  ),
                ),
              ),

              // 4. Controles Inferiores
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Botón Editar Serpiente
                    SnakeEditorButton(
                      currentSkin: _selectedSkin,
                      onPressed: _openSkinSelection,
                      hasNotifications: true,
                    ),
                    const SizedBox(height: 20),

                    // Botón Jugar
                    _PlayButton(
                      onPressed: _startGame,
                      isAvailable: _selectedMode.isAvailable,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isAvailable;

  const _PlayButton({required this.onPressed, required this.isAvailable});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.5,
      child: Container(
        width: 220,
        height: 64,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.accentSoft],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isAvailable ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: const Text(
            'JUGAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    );
  }
}
