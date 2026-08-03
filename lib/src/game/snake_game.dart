import 'dart:math';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:serpiente_io/src/game/components/bot_snake_component.dart';
import 'package:serpiente_io/src/game/components/orb_component.dart';
import 'package:serpiente_io/src/game/components/snake_component.dart';
import 'package:serpiente_io/src/game/controllers/bot_controller.dart';
import 'package:serpiente_io/src/game/controllers/snake_controller.dart';
import 'package:serpiente_io/src/game/models/game_mode.dart';
import 'package:serpiente_io/src/game/skins/skin_repository.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

/// Componente que dibuja el fondo de la arena con cuadrícula neon
/// y borde rojo de peligro alrededor del mapa.
class ArenaBackgroundComponent extends PositionComponent {
  final double mapSize;

  ArenaBackgroundComponent({required this.mapSize})
      : super(
          position: Vector2.zero(),
          size: Vector2.all(mapSize),
        );

  final Paint _bgPaint = Paint()..color = const Color(0xFF0F1A2E);
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFFF2D55)
    ..strokeWidth = 8
    ..style = PaintingStyle.stroke;
  final Paint _gridPaint = Paint()
    ..color = const Color(0x1822C55E)
    ..strokeWidth = 1.2;

  @override
  void render(Canvas canvas) {
    // Fondo de la arena
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _bgPaint);

    // Cuadrícula (grid lines)
    const step = 60.0;
    for (double x = 0; x <= size.x; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _gridPaint);
    }
    for (double y = 0; y <= size.y; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _gridPaint);
    }

    // Borde rojo exterior de peligro
    canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), _borderPaint);
  }
}

/// Motor de juego principal de serpiente.io.
///
/// Usando el sistema World + CameraComponent de Flame:
/// Todos los elementos del mapa (serpiente, bots, orbes, fondo) se agregan a [world]
/// y la cámara los enfoca dinámicamente en coordenadas de mundo.
class SnakeGame extends FlameGame {
  final SnakeSkin initialSkin;
  final GameMode mode;
  final int botCount;

  late SnakeComponent snakeComponent;
  late SnakeController snakeController;
  late PositionComponent playerCameraTarget;
  final List<OrbComponent> orbs = [];
  final List<BotEntry> bots = [];

  int score = 0;
  bool _isGameOver = false;
  final ValueNotifier<bool> isGameOverNotifier = ValueNotifier(false);
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isBoostingNotifier = ValueNotifier(false);

  final _rng = Random();
  static const double _kMapSize = 2400;
  static const double _kOrbRadius = 7;
  static const int _kTargetOrbCount = 100;

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
    _initGame();
  }

  void _initGame() {
    score = 0;
    _isGameOver = false;
    isGameOverNotifier.value = false;
    scoreNotifier.value = 0;
    isBoostingNotifier.value = false;

    // Limpiar mundo si viene de reset
    world.removeAll(world.children);
    orbs.clear();
    bots.clear();

    // ── 1. Fondo de la arena con cuadrícula neon ──────────────────────────
    world.add(ArenaBackgroundComponent(mapSize: _kMapSize));

    // ── 2. Jugador ─────────────────────────────────────────────────────────
    snakeController = SnakeController(speed: 155, initialAngle: 0);

    final playerStart = _randomPos();
    snakeComponent = SnakeComponent(
      skin: initialSkin,
      isPlayer: true,
      initialSegments: _buildInitialSegments(playerStart, 0, 14),
      segmentRadius: 12,
    );
    world.add(snakeComponent);

    // Tracker de posición para la cámara en el mundo
    playerCameraTarget = PositionComponent(position: playerStart.clone());
    world.add(playerCameraTarget);
    camera.follow(playerCameraTarget);

    // ── 3. Bots (modo offline) ─────────────────────────────────────────────
    if (mode == GameMode.offline) _spawnBots();

    // ── 4. Orbes iniciales ─────────────────────────────────────────────────
    _spawnOrbs(count: _kTargetOrbCount);
  }

  void _spawnBots() {
    final skinRepo = SkinRepository();
    final names = [
      'Víbora', 'Cobra', 'Anaconda', 'Mamba', 'Pitón',
      'Boa', 'Taipán', 'Cascabel', 'Dragón', 'Rex',
    ];
    for (var i = 0; i < botCount; i++) {
      _spawnBot(
        'bot_$i',
        names[i % names.length],
        skinRepo.availableSkins[i % skinRepo.availableSkins.length],
      );
    }
  }

  void _spawnBot(String id, String name, SnakeSkin skin) {
    final angle = _rng.nextDouble() * 2 * pi;
    final pos = _randomPos();
    final entry = BotEntry(
      id: id,
      name: name,
      skin: skin,
      initialSegments: _buildInitialSegments(pos, angle, 8),
    );
    final ctrl = BotController(botName: name, mapSize: _kMapSize, initialAngle: angle);
    entry.controller = ctrl;
    bots.add(entry);
    world.add(entry.component);
  }

  void _spawnOrbs({required int count}) {
    for (var i = 0; i < count; i++) {
      final orb = OrbComponent(position: _randomPos());
      orbs.add(orb);
      world.add(orb);
    }
  }

  void _spawnOrbsAt(List<Vector2> positions) {
    for (final pos in positions) {
      final orb = OrbComponent(position: pos.clone());
      orbs.add(orb);
      world.add(orb);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver) return;

    // ── Jugador ──────────────────────────────────────────────────────────
    final nextSegs = snakeController.move(snakeComponent.segments, dt);

    if (_isOutOfBounds(nextSegs.first) || _collidesWithBots(nextSegs.first)) {
      _handleGameOver();
      return;
    }

    snakeComponent.updateSegments(nextSegs);

    // Actualizar tracker de cámara con la cabeza del jugador
    if (snakeComponent.segments.isNotEmpty) {
      playerCameraTarget.position.setFrom(snakeComponent.segments.first);
    }

    // Masa perdida en boost → orbes en la cola
    final massDrop = snakeController.consumePendingMassDrop();
    if (massDrop > 0 && snakeComponent.segments.isNotEmpty) {
      final tail = snakeComponent.segments.last;
      _spawnOrbsAt(List.generate(
        massDrop,
        (_) => Vector2(
          tail.x + (_rng.nextDouble() - 0.5) * 22,
          tail.y + (_rng.nextDouble() - 0.5) * 22,
        ),
      ));
    }

    _checkPlayerOrbCollision();
    isBoostingNotifier.value = snakeController.isBoosting;

    // ── Bots ─────────────────────────────────────────────────────────────
    if (mode == GameMode.offline) _updateBots(dt);

    // Mantener densidad mínima de orbes
    if (orbs.length < _kTargetOrbCount ~/ 2) _spawnOrbs(count: 15);
  }

  void _updateBots(double dt) {
    final orbPositions = orbs.map((o) => o.position).toList();

    for (final bot in bots.toList()) {
      final ctrl = bot.controller as BotController;
      final segs = bot.component.segments;
      if (segs.isEmpty) continue;

      final rivals = <Vector2>[
        ...snakeComponent.segments,
        for (final other in bots)
          if (other.id != bot.id) ...other.component.segments,
      ];

      ctrl.think(
        headPos: segs.first,
        orbPositions: orbPositions,
        rivalSegments: rivals,
        dt: dt,
      );

      final nextBotSegs = ctrl.move(segs, dt);

      if (_isOutOfBounds(nextBotSegs.first) ||
          _collidesWithSnake(nextBotSegs.first, snakeComponent.segments)) {
        _killBot(bot);
        continue;
      }

      bot.component.updateSegments(nextBotSegs);
      _checkBotOrbCollision(bot);

      final botDrop = ctrl.consumePendingMassDrop();
      if (botDrop > 0 && bot.component.segments.isNotEmpty) {
        final tail = bot.component.segments.last;
        _spawnOrbsAt(List.generate(
          botDrop,
          (_) => Vector2(
            tail.x + (_rng.nextDouble() - 0.5) * 20,
            tail.y + (_rng.nextDouble() - 0.5) * 20,
          ),
        ));
      }
    }
  }

  void _killBot(BotEntry bot) {
    final drops = bot.component.segments
        .where((s) => !_isOutOfBounds(s))
        .take((bot.component.segments.length * 0.4).round())
        .map((s) => s.clone())
        .toList();
    _spawnOrbsAt(drops);

    bots.remove(bot);
    bot.component.removeFromParent();

    Future.delayed(const Duration(seconds: 4), () {
      if (!_isGameOver && isLoaded) {
        final skinRepo = SkinRepository();
        final idx = _rng.nextInt(skinRepo.availableSkins.length);
        _spawnBot(bot.id, 'Bot_${_rng.nextInt(99)}', skinRepo.availableSkins[idx]);
      }
    });
  }

  void _checkPlayerOrbCollision() {
    if (snakeComponent.segments.isEmpty) return;
    final head = snakeComponent.segments.first;
    final hitR = snakeComponent.segmentRadius + _kOrbRadius;

    final hit = orbs.where((o) => o.position.distanceTo(head) < hitR).toList();
    for (final orb in hit) {
      orbs.remove(orb);
      orb.removeFromParent();
      if (snakeComponent.segments.isNotEmpty) {
        snakeComponent.segments.add(snakeComponent.segments.last.clone());
      }
      score += 10;
      scoreNotifier.value = score;
    }
  }

  void _checkBotOrbCollision(BotEntry bot) {
    if (bot.component.segments.isEmpty) return;
    final head = bot.component.segments.first;
    final hitR = bot.component.segmentRadius + _kOrbRadius;

    final hit = orbs.where((o) => o.position.distanceTo(head) < hitR).toList();
    for (final orb in hit) {
      orbs.remove(orb);
      orb.removeFromParent();
      bot.component.segments.add(bot.component.segments.last.clone());
    }
  }

  bool _collidesWithBots(Vector2 head) =>
      bots.any((bot) => _collidesWithSnake(head, bot.component.segments));

  bool _collidesWithSnake(Vector2 head, List<Vector2> segs) {
    for (var i = 3; i < segs.length; i++) {
      if (head.distanceTo(segs[i]) < 11) return true;
    }
    return false;
  }

  bool _isOutOfBounds(Vector2 pos) =>
      pos.x < 5 || pos.x > _kMapSize - 5 ||
      pos.y < 5 || pos.y > _kMapSize - 5;

  void _handleGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    isGameOverNotifier.value = true;
    pauseEngine();
  }

  void reset() {
    _initGame();
    if (paused) resumeEngine();
  }

  void setAngle(double angle) => snakeController.setTargetAngle(angle);
  void setBoosting(bool value) => snakeController.setBoosting(value);

  Vector2 _randomPos() {
    const m = 150.0;
    return Vector2(
      m + _rng.nextDouble() * (_kMapSize - m * 2),
      m + _rng.nextDouble() * (_kMapSize - m * 2),
    );
  }

  List<Vector2> _buildInitialSegments(Vector2 head, double angle, int count) =>
      List.generate(
        count,
        (i) => Vector2(
          head.x - cos(angle) * i * 14.0,
          head.y - sin(angle) * i * 14.0,
        ),
      );
}
