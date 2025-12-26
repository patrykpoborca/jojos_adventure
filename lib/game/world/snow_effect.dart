import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// A pooled snowflake particle
class _Snowflake {
  double x;
  double y;
  double size;
  double speed;
  double drift; // Horizontal drift amplitude
  double phase; // Phase offset for sine wave drift
  double opacity;

  _Snowflake()
      : x = 0,
        y = 0,
        size = 3,
        speed = 50,
        drift = 15,
        phase = 0,
        opacity = 0.7;

  /// Reinitialize this snowflake with new random properties
  void reset(Random random, Rect spawnArea, {bool randomY = false}) {
    x = spawnArea.left + random.nextDouble() * spawnArea.width;
    y = randomY
        ? spawnArea.top + random.nextDouble() * spawnArea.height
        : spawnArea.top - random.nextDouble() * 50;
    size = 2 + random.nextDouble() * 3; // 2-5 pixel radius
    speed = 25 + random.nextDouble() * 40; // 25-65 pixels per second
    drift = 8 + random.nextDouble() * 15; // Horizontal drift amount
    phase = random.nextDouble() * 2 * pi;
    opacity = 0.5 + random.nextDouble() * 0.5; // 0.5-1.0 opacity
  }
}

/// Optimized snow effect with viewport culling and object pooling
class SnowEffect extends PositionComponent with HasGameReference<MemoryLaneGame> {
  /// Number of snowflakes in the pool
  final int flakeCount;

  /// Area where snow can spawn (world coordinates)
  final Rect spawnArea;

  /// Areas to exclude from snow rendering (level bounds)
  final List<Rect> excludeAreas;

  /// Areas to INCLUDE snow rendering (overrides exclude, e.g., outdoor zones)
  final List<Rect> includeZones;

  /// Animation time accumulator
  double _time = 0;

  /// Random generator
  final Random _random = Random();

  /// Pooled list of snowflakes
  late final List<_Snowflake> _flakes;

  /// Cached paint objects for different opacity levels (avoid allocations)
  late final List<Paint> _paintCache;

  /// Number of opacity levels to cache
  static const int _opacityLevels = 10;

  SnowEffect({
    this.flakeCount = 500,
    required this.spawnArea,
    this.excludeAreas = const [],
    this.includeZones = const [],
  }) : super(priority: 50); // Render above background, below fog

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializePaintCache();
    _initializeFlakes();
  }

  /// Pre-create paint objects to avoid per-frame allocations
  void _initializePaintCache() {
    _paintCache = List.generate(_opacityLevels, (i) {
      final opacity = (i + 1) / _opacityLevels;
      return Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
    });
  }

  /// Get cached paint for an opacity value
  Paint _getPaintForOpacity(double opacity) {
    final index = ((opacity * _opacityLevels).round() - 1).clamp(0, _opacityLevels - 1);
    return _paintCache[index];
  }

  /// Initialize all snowflakes in the pool
  void _initializeFlakes() {
    _flakes = List.generate(flakeCount, (index) {
      final flake = _Snowflake();
      flake.reset(_random, spawnArea, randomY: true);
      return flake;
    });
  }

  /// Check if a point should be hidden (in excluded area but not in include zone)
  bool _shouldHideSnowflake(double x, double y) {
    final point = Offset(x, y);

    // First check if in an include zone - these override exclusions
    for (final zone in includeZones) {
      if (zone.contains(point)) {
        return false; // Show snow in include zones
      }
    }

    // Then check if in an excluded area
    for (final area in excludeAreas) {
      if (area.contains(point)) {
        return true; // Hide snow in excluded areas
      }
    }

    return false; // Show snow everywhere else
  }

  /// Get the current camera viewport in world coordinates
  Rect _getViewportRect() {
    final cam = game.camera;
    final viewportSize = cam.viewport.size;
    final zoom = cam.viewfinder.zoom;

    // Calculate visible world area based on camera position and zoom
    final worldWidth = viewportSize.x / zoom;
    final worldHeight = viewportSize.y / zoom;

    // Camera anchor position is the center of the view
    final camPos = game.player.cameraTarget;

    return Rect.fromCenter(
      center: Offset(camPos.x, camPos.y),
      width: worldWidth,
      height: worldHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Get current viewport for recycling snowflakes
    final viewport = _getViewportRect();

    // Expand viewport slightly for spawning (so flakes don't pop in)
    final spawnMargin = 100.0;
    final expandedViewport = Rect.fromLTRB(
      viewport.left - spawnMargin,
      viewport.top - spawnMargin,
      viewport.right + spawnMargin,
      viewport.bottom + spawnMargin,
    );

    // Update each snowflake
    for (var i = 0; i < _flakes.length; i++) {
      final flake = _flakes[i];

      // Move downward
      flake.y += flake.speed * dt;

      // Horizontal drift using sine wave
      flake.x += sin(_time * 1.5 + flake.phase) * flake.drift * dt;

      // Recycle if fallen below viewport or drifted too far
      final needsRecycle = flake.y > expandedViewport.bottom ||
          flake.x < expandedViewport.left - 50 ||
          flake.x > expandedViewport.right + 50;

      if (needsRecycle) {
        // Respawn at top of viewport with random X within viewport width
        flake.x = viewport.left + _random.nextDouble() * viewport.width;
        flake.y = viewport.top - _random.nextDouble() * 50;
        // Randomize other properties slightly for variety
        flake.speed = 25 + _random.nextDouble() * 40;
        flake.phase = _random.nextDouble() * 2 * pi;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Get current viewport for culling
    final viewport = _getViewportRect();

    // Small margin for rendering (so flakes don't disappear at edges)
    final renderMargin = 20.0;
    final renderRect = Rect.fromLTRB(
      viewport.left - renderMargin,
      viewport.top - renderMargin,
      viewport.right + renderMargin,
      viewport.bottom + renderMargin,
    );

    for (final flake in _flakes) {
      // Skip flakes outside viewport
      if (flake.x < renderRect.left ||
          flake.x > renderRect.right ||
          flake.y < renderRect.top ||
          flake.y > renderRect.bottom) {
        continue;
      }

      // Skip flakes inside excluded areas (unless in include zone)
      if (_shouldHideSnowflake(flake.x, flake.y)) {
        continue;
      }

      // Draw simple circle with cached paint
      canvas.drawCircle(
        Offset(flake.x, flake.y),
        flake.size,
        _getPaintForOpacity(flake.opacity),
      );
    }
  }
}

/// Factory for creating SnowEffect with current level bounds
class SnowEffectFactory {
  /// Creates a SnowEffect configured for the game's background area
  /// excluding the current level's bounds
  static SnowEffect createForGame(MemoryLaneGame game) {
    // The background spans this area (from _loadBackground in memory_lane_game.dart)
    const spawnArea = Rect.fromLTWH(-750, -500, 6336, 3000);

    // Get exclusion areas based on current level
    final excludeAreas = <Rect>[];

    // Always exclude both level areas since snow should only be outside
    // Main floor level bounds (based on obstacle data)
    excludeAreas.add(const Rect.fromLTWH(134, 114, 2961, 1051)); // HouseMap area

    // Upstairs level bounds (based on obstacle data)
    excludeAreas.add(const Rect.fromLTWH(84, 84, 2071, 1719)); // UpstairsMap area

    // Include zones - areas INSIDE levels where snow should still appear
    final includeZones = <Rect>[
      // Outdoor/patio area on main floor
      const Rect.fromLTWH(2003, 114, 1189, 345),
    ];

    return SnowEffect(
      flakeCount: 500,
      spawnArea: spawnArea,
      excludeAreas: excludeAreas,
      includeZones: includeZones,
    );
  }
}
