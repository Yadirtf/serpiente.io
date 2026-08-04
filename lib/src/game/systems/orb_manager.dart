import 'dart:math';
import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/components/orb_component.dart';

/// Manejador del ciclo de vida, spawn, recolección y atracción electromagnética de orbes.
class OrbManager {
  final World world;
  final double mapSize;
  final List<OrbComponent> orbs = [];
  final Random _rng = Random();

  static const double orbRadius = 7.0;
  static const int targetOrbCount = 100;
  static const double magnetRadius = 45.0;
  static const double magnetSpeed = 650.0;

  OrbManager({
    required this.world,
    required this.mapSize,
  });

  /// Limpia los orbes existentes del mundo.
  void clear() {
    for (final orb in orbs) {
      orb.removeFromParent();
    }
    orbs.clear();
  }

  /// Genera orbes aleatorios en el mapa.
  void spawnOrbs({required int count, int value = 1}) {
    for (var i = 0; i < count; i++) {
      final orb = OrbComponent(position: randomPos(), value: value);
      orbs.add(orb);
      world.add(orb);
    }
  }

  /// Genera orbes en posiciones específicas (drop por boost o por muerte de serpiente).
  void spawnOrbsAt(List<Vector2> positions, {int value = 1}) {
    for (final pos in positions) {
      final orb = OrbComponent(position: pos.clone(), value: value);
      orbs.add(orb);
      world.add(orb);
    }
  }

  /// Mantiene la densidad mínima de orbes en el mapa.
  void maintainDensity() {
    if (orbs.length < targetOrbCount ~/ 2) {
      spawnOrbs(count: 15);
    }
  }

  /// Aplica la física de atracción electromagnética de orbes hacia las cabezas de serpientes cercanas.
  void updateMagnet(List<Vector2> activeHeads, double dt) {
    if (orbs.isEmpty || activeHeads.isEmpty) return;

    for (final orb in orbs) {
      Vector2? closestHead;
      double minDist = magnetRadius;

      for (final head in activeHeads) {
        final d = orb.position.distanceTo(head);
        if (d < minDist) {
          minDist = d;
          closestHead = head;
        }
      }

      if (closestHead != null && minDist > 1.0) {
        final dir = (closestHead - orb.position)..normalize();
        orb.position.addScaled(dir, magnetSpeed * dt);
      }
    }
  }

  /// Verifica colisiones de una cabeza dada con todos los orbes activos.
  /// Retorna los valores puntuales de los orbes consumidos.
  List<int> checkHeadCollisions(Vector2 head, double segmentRadius) {
    if (orbs.isEmpty) return const [];
    final hitR = segmentRadius + orbRadius;

    final hitList = orbs.where((o) => o.position.distanceTo(head) < hitR).toList();
    for (final orb in hitList) {
      orbs.remove(orb);
      orb.removeFromParent();
    }
    return hitList.map((orb) => orb.value).toList();
  }

  Vector2 randomPos() {
    const margin = 150.0;
    return Vector2(
      margin + _rng.nextDouble() * (mapSize - margin * 2),
      margin + _rng.nextDouble() * (mapSize - margin * 2),
    );
  }
}
