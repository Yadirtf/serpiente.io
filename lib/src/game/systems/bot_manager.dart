import 'dart:math';
import 'package:flame/components.dart';
import 'package:serpiente_io/src/game/components/bot_snake_component.dart';
import 'package:serpiente_io/src/game/controllers/bot_controller.dart';
import 'package:serpiente_io/src/game/skins/skin_repository.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';
import 'package:serpiente_io/src/game/systems/collision_system.dart';
import 'package:serpiente_io/src/game/systems/orb_manager.dart';

/// Gestor del ciclo de vida, IA, colisiones y respawn de bots.
class BotManager {
  final World world;
  final double mapSize;
  final CollisionSystem collisionSystem;
  final OrbManager orbManager;
  final List<BotEntry> bots = [];
  final Random _rng = Random();

  BotManager({
    required this.world,
    required this.mapSize,
    required this.collisionSystem,
    required this.orbManager,
  });

  /// Limpia los bots existentes del mundo.
  void clear() {
    for (final bot in bots) {
      bot.component.removeFromParent();
    }
    bots.clear();
  }

  /// Spawn inicial de bots.
  void spawnBots(int count) {
    final skinRepo = SkinRepository();
    final names = [
      'Víbora', 'Cobra', 'Anaconda', 'Mamba', 'Pitón',
      'Boa', 'Taipán', 'Cascabel', 'Dragón', 'Rex',
    ];
    for (var i = 0; i < count; i++) {
      spawnBot(
        'bot_$i',
        names[i % names.length],
        skinRepo.availableSkins[i % skinRepo.availableSkins.length],
      );
    }
  }

  /// Spawnea una serpiente bot individual.
  void spawnBot(String id, String name, SnakeSkin skin) {
    final angle = _rng.nextDouble() * 2 * pi;
    final pos = randomPos();
    final initSegs = buildInitialSegments(pos, angle, 8);
    final ctrl = BotController(botName: name, mapSize: mapSize, initialAngle: angle);
    ctrl.resetHistory(initSegs);

    final entry = BotEntry(
      id: id,
      name: name,
      skin: skin,
      initialSegments: initSegs,
      controller: ctrl,
    );

    bots.add(entry);
    world.add(entry.component);
  }

  /// Actualiza el comportamiento y movimiento de todos los bots.
  void updateBots({
    required double dt,
    required List<Vector2> playerSegments,
    required bool isGameOver,
  }) {
    final orbPositions = orbManager.orbs.map((o) => o.position).toList();

    for (final bot in bots.toList()) {
      final ctrl = bot.controller;
      final segs = bot.component.segments;
      if (segs.isEmpty) continue;

      // Segmentos rivales: jugador + otros bots
      final rivals = <Vector2>[
        ...playerSegments,
        for (final other in bots)
          if (other.id != bot.id) ...other.component.segments,
      ];

      // Cabezas rivales
      final rivalHeads = <Vector2>[
        if (!isGameOver && playerSegments.isNotEmpty) playerSegments.first,
        for (final other in bots)
          if (other.id != bot.id && other.component.segments.isNotEmpty)
            other.component.segments.first,
      ];

      ctrl.think(
        headPos: segs.first,
        orbPositions: orbPositions,
        rivalSegments: rivals,
        rivalHeads: rivalHeads,
        mySegmentCount: segs.length,
        dt: dt,
      );

      final previousHead = segs.isNotEmpty ? segs.first.clone() : null;
      final nextBotSegs = ctrl.move(segs, dt);

      // Colisión bot con borde o cuerpo del jugador → bot muere
      if (collisionSystem.isOutOfBoundsBot(nextBotSegs.first) ||
          collisionSystem.collidesWithSnake(
              nextBotSegs.first,
              playerSegments,
              CollisionSystem.botSegRadius,
              CollisionSystem.playerSegRadius,
              previousHead: previousHead)) {
        killBot(bot);
        continue;
      }

      // Colisión bot con otros bots → bot muere
      bool botDied = false;
      for (final other in bots) {
        if (other.id == bot.id) continue;
        if (collisionSystem.collidesWithSnake(
            nextBotSegs.first,
            other.component.segments,
            CollisionSystem.botSegRadius,
            CollisionSystem.botSegRadius,
            previousHead: previousHead)) {
          killBot(bot);
          botDied = true;
          break;
        }
      }
      if (botDied) continue;

      bot.component.updateSegments(nextBotSegs);

      // Recolección de orbes por bot
      if (bot.component.segments.isNotEmpty) {
        final orbValues = orbManager.checkHeadCollisions(bot.component.segments.first, bot.component.segmentRadius);
        for (final _ in orbValues) {
          bot.component.segments.add(bot.component.segments.last.clone());
        }
      }

      // Caída de masa por boost de bot
      final botDrop = ctrl.consumePendingMassDrop();
      if (botDrop > 0 && bot.component.segments.isNotEmpty) {
        final tail = bot.component.segments.last;
        orbManager.spawnOrbsAt(List.generate(
          botDrop,
          (_) => Vector2(
            tail.x + (_rng.nextDouble() - 0.5) * 20,
            tail.y + (_rng.nextDouble() - 0.5) * 20,
          ),
        ), value: 3);
      }
    }
  }

  /// Elimina un bot del mapa, convierte su cuerpo en orbes y programa su respawn.
  void killBot(BotEntry bot) {
    final drops = bot.component.segments
        .where((s) => !collisionSystem.isOutOfBoundsBot(s))
        .take((bot.component.segments.length * 0.4).round())
        .map((s) => s.clone())
        .toList();
    orbManager.spawnOrbsAt(drops, value: 3);

    if (drops.isNotEmpty) {
      final dropCenter = drops.first;
      final nearbyBots = bots
          .where((b) =>
              b.id != bot.id &&
              b.component.segments.isNotEmpty &&
              b.component.segments.first.distanceTo(dropCenter) < 600)
          .toList()
        ..sort((a, b2) => a.component.segments.first
            .distanceTo(dropCenter)
            .compareTo(b2.component.segments.first.distanceTo(dropCenter)));

      for (final nb in nearbyBots.take(3)) {
        nb.controller.notifyOrbDrop(drops);
      }
    }

    bots.remove(bot);
    bot.component.removeFromParent();

    // Respawn programado después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      final skinRepo = SkinRepository();
      final idx = _rng.nextInt(skinRepo.availableSkins.length);
      spawnBot(bot.id, 'Bot_${_rng.nextInt(99)}', skinRepo.availableSkins[idx]);
    });
  }

  Vector2 randomPos() {
    const margin = 150.0;
    return Vector2(
      margin + _rng.nextDouble() * (mapSize - margin * 2),
      margin + _rng.nextDouble() * (mapSize - margin * 2),
    );
  }

  List<Vector2> buildInitialSegments(Vector2 head, double angle, int count) =>
      List.generate(
        count,
        (i) => Vector2(
          head.x - cos(angle) * i * 14.0,
          head.y - sin(angle) * i * 14.0,
        ),
      );
}
