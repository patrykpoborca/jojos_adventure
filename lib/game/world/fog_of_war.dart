import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// Fog of war component that obscures areas far from the player
class FogOfWar extends PositionComponent with HasGameReference<MemoryLaneGame> {
  /// Base visibility radius around the player
  static const double baseVisibilityRadius = 300.0;

  /// Extended radius for the gradient fade
  static const double fadeRadius = 150.0;

  /// Fog darkness (0.0 = transparent, 1.0 = fully opaque)
  static const double fogOpacity = 0.85;

  /// How much nearby obstacles reduce visibility (0-1)
  static const double obstacleInfluence = 0.3;

  /// Distance at which obstacles start affecting visibility
  static const double obstacleInfluenceDistance = 200.0;

  @override
  int get priority => 1000; // Render on top of everything

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final playerPos = game.player.position;
    final cameraPos = game.camera.viewfinder.position;
    final zoom = game.camera.viewfinder.zoom;

    // Calculate the visible area in world coordinates
    final screenSize = game.size;
    final worldWidth = screenSize.x / zoom;
    final worldHeight = screenSize.y / zoom;

    // Calculate fog rect in world space (larger than screen for safety)
    final fogRect = Rect.fromCenter(
      center: Offset(cameraPos.x, cameraPos.y),
      width: worldWidth * 1.5,
      height: worldHeight * 1.5,
    );

    // Calculate visibility radius with obstacle influence
    final visRadius = _calculateVisibilityRadius(playerPos);
    final totalRadius = visRadius + fadeRadius;

    // Create radial gradient for the visibility hole
    final gradient = ui.Gradient.radial(
      Offset(playerPos.x, playerPos.y),
      totalRadius,
      [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: fogOpacity),
      ],
      [
        0.0,
        visRadius / totalRadius, // Start fade at visibility edge
        1.0, // Full fog at outer edge
      ],
    );

    // Draw the fog with a hole around the player
    final paint = Paint()..shader = gradient;
    canvas.drawRect(fogRect, paint);
  }

  /// Calculate visibility radius based on nearby obstacles
  double _calculateVisibilityRadius(Vector2 playerPos) {
    double radius = baseVisibilityRadius;

    // Check for nearby obstacles that might reduce visibility
    final obstacles = game.currentMap?.children.whereType<PositionComponent>();
    if (obstacles == null) return radius;

    double totalInfluence = 0.0;
    int influencingObstacles = 0;

    for (final obstacle in obstacles) {
      // Skip non-obstacle components (check by type or tag if available)
      if (!_isObstacle(obstacle)) continue;

      final distance = playerPos.distanceTo(obstacle.position + obstacle.size / 2);
      if (distance < obstacleInfluenceDistance) {
        // Closer obstacles have more influence
        final influence = 1.0 - (distance / obstacleInfluenceDistance);
        totalInfluence += influence;
        influencingObstacles++;
      }
    }

    // Reduce radius based on average obstacle influence
    if (influencingObstacles > 0) {
      final avgInfluence = totalInfluence / influencingObstacles;
      radius *= (1.0 - avgInfluence * obstacleInfluence);
    }

    return radius.clamp(baseVisibilityRadius * 0.5, baseVisibilityRadius);
  }

  /// Check if a component is an obstacle (by class name for now)
  bool _isObstacle(PositionComponent component) {
    return component.runtimeType.toString() == 'Obstacle';
  }
}
