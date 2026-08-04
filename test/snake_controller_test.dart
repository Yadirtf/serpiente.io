import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serpiente_io/src/game/controllers/snake_controller.dart';
import 'package:serpiente_io/src/game/snake_game.dart';
import 'package:serpiente_io/src/game/skins/snake_skin.dart';

void main() {
  group('SnakeController', () {
    test('uses a more responsive default turn speed for smoother movement', () {
      final controller = SnakeController();
      controller.setTargetAngle(1.0);

      final initialSegments = <Vector2>[
        Vector2(100, 100),
        Vector2(86, 100),
        Vector2(72, 100),
      ];

      final nextSegments = controller.move(initialSegments, 0.05);

      expect(controller.currentAngle, greaterThan(0.24));
      expect(nextSegments.first.x, greaterThan(initialSegments.first.x));
    });

    test('keeps the body trail aligned with the head after moving', () {
      final controller = SnakeController(speed: 120, segmentDistance: 14);
      controller.setTargetAngle(0.0);

      final initialSegments = <Vector2>[
        Vector2(100, 100),
        Vector2(86, 100),
        Vector2(72, 100),
        Vector2(58, 100),
      ];

      controller.resetHistory(initialSegments);
      final nextSegments = controller.move(initialSegments, 0.2);

      expect(nextSegments.length, equals(initialSegments.length));
      expect(nextSegments.first.x, greaterThan(initialSegments.first.x));
      expect(nextSegments[1].x, greaterThanOrEqualTo(initialSegments[1].x));
    });

    test('keeps a stable travel distance when turning', () {
      final straightController = SnakeController(speed: 100, maxTurnSpeed: 10);
      straightController.setTargetAngle(0.0);
      final straightInitial = <Vector2>[Vector2(100, 100), Vector2(86, 100)];

      final turningController = SnakeController(speed: 100, maxTurnSpeed: 10);
      turningController.setTargetAngle(1.2);
      final turningInitial = <Vector2>[Vector2(100, 100), Vector2(86, 100)];

      final straightNext = straightController.move(straightInitial, 0.1);
      final turningNext = turningController.move(turningInitial, 0.1);

      final straightDistance = straightNext.first.distanceTo(straightInitial.first);
      final turningDistance = turningNext.first.distanceTo(turningInitial.first);

      expect(straightDistance, closeTo(10.0, 0.01));
      expect(turningDistance, closeTo(10.0, 0.01));
    });

    test('scores normal orbs by their value and dead snake orbs by 3', () {
      final game = SnakeGame(
        initialSkin: const SnakeSkin(
          id: 'test',
          name: 'test',
          gradientColors: [Colors.white],
          accentColor: Colors.white,
        ),
      );
      game.score = 0;

      game.applyOrbScore(1);
      expect(game.score, 1);

      game.applyOrbScore(3);
      expect(game.score, 4);
    });

    test('builds a smaller initial snake body for the player', () {
      final game = SnakeGame(
        initialSkin: const SnakeSkin(
          id: 'test',
          name: 'test',
          gradientColors: [Colors.white],
          accentColor: Colors.white,
        ),
      );

      final segments = game.buildInitialSegments(Vector2(100, 100), 0, 7);

      expect(segments.length, 7);
      expect(segments.last.distanceTo(segments.first), closeTo(84.0, 0.001));
    });

    test('reduces boost speed by 3 units per pending dropped orb', () {
      final controller = SnakeController(speed: 100);
      controller.setBoosting(true);
      controller.applyMassDrop(1);
      expect(controller.currentSpeed, closeTo(192.0, 0.001));
    });
  });
}
