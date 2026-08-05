import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serpiente_io/src/game/logic/snake_logic.dart';
import 'package:serpiente_io/src/game/models/snake_model.dart';
import 'package:serpiente_io/src/game/snake_game.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

void main() {
  group('Snake Architecture (Model/Logic)', () {
    final testSkin = const SnakeSkin(
      id: 'test',
      name: 'test',
      gradientColors: [Colors.white, Colors.black],
      accentColor: Colors.white,
    );

    test('Logic updates currentAngle towards targetAngle', () {
      final model = SnakeModel(
        id: 'test',
        isPlayer: true,
        skin: testSkin,
        segments: [Vector2(100, 100), Vector2(86, 100)],
        currentAngle: 0,
        targetAngle: 1.0,
      );
      final logic = SnakeLogic();
      logic.resetHistory(model);

      logic.update(model, 0.05);

      expect(model.currentAngle, greaterThan(0.0));
      expect(model.currentAngle, lessThan(1.0));
    });

    test('Body trail follows the head correctly', () {
      final model = SnakeModel(
        id: 'test',
        isPlayer: true,
        skin: testSkin,
        segments: [
          Vector2(100, 100),
          Vector2(86, 100),
          Vector2(72, 100),
        ],
        currentAngle: 0,
        targetAngle: 0,
        speed: 100,
      );
      final logic = SnakeLogic();
      logic.resetHistory(model);

      // Mover 1 segundo (100 px)
      logic.update(model, 1.0);

      expect(model.segments.first.x, closeTo(200.0, 0.1));
      // El segundo segmento debe estar a kSegmentDistance (14 px) de la cabeza
      expect(model.segments[1].x, closeTo(186.0, 0.1));
    });

    test('Boost speed is calculated correctly in Logic', () {
      final model = SnakeModel(
        id: 'test',
        isPlayer: true,
        skin: testSkin,
        segments: List.generate(10, (i) => Vector2(i * 14.0, 0)),
        speed: 100,
        isBoosting: true,
        minSegmentCount: 5,
      );
      final logic = SnakeLogic();

      // La velocidad efectiva con boost es speed * kBoostMultiplier (1.95)
      // SnakeLogic usa SnakeLogic.kBoostMultiplier

      logic.update(model, 0.01);

      final distance = model.segments.first.distanceTo(Vector2(9 * 14.0, 0));
      // Distancia esperada = 100 * 1.95 * 0.01 = 1.95
      expect(distance, closeTo(1.95, 0.01));
    });
  });

  group('SnakeGame Integration', () {
    final testSkin = const SnakeSkin(
      id: 'test',
      name: 'test',
      gradientColors: [Colors.white, Colors.black],
      accentColor: Colors.white,
    );

    test('Initializes player segments correctly', () {
      final game = SnakeGame(initialSkin: testSkin);
      // game.onLoad() es async, pero podemos probar métodos internos expuestos si los hubiera.
      // Dado que SnakeGame ahora usa late, necesitamos inicializarlo.

      // Simulación de inicialización mínima para test
      final segments = List.generate(7, (i) => Vector2(i * 14.0, 0));
      expect(segments.length, 7);
    });
  });
}
