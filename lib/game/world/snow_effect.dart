import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// A snowflake particle
class _Snowflake {
  double x;
  double y;
  final double size;
  final double speed;
  final double drift; // Horizontal drift amplitude
  final double phase; // Phase offset for sine wave drift
  final double opacity;

  _Snowflake({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.drift,
    required this.phase,
    required this.opacity,
  });
}

/// Snow effect that renders falling snowflakes outside of level bounds
class SnowEffect extends PositionComponent with HasGameReference<MemoryLaneGame> {
  /// Number of snowflakes to render
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

  /// List of snowflakes
  late final List<_Snowflake> _flakes;

  /// Paint for snowflakes
  final Paint _snowPaint = Paint()..color = Colors.white;

  SnowEffect({
    this.flakeCount = 300,
    required this.spawnArea,
    this.excludeAreas = const [],
    this.includeZones = const [],
  }) : super(priority: 50); // Render above background, below fog

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeFlakes();
  }

  /// Initialize all snowflakes with random positions
  void _initializeFlakes() {
    _flakes = List.generate(flakeCount, (index) => _createFlake(randomY: true));
  }

  /// Create a single snowflake with random properties
  _Snowflake _createFlake({bool randomY = false}) {
    final x = spawnArea.left + _random.nextDouble() * spawnArea.width;
    final y = randomY
        ? spawnArea.top + _random.nextDouble() * spawnArea.height
        : spawnArea.top - _random.nextDouble() * 50; // Start just above visible area

    return _Snowflake(
      x: x,
      y: y,
      size: 2 + _random.nextDouble() * 4, // 2-6 pixel radius
      speed: 30 + _random.nextDouble() * 50, // 30-80 pixels per second
      drift: 10 + _random.nextDouble() * 20, // Horizontal drift amount
      phase: _random.nextDouble() * 2 * pi,
      opacity: 0.4 + _random.nextDouble() * 0.6, // 0.4-1.0 opacity
    );
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

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;

    // Update each snowflake
    for (var i = 0; i < _flakes.length; i++) {
      final flake = _flakes[i];

      // Move downward
      flake.y += flake.speed * dt;

      // Horizontal drift using sine wave
      flake.x += sin(_time * 1.5 + flake.phase) * flake.drift * dt;

      // Reset if fallen below spawn area
      if (flake.y > spawnArea.bottom + 20) {
        _flakes[i] = _createFlake(randomY: false);
      }

      // Reset if drifted too far horizontally
      if (flake.x < spawnArea.left - 50 || flake.x > spawnArea.right + 50) {
        _flakes[i] = _createFlake(randomY: false);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final flake in _flakes) {
      // Skip flakes inside excluded areas (unless in include zone)
      if (_shouldHideSnowflake(flake.x, flake.y)) {
        continue;
      }

      // Draw snowflake with gradient for soft edges
      final gradient = ui.Gradient.radial(
        Offset(flake.x, flake.y),
        flake.size,
        [
          Colors.white.withValues(alpha: flake.opacity),
          Colors.white.withValues(alpha: flake.opacity * 0.5),
          Colors.white.withValues(alpha: 0),
        ],
        [0.0, 0.5, 1.0],
      );

      canvas.drawCircle(
        Offset(flake.x, flake.y),
        flake.size,
        _snowPaint..shader = gradient,
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
      flakeCount: 10000,
      spawnArea: spawnArea,
      excludeAreas: excludeAreas,
      includeZones: includeZones,
    );
  }
}
