import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// An invisible obstacle that blocks player movement
class Obstacle extends PositionComponent with CollisionCallbacks {
  /// Whether to show debug visualization
  final bool showDebug;

  /// Optional label for debugging
  final String? label;

  Obstacle({
    required Vector2 position,
    required Vector2 size,
    this.showDebug = false,
    this.label,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add rectangle hitbox matching the obstacle size
    add(RectangleHitbox(
      size: size,
      position: Vector2.zero(),
      collisionType: CollisionType.passive,
    ));

    // Add debug visualization if enabled
    if (showDebug) {
      add(RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.red.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      ));
      add(RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ));
    }
  }
}

/// A polygon-shaped obstacle for irregular shapes
class PolygonObstacle extends PositionComponent with CollisionCallbacks {
  final List<Vector2> vertices;
  final bool showDebug;
  final String? label;

  PolygonObstacle({
    required this.vertices,
    required Vector2 position,
    this.showDebug = false,
    this.label,
  }) : super(
          position: position,
          anchor: Anchor.topLeft,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(PolygonHitbox(
      vertices,
      collisionType: CollisionType.passive,
    ));

    if (showDebug) {
      add(PolygonComponent(
        vertices,
        paint: Paint()
          ..color = Colors.orange.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      ));
    }
  }
}

/// Helper class to define obstacle data
class ObstacleData {
  final double x;
  final double y;
  final double width;
  final double height;
  final String? label;

  const ObstacleData({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.label,
  });

  Obstacle toObstacle({bool showDebug = false}) {
    return Obstacle(
      position: Vector2(x, y),
      size: Vector2(width, height),
      showDebug: showDebug,
      label: label,
    );
  }
}
