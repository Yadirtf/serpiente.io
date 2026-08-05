import 'dart:math';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:serpiente_io/src/core/events/event_bus.dart';
import 'package:serpiente_io/src/core/events/game_events.dart';
import 'package:serpiente_io/src/game/components/arena_background_component.dart';
import 'package:serpiente_io/src/game/components/snake_component.dart';
import 'package:serpiente_io/src/game/input/human_input.dart';
import 'package:serpiente_io/src/game/logic/snake_logic.dart';
import 'package:serpiente_io/src/game/models/game_mode.dart';
import 'package:serpiente_io/src/game/models/snake_model.dart';
import 'package:serpiente_io/src/game/renderers/snake_renderer.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';
import 'package:serpiente_io/src/game/systems/bot_manager.dart';
import 'package:serpiente_io/src/game/systems/collision_system.dart';
import 'package:serpiente_io/src/game/systems/orb_manager.dart';

class SnakeGame extends FlameGame {
  final SnakeSkin initialSkin;
  final GameMode mode;
  final int botCount;

  late SnakeComponent playerSnake;
  late HumanInput humanInput;
  late SnakeLogic playerLogic;
  late SnakeModel playerModel;

  late PositionComponent playerCameraTarget;
  late CollisionSystem collisionSystem;
  late OrbManager orbManager;
  late BotManager botManager;

  int score = 0;
  bool _isGameOver = false;
  final ValueNotifier<bool> isGameOverNotifier = ValueNotifier(false);
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isBoostingNotifier = ValueNotifier(false);
  final ValueNotifier<int> segmentCountNotifier = ValueNotifier(0);

  final _rng = Random();
  static const double _kMapSize = 2400;

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

    // Escuchar eventos
    EventBus().on<OrbCollectedEvent>().listen((event) {
      if (event.isPlayer) {
        _applyOrbScore(event.value);
      }
    });

    _initGame();
  }

  void _initGame() {
    score = 0;
    _isGameOver = false;
    isGameOverNotifier.value = false;
    scoreNotifier.value = 0;
    isBoostingNotifier.value = false;
    segmentCountNotifier.value = 0;

    world.removeAll(world.children);
    orbManager.clear();
    botManager.clear();

    world.add(ArenaBackgroundComponent(mapSize: _kMapSize));

    // Jugador
    final playerStart = orbManager.randomPos();
    final initSegs = _buildInitialSegments(playerStart, 0, 7);

    playerModel = SnakeModel(
      id: 'player',
      isPlayer: true,
      skin: initialSkin,
      segments: initSegs,
      segmentRadius: CollisionSystem.playerSegRadius,
    );

    playerLogic = SnakeLogic();
    playerLogic.resetHistory(playerModel);

    humanInput = HumanInput();
    final renderer = SnakeRenderer(playerModel);

    playerSnake = SnakeComponent(
      model: playerModel,
      logic: playerLogic,
      renderer: renderer,
      input: humanInput,
    );

    world.add(playerSnake);
    segmentCountNotifier.value = initSegs.length;

    playerCameraTarget = PositionComponent(position: playerStart.clone());
    world.add(playerCameraTarget);
    camera.follow(playerCameraTarget);

    if (mode == GameMode.offline) {
      botManager.spawnBots(botCount);
    }

    orbManager.spawnOrbs(count: OrbManager.targetOrbCount);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_isGameOver) {
      _checkPlayerCollisions();
      _checkPlayerOrbs();
      _updateCamera();
      _handlePlayerMassDrop();

      isBoostingNotifier.value = playerModel.isBoosting && playerModel.segments.length > playerModel.minSegmentCount;
      segmentCountNotifier.value = playerModel.segments.length;
    }

    if (mode == GameMode.offline) {
      botManager.updateBots(
        dt: dt,
        playerSegments: playerModel.segments,
        isGameOver: _isGameOver,
      );
    }

    final activeHeads = <Vector2>[
      if (!_isGameOver && playerModel.segments.isNotEmpty) playerModel.segments.first,
      for (final bot in botManager.bots) if (bot.model.segments.isNotEmpty) bot.model.segments.first,
    ];
    orbManager.updateMagnet(activeHeads, dt);
    orbManager.maintainDensity();
  }

  void _checkPlayerCollisions() {
    if (playerModel.segments.isEmpty) return;
    final head = playerModel.segments.first;

    if (collisionSystem.isOutOfBoundsPlayer(head) ||
        collisionSystem.collidesWithBotsPlayer(head, botManager.bots, previousHead: null)) {
      _handleGameOver();
    }
  }

  void _checkPlayerOrbs() {
    if (playerModel.segments.isEmpty) return;
    final orbValues = orbManager.checkHeadCollisions(playerModel.segments.first, playerModel.segmentRadius);
    for (final val in orbValues) {
      playerModel.segments.add(playerModel.segments.last.clone());
      EventBus().fire(OrbCollectedEvent(collectorId: 'player', isPlayer: true, value: val));
    }
  }

  void _updateCamera() {
    if (playerModel.segments.isNotEmpty) {
      playerCameraTarget.position.setFrom(playerModel.segments.first);
    }
  }

  void _handlePlayerMassDrop() {
    if (playerModel.pendingMassDrop > 0) {
      final tail = playerModel.segments.last;
      final droppedOrbs = List.generate(
        playerModel.pendingMassDrop,
        (_) => Vector2(tail.x + (_rng.nextDouble() - 0.5) * 22, tail.y + (_rng.nextDouble() - 0.5) * 22),
      );
      orbManager.spawnOrbsAt(droppedOrbs, value: 1);

      // Lógica de puntuación por consumo de masa
      final massDrop = playerModel.pendingMassDrop;
      final currentSegs = playerModel.segments.length;
      final minSegs = playerModel.minSegmentCount;
      final extraSegs = currentSegs + massDrop - minSegs;

      if (extraSegs > 0) {
        final pointsToRemove = (score * (massDrop / extraSegs)).ceil();
        _applyOrbScore(-max(massDrop, pointsToRemove));
      } else {
        _applyOrbScore(-score);
      }

      playerModel.pendingMassDrop = 0;
    }
  }

  void _applyOrbScore(int points) {
    score = max(0, score + points);
    scoreNotifier.value = score;
    EventBus().fire(ScoreChangedEvent(newScore: score, delta: points));
  }

  void _handleGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    isGameOverNotifier.value = true;

    EventBus().fire(SnakeDeadEvent(
      snakeId: 'player',
      isPlayer: true,
      deathPosition: playerModel.segments.first.clone(),
    ));

    playerModel.segments.clear();
    segmentCountNotifier.value = 0;
  }

  void respawn() {
    _initGame();
  }

  void reset() => _initGame();
  void setAngle(double angle) => humanInput.updateAngle(angle);
  void setBoosting(bool value) => humanInput.updateBoosting(value);

  List<Vector2> _buildInitialSegments(Vector2 head, double angle, int count) =>
      List.generate(count, (i) => Vector2(head.x - cos(angle) * i * 14.0, head.y - sin(angle) * i * 14.0));
}
