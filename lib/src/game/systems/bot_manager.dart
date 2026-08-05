import 'dart:math';
import 'package:flame/components.dart';
import 'package:serpiente_io/src/core/events/event_bus.dart';
import 'package:serpiente_io/src/core/events/game_events.dart';
import 'package:serpiente_io/src/game/components/bot_snake_component.dart';
import 'package:serpiente_io/src/game/input/bot_input.dart';
import 'package:serpiente_io/src/game/logic/snake_logic.dart';
import 'package:serpiente_io/src/game/models/bot_entry.dart';
import 'package:serpiente_io/src/game/models/snake_model.dart';
import 'package:serpiente_io/src/game/renderers/snake_renderer.dart';
import 'package:serpiente_io/src/game/skins/skin_repository.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';
import 'package:serpiente_io/src/game/systems/collision_system.dart';
import 'package:serpiente_io/src/game/systems/orb_manager.dart';

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

  void clear() {
    for (final bot in bots) {
      bot.component.removeFromParent();
    }
    bots.clear();
  }

  void spawnBots(int count) {
    final skinRepo = SkinRepository();
    final names = ['Víbora', 'Cobra', 'Anaconda', 'Mamba', 'Pitón', 'Boa', 'Taipán', 'Cascabel', 'Dragón', 'Rex'];
    for (var i = 0; i < count; i++) {
      spawnBot('bot_$i', names[i % names.length], skinRepo.availableSkins[i % skinRepo.availableSkins.length]);
    }
  }

  void spawnBot(String id, String name, SnakeSkin skin) {
    final angle = _rng.nextDouble() * 2 * pi;
    final pos = randomPos();
    final initSegs = buildInitialSegments(pos, angle, 8);

    final model = SnakeModel(
      id: id,
      isPlayer: false,
      skin: skin,
      segments: initSegs,
      currentAngle: angle,
      targetAngle: angle,
      segmentRadius: CollisionSystem.botSegRadius,
    );

    final logic = SnakeLogic();
    logic.resetHistory(model);

    final input = BotInput(mapSize: mapSize, initialAngle: angle);
    final renderer = SnakeRenderer(model);

    final component = BotSnakeComponent(
      name: name,
      model: model,
      logic: logic,
      renderer: renderer,
      input: input,
    );

    final entry = BotEntry(
      id: id,
      name: name,
      component: component,
      input: input,
      logic: logic,
      model: model,
    );

    bots.add(entry);
    world.add(component);
  }

  void updateBots({
    required double dt,
    required List<Vector2> playerSegments,
    required bool isGameOver,
  }) {
    final orbPositions = orbManager.orbs.map((o) => o.position).toList();

    for (final bot in bots.toList()) {
      final input = bot.input;
      final model = bot.model;
      if (model.segments.isEmpty) continue;

      final rivals = <Vector2>[
        ...playerSegments,
        for (final other in bots) if (other.id != bot.id) ...other.model.segments,
      ];

      final rivalHeads = <Vector2>[
        if (!isGameOver && playerSegments.isNotEmpty) playerSegments.first,
        for (final other in bots) if (other.id != bot.id && other.model.segments.isNotEmpty) other.model.segments.first,
      ];

      input.think(
        headPos: model.segments.first,
        orbPositions: orbPositions,
        rivalSegments: rivals,
        rivalHeads: rivalHeads,
        mySegmentCount: model.segments.length,
        dt: dt,
        currentAngle: model.currentAngle,
      );

      final previousHead = model.segments.isNotEmpty ? model.segments.first.clone() : null;

      // La lógica se actualiza automáticamente a través del componente SnakeComponent.update(dt)
      // pero aquí comprobamos colisiones.

      if (collisionSystem.isOutOfBoundsBot(model.segments.first) ||
          collisionSystem.collidesWithSnake(
              model.segments.first,
              playerSegments,
              CollisionSystem.botSegRadius,
              CollisionSystem.playerSegRadius,
              previousHead: previousHead)) {
        killBot(bot);
        continue;
      }

      bool botDied = false;
      for (final other in bots) {
        if (other.id == bot.id) continue;
        if (collisionSystem.collidesWithSnake(
            model.segments.first,
            other.model.segments,
            CollisionSystem.botSegRadius,
            CollisionSystem.botSegRadius,
            previousHead: previousHead)) {
          killBot(bot);
          botDied = true;
          break;
        }
      }
      if (botDied) continue;

      // Recolección de orbes
      final orbValues = orbManager.checkHeadCollisions(model.segments.first, model.segmentRadius);
      for (final val in orbValues) {
        model.segments.add(model.segments.last.clone());
        EventBus().fire(OrbCollectedEvent(collectorId: bot.id, isPlayer: false, value: val));
      }

      // Caída de masa por boost
      if (model.pendingMassDrop > 0) {
        final tail = model.segments.last;
        orbManager.spawnOrbsAt(List.generate(
          model.pendingMassDrop,
          (_) => Vector2(tail.x + (_rng.nextDouble() - 0.5) * 20, tail.y + (_rng.nextDouble() - 0.5) * 20),
        ), value: 3);
        model.pendingMassDrop = 0;
      }
    }
  }

  void killBot(BotEntry bot) {
    EventBus().fire(SnakeDeadEvent(
      snakeId: bot.id,
      isPlayer: false,
      deathPosition: bot.model.segments.isNotEmpty ? bot.model.segments.first.clone() : Vector2.zero(),
    ));

    final drops = bot.model.segments
        .where((s) => !collisionSystem.isOutOfBoundsBot(s))
        .take((bot.model.segments.length * 0.4).round())
        .map((s) => s.clone())
        .toList();
    orbManager.spawnOrbsAt(drops, value: 3);

    if (drops.isNotEmpty) {
      final dropCenter = drops.first;
      for (final nb in bots.where((b) => b.id != bot.id)) {
        if (nb.model.segments.isNotEmpty && nb.model.segments.first.distanceTo(dropCenter) < 600) {
          nb.input.notifyOrbDrop(drops);
        }
      }
    }

    bots.remove(bot);
    bot.component.removeFromParent();

    Future.delayed(const Duration(seconds: 4), () {
      final skinRepo = SkinRepository();
      spawnBot(bot.id, 'Bot_${_rng.nextInt(99)}', skinRepo.availableSkins[_rng.nextInt(skinRepo.availableSkins.length)]);
    });
  }

  Vector2 randomPos() {
    const margin = 150.0;
    return Vector2(margin + _rng.nextDouble() * (mapSize - margin * 2), margin + _rng.nextDouble() * (mapSize - margin * 2));
  }

  List<Vector2> buildInitialSegments(Vector2 head, double angle, int count) =>
      List.generate(count, (i) => Vector2(head.x - cos(angle) * i * 14.0, head.y - sin(angle) * i * 14.0));
}
