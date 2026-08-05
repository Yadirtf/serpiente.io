import 'package:serpiente_io/src/game/interfaces/input_source.dart';

/// Implementación de entrada para un jugador humano.
/// Recibe actualizaciones externas desde el joystick o eventos táctiles.
class HumanInput implements InputSource {
  double _angle = 0.0;
  bool _boosting = false;

  void updateAngle(double angle) {
    _angle = angle;
  }

  void updateBoosting(bool boosting) {
    _boosting = boosting;
  }

  @override
  double getAngle() => _angle;

  @override
  bool isBoosting() => _boosting;
}
