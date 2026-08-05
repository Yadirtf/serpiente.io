/// Modelo de datos para el perfil del usuario.
class UserProfile {
  final String name;
  final String avatarPath;
  final String uid;

  const UserProfile({
    required this.name,
    required this.avatarPath,
    required this.uid,
  });

  /// Perfil por defecto para la primera versión.
  factory UserProfile.defaultProfile() {
    return const UserProfile(
      name: 'Jugador',
      avatarPath: 'assets/icon/images/avatars/default.png',
      uid: 'UID: 12023A788F72',
    );
  }
}
