import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serpiente_io/src/game/systems/collision_system.dart';

void main() {
  group('CollisionSystem', () {
    test('detects collision with a body line segment even when no body point is close', () {
      final collisionSystem = CollisionSystem(mapSize: 2400);
      final head = Vector2(15, 15);
      final body = <Vector2>[
        Vector2(0, 0),
        Vector2(30, 0),
      ];

      final collided = collisionSystem.collidesWithSnake(
        head,
        body,
        CollisionSystem.playerSegRadius,
        CollisionSystem.botSegRadius,
      );

      expect(collided, isTrue);
    });
  });
}
