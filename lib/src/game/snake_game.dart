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
///
/// ### Cambios clave respecto a la versión anterior:
/// - Al morir, el juego **no se pausa** → los bots siguen moviéndose.
/// - La cámara hace un leve desplazamiento hacia arriba para que el jugador
///   vea la acción mientras el modal de Game Over está visible.
/// - [respawn()] recrea al jugador en posición segura sin reiniciar el mundo.
/// - Las colisiones usan [_kGraceMargin] de 2 px para permitir rozar sin morir.
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

  /// Margen de gracia en píxeles: el jugador puede rozar 2 px sin morir.
  static const double _kGraceMargin = 2.0;

  /// Radio de segmento del jugador (mismo que en SnakeComponent).
  static const double _kPlayerSegRadius = 12.0;

  /// Radio de segmento de un bot.
  static const double _kBotSegRadius = 10.0;

  /// Desplazamiento de cámara al morir (hacia arriba en coords de mundo).
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
    final initSegs = _buildInitialSegments(playerStart, 0, 14);
    snakeComponent = SnakeComponent(
      skin: initialSkin,
      isPlayer: true,
      initialSegments: initSegs,
      segmentRadius: _kPlayerSegRadius,
    );
    // Inicializar el historial del controlador con los segmentos iniciales.
    snakeController.resetHistory(initSegs);
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
    final initSegs = _buildInitialSegments(pos, angle, 8);
    final entry = BotEntry(
      id: id,
      name: name,
      skin: skin,
      initialSegments: initSegs,
    );
    final ctrl = BotController(botName: name, mapSize: _kMapSize, initialAngle: angle);
    // Inicializar historial del bot.
    ctrl.resetHistory(initSegs);
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

  /// Radio del efecto imán de orbes (px). Rango estrecho para garantizar que
  /// los orbes atraídos sean consumidos al 100% y no queden desplazados.
  static const double _kOrbMagnetRadius = 45.0;

  /// Velocidad de atracción magnética (px/s). Alta para que el orbe encaje
  /// instantáneamente en la cabeza antes de que esta se aleje.
  static const double _kOrbMagnetSpeed = 650.0;

  @override
  void update(double dt) {
    super.update(dt);

    // Si el jugador está muerto, el mundo sigue corriendo (bots activos).
    // Solo se salta la lógica DEL JUGADOR.
    if (!_isGameOver) {
      _updatePlayer(dt);
    }

    // Bots siempre activos (juego no se pausa al morir el jugador).
    if (mode == GameMode.offline) _updateBots(dt);

    // Atracción electromagnética (imán) de orbes hacia cabezas cercanas
    _updateOrbMagnet(dt);

    // Mantener densidad mínima de orbes
    if (orbs.length < _kTargetOrbCount ~/ 2) _spawnOrbs(count: 15);
  }

  /// Aplica el efecto imán a orbes dentro del rango estrecho de captura.
  /// La alta velocidad de atracción garantiza que todo orbe atraído sea comido de inmediato.
  void _updateOrbMagnet(double dt) {
    if (orbs.isEmpty) return;

    final activeHeads = <Vector2>[
      if (!_isGameOver && snakeComponent.segments.isNotEmpty)
        snakeComponent.segments.first,
      for (final bot in bots)
        if (bot.component.segments.isNotEmpty) bot.component.segments.first,
    ];

    if (activeHeads.isEmpty) return;

    for (final orb in orbs) {
      Vector2? closestHead;
      double minDist = _kOrbMagnetRadius;

      for (final head in activeHeads) {
        final d = orb.position.distanceTo(head);
        if (d < minDist) {
          minDist = d;
          closestHead = head;
        }
      }

      if (closestHead != null && minDist > 1.0) {
        // Dirección directa hacia la cabeza
        final dir = (closestHead - orb.position)..normalize();
        // Atracción rápida y directa: se mueve a alta velocidad hacia la cabeza
        // garantizando colisión inmediata sin dejar el orbe flotando o desplazado.
        orb.position.addScaled(dir, _kOrbMagnetSpeed * dt);
      }
    }
  }

  void _updatePlayer(double dt) {
    final nextSegs = snakeController.move(snakeComponent.segments, dt);

    if (_isOutOfBoundsPlayer(nextSegs.first) ||
        _collidesWithBotsPlayer(nextSegs.first)) {
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
  }

  void _updateBots(double dt) {
    final orbPositions = orbs.map((o) => o.position).toList();

    // Cabezas de todos los bots (para lógica de intercept entre bots).
    final allBotHeads = bots
        .where((b) => b.component.segments.isNotEmpty)
        .map((b) => b.component.segments.first)
        .toList();

    for (final bot in bots.toList()) {
      final ctrl = bot.controller as BotController;
      final segs = bot.component.segments;
      if (segs.isEmpty) continue;

      // Segmentos rivales: jugador + otros bots.
      final rivals = <Vector2>[
        ...snakeComponent.segments,
        for (final other in bots)
          if (other.id != bot.id) ...other.component.segments,
      ];

      // Cabezas rivales (excluyendo la propia, incluyendo jugador si vivo).
      final rivalHeads = <Vector2>[
        if (!_isGameOver && snakeComponent.segments.isNotEmpty)
          snakeComponent.segments.first,
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

      final nextBotSegs = ctrl.move(segs, dt);

      // Colisión bot con borde o cuerpo del jugador → bot muere.
      if (_isOutOfBoundsBot(nextBotSegs.first) ||
          _collidesWithSnake(
              nextBotSegs.first, snakeComponent.segments, _kBotSegRadius, _kPlayerSegRadius)) {
        _killBot(bot);
        continue;
      }

      // Colisión bot con otros bots → bot muere.
      bool botDied = false;
      for (final other in bots) {
        if (other.id == bot.id) continue;
        if (_collidesWithSnake(
            nextBotSegs.first, other.component.segments, _kBotSegRadius, _kBotSegRadius)) {
          _killBot(bot);
          botDied = true;
          break;
        }
      }
      if (botDied) continue;

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
        .where((s) => !_isOutOfBoundsBot(s))
        .take((bot.component.segments.length * 0.4).round())
        .map((s) => s.clone())
        .toList();
    _spawnOrbsAt(drops);

    // Notificar a los 3 bots más cercanos de los orbes caídos.
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
        (nb.controller as BotController).notifyOrbDrop(drops);
      }
    }

    bots.remove(bot);
    bot.component.removeFromParent();

    Future.delayed(const Duration(seconds: 4), () {
      if (isLoaded) {
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

  // ── Colisiones con margen de gracia ──────────────────────────────────────

  /// Colisión de la CABEZA DEL JUGADOR con los segmentos de un bot.
  /// Usa margen de gracia de [_kGraceMargin] px.
  bool _collidesWithBotsPlayer(Vector2 head) =>
      bots.any((bot) => _collidesWithSnake(
          head, bot.component.segments, _kPlayerSegRadius, _kBotSegRadius,
          graceMargin: _kGraceMargin));

  /// Colisión genérica entre una cabeza y una lista de segmentos.
  /// [headRadius] y [bodyRadius] son los radios de cada serpiente.
  /// [graceMargin] permite rozar sin morir (0 = sin margen).
  bool _collidesWithSnake(
    Vector2 head,
    List<Vector2> segs,
    double headRadius,
    double bodyRadius, {
    double graceMargin = 0,
    int skipFirst = 3,
  }) {
    final threshold = headRadius + bodyRadius - graceMargin;
    for (var i = skipFirst; i < segs.length; i++) {
      if (head.distanceTo(segs[i]) < threshold) return true;
    }
    return false;
  }

  /// Fuera de los límites para el JUGADOR (con margen de gracia de 2 px).
  bool _isOutOfBoundsPlayer(Vector2 pos) {
    const border = 5.0;
    final limit = border - _kGraceMargin; // 3 px — puede rozar el borde
    return pos.x < limit ||
        pos.x > _kMapSize - limit ||
        pos.y < limit ||
        pos.y > _kMapSize - limit;
  }

  /// Fuera de los límites para los BOTS (sin margen de gracia extra).
  bool _isOutOfBoundsBot(Vector2 pos) =>
      pos.x < 5 || pos.x > _kMapSize - 5 ||
      pos.y < 5 || pos.y > _kMapSize - 5;

  // ── Game Over y Respawn ───────────────────────────────────────────────────

  void _handleGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;

    // Ocultar la serpiente del jugador sin eliminarla del mundo.
    snakeComponent.segments.clear();

    // Desplazar cámara hacia arriba suavemente para revelar el mundo activo.
    if (playerCameraTarget.position.y > _kDeathCameraOffset) {
      playerCameraTarget.position.y -= _kDeathCameraOffset;
    }

    // NO llamar pauseEngine() → los bots siguen moviéndose.
    isGameOverNotifier.value = true;
  }

  /// Reaparece al jugador en una posición aleatoria segura.
  /// No reinicia el mundo ni los bots.
  void respawn() {
    _isGameOver = false;
    score = 0;
    scoreNotifier.value = 0;
    isBoostingNotifier.value = false;

    // Buscar posición segura (lejos de todos los segmentos existentes).
    Vector2 safePos = _randomPos();
    const int maxAttempts = 20;
    for (var i = 0; i < maxAttempts; i++) {
      final candidate = _randomPos();
      final allSegs = <Vector2>[
        for (final bot in bots) ...bot.component.segments,
      ];
      final isSafe = allSegs.every((s) => s.distanceTo(candidate) > 200);
      if (isSafe) {
        safePos = candidate;
        break;
      }
    }

    final angle = _rng.nextDouble() * 2 * pi;
    final initSegs = _buildInitialSegments(safePos, angle, 14);

    // Reconstruir el controlador del jugador para resetear historial y boost.
    snakeController = SnakeController(speed: 155, initialAngle: angle);
    snakeController.resetHistory(initSegs);

    snakeComponent.updateSegments(initSegs);

    // Reposicionar cámara en la nueva posición del jugador.
    playerCameraTarget.position.setFrom(safePos);

    isGameOverNotifier.value = false;
  }

  /// Reset completo del juego (usado al volver al menú principal).
  void reset() {
    _initGame();
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
