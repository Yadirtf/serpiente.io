/// Modos de juego disponibles en la aplicación.
///
/// La arquitectura está diseñada para que la lógica de juego sea independiente
/// del modo, permitiendo agregar el modo online en el futuro sin refactorizar
/// el motor de juego.
enum GameMode {
  /// Modo offline: el jugador compite contra bots controlados localmente.
  /// No requiere conexión a internet.
  offline,

  /// Modo online (futura implementación): sala con jugadores reales conectados
  /// a través de websockets / servidor dedicado.
  /// La lógica del servidor reemplaza a los bots locales.
  online,

  /// Modo red local (futura implementación): permite jugar con amigos en la misma red Wi-Fi.
  /// Un dispositivo actúa como host y los demás se conectan como clientes.
  lan,
}
