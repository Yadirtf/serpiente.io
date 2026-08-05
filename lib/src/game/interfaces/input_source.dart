/// Interfaz abstracta para definir una fuente de entrada de control.
/// Puede ser un humano (touch/teclado), una IA (Bot) o datos de red.
abstract class InputSource {
  /// Devuelve el ángulo objetivo actual en radianes.
  double getAngle();

  /// Indica si se está solicitando la activación del boost.
  bool isBoosting();
}
