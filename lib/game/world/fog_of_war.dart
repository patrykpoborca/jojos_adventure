import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';
import 'christmas_lights.dart';

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

    // Use a layer to combine multiple light sources
    canvas.saveLayer(fogRect, Paint());

    // Draw base fog
    canvas.drawRect(
      fogRect,
      Paint()..color = Colors.black.withValues(alpha: fogOpacity),
    );

    // Punch hole for player visibility
    final visRadius = _calculateVisibilityRadius(playerPos);
    _drawLightHole(canvas, playerPos, visRadius, fadeRadius);

    // Punch holes for Christmas lights
    _drawChristmasLightHoles(canvas);

    canvas.restore();
  }

  /// Draw a visibility hole at a position
  void _drawLightHole(Canvas canvas, Vector2 pos, double innerRadius, double fadeRadius) {
    final totalRadius = innerRadius + fadeRadius;
    final gradient = ui.Gradient.radial(
      Offset(pos.x, pos.y),
      totalRadius,
      [
        Colors.black, // Will be used to "erase" the fog
        Colors.black,
        Colors.transparent,
      ],
      [
        0.0,
        innerRadius / totalRadius,
        1.0,
      ],
    );

    canvas.drawCircle(
      Offset(pos.x, pos.y),
      totalRadius,
      Paint()
        ..shader = gradient
        ..blendMode = BlendMode.dstOut, // Erase the fog
    );
  }

  /// Draw light holes for all Christmas lights in the current map
  void _drawChristmasLightHoles(Canvas canvas) {
    final lights = game.currentMap?.children.whereType<ChristmasLights>();
    if (lights == null) return;

    for (final light in lights) {
      // Use the triangle's center for fog piercing
      _drawLightHole(
        canvas,
        light.triangleCenter,
        light.fogPierceRadius * 0.5, // Inner bright area
        light.fogPierceRadius * 0.5, // Fade area
      );
    }
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
