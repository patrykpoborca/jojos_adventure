import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';
import 'christmas_lights.dart';
import 'obstacle.dart';

/// Fog of war component that obscures areas far from the player
/// Features organic edges that interact with obstacles
class FogOfWar extends PositionComponent with HasGameReference<MemoryLaneGame> {
  /// Base visibility radius around the player (main floor)
  static const double _baseVisibilityRadius = 300.0;

  /// Extended radius for the gradient fade (main floor)
  static const double _baseFadeRadius = 150.0;

  /// Upstairs scale multiplier (matches player scale difference)
  static const double upstairsMultiplier = 2.0;

  /// Get current visibility radius based on level
  double get baseVisibilityRadius {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseVisibilityRadius * upstairsMultiplier;
    }
    return _baseVisibilityRadius;
  }

  /// Get current fade radius based on level
  double get fadeRadius {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseFadeRadius * upstairsMultiplier;
    }
    return _baseFadeRadius;
  }

  /// Fog darkness (0.0 = transparent, 1.0 = fully opaque)
  static const double fogOpacity = 0.85;

  /// Number of rays to cast for organic edge
  static const int rayCount = 64;

  /// How much the edge wobbles (0-1)
  static const double edgeWobble = 0.12;

  /// Number of smoothing passes for the edge
  static const int smoothingPasses = 3;

  /// How much obstacles block light (0-1)
  static const double obstacleShadowStrength = 0.6;

  /// Animation time for subtle edge movement
  double _time = 0;

  @override
  int get priority => 1000; // Render on top of everything

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt * 0.5; // Slow animation
  }

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

    // Draw organic player visibility with obstacle interaction
    _drawOrganicLightHole(canvas, playerPos, baseVisibilityRadius, fadeRadius);

    // Punch holes for Christmas lights (simpler, just circular)
    _drawChristmasLightHoles(canvas);

    canvas.restore();
  }

  /// Draw an organic visibility hole with wobbly edges and obstacle shadows
  void _drawOrganicLightHole(
    Canvas canvas,
    Vector2 center,
    double innerRadius,
    double outerFade,
  ) {
    final obstacles = _getNearbyObstacles(center, innerRadius + outerFade + 100);

    // First pass: calculate all ray radii
    final rayRadii = List<double>.filled(rayCount, 0);

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi;

      // Calculate wobble using multiple sine waves for organic feel
      final wobble1 = math.sin(angle * 3 + _time) * edgeWobble * 0.5;
      final wobble2 = math.sin(angle * 7 - _time * 1.3) * edgeWobble * 0.3;
      final wobble3 = math.sin(angle * 11 + _time * 0.7) * edgeWobble * 0.2;
      final totalWobble = 1.0 + wobble1 + wobble2 + wobble3;

      // Check for obstacle blocking this ray
      final rayEnd = Vector2(
        center.x + math.cos(angle) * (innerRadius + outerFade) * 1.2,
        center.y + math.sin(angle) * (innerRadius + outerFade) * 1.2,
      );
      final shadowFactor = _calculateShadowFactor(center, rayEnd, obstacles);

      // Calculate effective outer radius for this ray
      rayRadii[i] = (innerRadius + outerFade) * totalWobble * shadowFactor;
    }

    // Apply smoothing passes to reduce sharp peaks
    for (var pass = 0; pass < smoothingPasses; pass++) {
      final smoothed = List<double>.filled(rayCount, 0);
      for (var i = 0; i < rayCount; i++) {
        // Average with neighbors (wrapping around)
        final prev = rayRadii[(i - 1 + rayCount) % rayCount];
        final curr = rayRadii[i];
        final next = rayRadii[(i + 1) % rayCount];
        // Weighted average: 25% prev, 50% current, 25% next
        smoothed[i] = prev * 0.25 + curr * 0.5 + next * 0.25;
      }
      // Copy smoothed values back
      for (var i = 0; i < rayCount; i++) {
        rayRadii[i] = smoothed[i];
      }
    }

    // Find max radius for gradient sizing
    double maxOuterRadius = 0;
    for (final r in rayRadii) {
      maxOuterRadius = math.max(maxOuterRadius, r);
    }

    // Build the outer boundary path using smoothed radii
    final outerPath = Path();

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * math.pi;
      final effectiveRadius = rayRadii[i];

      final x = center.x + math.cos(angle) * effectiveRadius;
      final y = center.y + math.sin(angle) * effectiveRadius;

      if (i == 0) {
        outerPath.moveTo(x, y);
      } else {
        // Use curves for smoother edges - control point uses average of current and previous radius
        final prevAngle = ((i - 0.5) / rayCount) * 2 * math.pi;
        final prevRadius = rayRadii[(i - 1 + rayCount) % rayCount];
        final ctrlRadius = (effectiveRadius + prevRadius) / 2;

        final ctrlX = center.x + math.cos(prevAngle) * ctrlRadius;
        final ctrlY = center.y + math.sin(prevAngle) * ctrlRadius;

        outerPath.quadraticBezierTo(ctrlX, ctrlY, x, y);
      }
    }
    outerPath.close();

    // Create a radial gradient that fades from transparent (center) to opaque (edge)
    // The gradient covers the full area but the path clips it to our organic shape
    final gradient = ui.Gradient.radial(
      Offset(center.x, center.y),
      maxOuterRadius,
      [
        Colors.black, // Full erase at center
        Colors.black, // Stay solid through inner zone
        Colors.black.withValues(alpha: 0.5), // Start fading
        Colors.transparent, // Fully transparent at edge (no erase = fog remains)
      ],
      [
        0.0,
        0.35, // Inner clear zone (35% of radius)
        0.7,  // Mid transition
        1.0,  // Outer edge
      ],
    );

    // Draw the organic shape with gradient - this erases fog
    canvas.drawPath(
      outerPath,
      Paint()
        ..shader = gradient
        ..blendMode = BlendMode.dstOut,
    );
  }

  /// Get obstacles near a position
  List<Obstacle> _getNearbyObstacles(Vector2 pos, double radius) {
    final obstacles = game.currentMap?.children.whereType<Obstacle>().toList() ?? [];
    return obstacles.where((o) {
      final obstacleCenter = o.position + o.size / 2;
      return pos.distanceTo(obstacleCenter) < radius + o.size.length / 2;
    }).toList();
  }

  /// Calculate how much an obstacle shadows a ray (1.0 = no shadow, 0.4 = full shadow)
  double _calculateShadowFactor(Vector2 from, Vector2 to, List<Obstacle> obstacles) {
    double shadowFactor = 1.0;

    for (final obstacle in obstacles) {
      // Simple ray-box intersection check
      final obstacleRect = Rect.fromLTWH(
        obstacle.position.x,
        obstacle.position.y,
        obstacle.size.x,
        obstacle.size.y,
      );

      if (_rayIntersectsRect(from, to, obstacleRect)) {
        // Calculate how close the intersection is
        final obstacleCenter = obstacle.position + obstacle.size / 2;
        final distToObstacle = from.distanceTo(obstacleCenter);
        final maxDist = baseVisibilityRadius + fadeRadius;

        // Closer obstacles cast stronger shadows
        final closeness = 1.0 - (distToObstacle / maxDist).clamp(0.0, 1.0);
        final thisShadow = 1.0 - (obstacleShadowStrength * closeness);

        shadowFactor = math.min(shadowFactor, thisShadow);
      }
    }

    return shadowFactor.clamp(0.4, 1.0);
  }

  /// Check if a ray intersects a rectangle
  bool _rayIntersectsRect(Vector2 from, Vector2 to, Rect rect) {
    // Expand rect slightly for better shadow catching
    final expandedRect = rect.inflate(10);

    final dx = to.x - from.x;
    final dy = to.y - from.y;

    double tMin = 0.0;
    double tMax = 1.0;

    // Check X slab
    if (dx.abs() < 0.0001) {
      if (from.x < expandedRect.left || from.x > expandedRect.right) return false;
    } else {
      final t1 = (expandedRect.left - from.x) / dx;
      final t2 = (expandedRect.right - from.x) / dx;
      tMin = math.max(tMin, math.min(t1, t2));
      tMax = math.min(tMax, math.max(t1, t2));
    }

    // Check Y slab
    if (dy.abs() < 0.0001) {
      if (from.y < expandedRect.top || from.y > expandedRect.bottom) return false;
    } else {
      final t1 = (expandedRect.top - from.y) / dy;
      final t2 = (expandedRect.bottom - from.y) / dy;
      tMin = math.max(tMin, math.min(t1, t2));
      tMax = math.min(tMax, math.max(t1, t2));
    }

    return tMin <= tMax && tMax > 0;
  }

  /// Draw light holes for all Christmas lights in the current map
  void _drawChristmasLightHoles(Canvas canvas) {
    final lights = game.currentMap?.children.whereType<ChristmasLights>();
    if (lights == null) return;

    for (final light in lights) {
      // Simpler circular hole for lights (no obstacle interaction)
      _drawSimpleLightHole(
        canvas,
        light.triangleCenter,
        light.fogPierceRadius * 0.5,
        light.fogPierceRadius * 0.5,
      );
    }
  }

  /// Draw a simple circular light hole (for Christmas lights)
  void _drawSimpleLightHole(
    Canvas canvas,
    Vector2 pos,
    double innerRadius,
    double fadeRadius,
  ) {
    final totalRadius = innerRadius + fadeRadius;
    final gradient = ui.Gradient.radial(
      Offset(pos.x, pos.y),
      totalRadius,
      [
        Colors.black,
        Colors.black,
        Colors.transparent,
      ],
      [0.0, innerRadius / totalRadius, 1.0],
    );

    canvas.drawCircle(
      Offset(pos.x, pos.y),
      totalRadius,
      Paint()
        ..shader = gradient
        ..blendMode = BlendMode.dstOut,
    );
  }
}
