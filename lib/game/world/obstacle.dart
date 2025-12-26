import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

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

    // Debug visualization (only visible when debug panel is open)
    add(DebugRectangleComponent(
      size: size,
      color: Colors.red,
      filled: true,
    ));
    add(DebugRectangleComponent(
      size: size,
      color: Colors.red,
      filled: false,
      strokeWidth: 2,
    ));
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

    // Debug visualization (only visible when debug panel is open)
    add(DebugPolygonComponent(
      vertices: vertices,
      color: Colors.orange,
    ));
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

/// A rectangle component that only renders when debug panel is open
class DebugRectangleComponent extends PositionComponent {
  final Color color;
  final bool filled;
  final double strokeWidth;

  DebugRectangleComponent({
    required Vector2 size,
    this.color = Colors.red,
    this.filled = true,
    this.strokeWidth = 2.0,
  }) : super(size: size);

  @override
  void render(Canvas canvas) {
    // Only render when debug panel is open
    if (!MemoryLaneGame.showDebugPanel) return;

    final paint = Paint()
      ..color = color.withValues(alpha: filled ? 0.3 : 1.0)
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );
  }
}

/// A polygon component that only renders when debug panel is open
class DebugPolygonComponent extends PositionComponent {
  final List<Vector2> vertices;
  final Color color;

  DebugPolygonComponent({
    required this.vertices,
    this.color = Colors.orange,
  });

  @override
  void render(Canvas canvas) {
    // Only render when debug panel is open
    if (!MemoryLaneGame.showDebugPanel) return;
    if (vertices.length < 3) return;

    final path = Path();
    path.moveTo(vertices[0].x, vertices[0].y);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].x, vertices[i].y);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill,
    );
  }
}
