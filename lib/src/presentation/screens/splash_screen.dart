import 'dart:async';

import 'package:flutter/material.dart';
import 'package:serpiente_io/src/presentation/screens/main_menu_screen.dart';
import 'package:serpiente_io/src/core/constants/app_colors.dart';
import 'package:serpiente_io/src/presentation/widgets/game_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      setState(() {
        _progress += 0.08;
        if (_progress >= 1) {
          _progress = 1;
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const MainMenuScreen(),
              ),
            );
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const RadialGradient(
                            colors: [AppColors.accent, AppColors.accentSoft],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withAlpha(89),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 72,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Cargando partida...',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Preparando tu experiencia Snake.io con skins, niveles y partida rápida.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 38),
                      Stack(
                        children: [
                          Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 20,
                            width: MediaQuery.of(context).size.width * _progress,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.accent, AppColors.accentSoft],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(_progress * 100).ceil()} %',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Hecho: Las serpientes pueden comer casi cualquier cosa.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
