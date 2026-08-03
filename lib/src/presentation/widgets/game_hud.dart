import 'package:flutter/material.dart';
import 'package:serpiente_io/src/presentation/widgets/boost_button.dart';
import 'package:serpiente_io/src/presentation/widgets/neon_joystick.dart';

/// HUD de juego en landscape.
///
/// Layout:
/// - Joystick neon (360°) — esquina inferior izquierda.
/// - Botón boost — esquina inferior derecha.
///
/// El HUD pasa el ángulo continuo directamente al juego a través de
/// [onAngleChanged], eliminando la conversión a 4 direcciones cardinales.
class GameHud extends StatelessWidget {
  /// Callback con el ángulo en radianes (null = stick en reposo).
  final void Function(double? angle) onAngleChanged;

  /// Callback cuando el boost cambia de estado.
  final void Function(bool isBoosting) onBoostChanged;

  /// Nivel de energía del boost (0.0 – 1.0), para el arco del botón.
  final double energyLevel;

  const GameHud({
    super.key,
    required this.onAngleChanged,
    required this.onBoostChanged,
    this.energyLevel = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Joystick inferior izquierdo ────────────────────────────────
        Positioned(
          left: 20,
          bottom: 20,
          child: NeonJoystick(
            size: 160,
            deadZone: 10,
            onAngleChanged: onAngleChanged,
          ),
        ),

        // ── Botón boost inferior derecho ───────────────────────────────
        Positioned(
          right: 20,
          bottom: 28,
          child: BoostButton(
            size: 88,
            energyLevel: energyLevel,
            onBoostChanged: onBoostChanged,
          ),
        ),
      ],
    );
  }
}
