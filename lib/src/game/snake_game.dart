import 'dart:math';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:serpiente_io/src/game/components/arena_background_component.dart';
import 'package:serpiente_io/src/game/components/snake_component.dart';
import 'package:serpiente_io/src/game/controllers/snake_controller.dart';
import 'package:serpiente_io/src/game/models/game_mode.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';
import 'package:serpiente_io/src/game/systems/bot_manager.dart';
import 'package:serpiente_io/src/game/systems/collision_system.dart';
import 'package:serpiente_io/src/game/systems/orb_manager.dart';

/// Motor principal de juego Serpiente.io coordinando subsistemas modulares.
class SnakeGame extends FlameGame {
  final SnakeSkin initialSkin;
  final GameMode mode;
  final int botCount;

  late SnakeComponent snakeComponent;
  late SnakeController snakeController;
  late PositionComponent playerCameraTarget;

  late CollisionSystem collisionSystem;
  late OrbManager orbManager;
  late BotManager botManager;

  int score = 0;
  bool _isGameOver = false;
  final ValueNotifier<bool> isGameOverNotifier = ValueNotifier(false);
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isBoostingNotifier = ValueNotifier(false);

  final _rng = Random();
  static const double _kMapSize = 2400;
  static const double _kDeathCameraOffset = 60.0;

  SnakeGame({
    required this.initialSkin,
    this.mode = GameMode.offline,
    this.botCount = 8,
  });

  @override
  Color backgroundColor() => const Color(0xFF0A0F1D);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    collisionSystem = CollisionSystem(mapSize: _kMapSize);
    orbManager = OrbManager(world: world, mapSize: _kMapSize);
    botManager = BotManager(
      world: world,
      mapSize: _kMapSize,
      collisionSystem: collisionSystem,
      orbManager: orbManager,
    );

    _initGame();
  }

  void _initGame() {
    score = 0;
    _isGameOver = false;
    isGameOverNotifier.value = false;
    scoreNotifier.value = 0;
    isBoostingNotifier.value = false;

    world.removeAll(world.children);
    orbManager.clear();
    botManager.clear();

    // 1. Fondo de la arena
    world.add(ArenaBackgroundComponent(mapSize: _kMapSize));

    // 2. Jugador
    snakeController = SnakeController(speed: 155, initialAngle: 0);
    final playerStart = orbManager.randomPos();
    final initSegs = buildInitialSegments(playerStart, 0, 7);

    snakeComponent = SnakeComponent(
      skin: initialSkin,
      isPlayer: true,
      initialSegments: initSegs,
      segmentRadius: CollisionSystem.playerSegRadius,
    );
    snakeController.resetHistory(initSegs);
    world.add(snakeComponent);

    // Cámara
    playerCameraTarget = PositionComponent(position: playerStart.clone());
    world.add(playerCameraTarget);
    camera.follow(playerCameraTarget);

    // 3. Bots
    if (mode == GameMode.offline) {
      botManager.spawnBots(botCount);
    }

    // 4. Orbes iniciales
    orbManager.spawnOrbs(count: OrbManager.targetOrbCount);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isGameOver) {
      _updatePlayer(dt);
    }

    if (mode == GameMode.offline) {
      botManager.updateBots(
        dt: dt,
        playerSegments: snakeComponent.segments,
        isGameOver: _isGameOver,
      );
    }

    // Actualizar imán de orbes
    final activeHeads = <Vector2>[
      if (!_isGameOver && snakeComponent.segments.isNotEmpty)
        snakeComponent.segments.first,
      for (final bot in botManager.bots)
        if (bot.component.segments.isNotEmpty) bot.component.segments.first,
    ];
    orbManager.updateMagnet(activeHeads, dt);
    orbManager.maintainDensity();
  }

  void _updatePlayer(double dt) {
    final previousHead = snakeComponent.segments.isNotEmpty
        ? snakeComponent.segments.first.clone()
        : null;
    final nextSegs = snakeController.move(snakeComponent.segments, dt);

    if (collisionSystem.isOutOfBoundsPlayer(nextSegs.first) ||
        collisionSystem.collidesWithBotsPlayer(nextSegs.first, botManager.bots, previousHead: previousHead)) {
      _handleGameOver();
      return;
    }

    snakeComponent.updateSegments(nextSegs);

    if (snakeComponent.segments.isNotEmpty) {
      playerCameraTarget.position.setFrom(snakeComponent.segments.first);
    }

    // Masa perdida en boost por el jugador
    final massDrop = snakeController.consumePendingMassDrop();
    if (massDrop > 0 && snakeComponent.segments.isNotEmpty) {
      final tail = snakeComponent.segments.last;
      final droppedOrbs = List.generate(
        massDrop,
        (_) => Vector2(
          tail.x + (_rng.nextDouble() - 0.5) * 22,
          tail.y + (_rng.nextDouble() - 0.5) * 22,
        ),
      );
      orbManager.spawnOrbsAt(droppedOrbs, value: 1);
      for (var i = 0; i < massDrop; i++) {
        applyOrbScore(-1);
      }
    }

    _checkPlayerOrbCollision();
    isBoostingNotifier.value = snakeController.isBoosting;
  }

  void _checkPlayerOrbCollision() {
    if (snakeComponent.segments.isEmpty) return;
    final head = snakeComponent.segments.first;

    final orbValues = orbManager.checkHeadCollisions(head, snakeComponent.segmentRadius);
    if (orbValues.isEmpty) return;

    if (snakeComponent.segments.isNotEmpty) {
      snakeComponent.segments.add(snakeComponent.segments.last.clone());
    }

    for (final orbValue in orbValues) {
      applyOrbScore(orbValue);
    }
  }

  void applyOrbScore(int points) {
    if (points == 0) return;
    score = max(0, score + points);
    scoreNotifier.value = score;
  }

  void _handleGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;

    snakeComponent.segments.clear();

    if (playerCameraTarget.position.y > _kDeathCameraOffset) {
      playerCameraTarget.position.y -= _kDeathCameraOffset;
    }

    isGameOverNotifier.value = true;
  }

  void respawn() {
    _isGameOver = false;
    score = 0;
    scoreNotifier.value = 0;
    isBoostingNotifier.value = false;

    Vector2 safePos = orbManager.randomPos();
    const int maxAttempts = 20;
    for (var i = 0; i < maxAttempts; i++) {
      final candidate = orbManager.randomPos();
      final allSegs = <Vector2>[
        for (final bot in botManager.bots) ...bot.component.segments,
      ];
      final isSafe = allSegs.every((s) => s.distanceTo(candidate) > 200);
      if (isSafe) {
        safePos = candidate;
        break;
      }
    }

    final angle = _rng.nextDouble() * 2 * pi;
    final initSegs = buildInitialSegments(safePos, angle, 7);

    snakeController = SnakeController(speed: 155, initialAngle: angle);
    snakeController.resetHistory(initSegs);
    snakeComponent.updateSegments(initSegs);
    playerCameraTarget.position.setFrom(safePos);

    isGameOverNotifier.value = false;
  }

  void reset() => _initGame();
  void setAngle(double angle) => snakeController.setTargetAngle(angle);
  void setBoosting(bool value) => snakeController.setBoosting(value);

  List<Vector2> buildInitialSegments(
    Vector2 head,
    double angle,
    int count, {
    double spacing = 14.0,
  }) =>
      List.generate(
        count,
        (i) => Vector2(
          head.x - cos(angle) * i * spacing,
          head.y - sin(angle) * i * spacing,
        ),
      );
}
