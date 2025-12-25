import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// A twinkling Christmas lights effect arranged in a triangle shape
class ChristmasLights extends PositionComponent with HasGameReference<MemoryLaneGame> {
  /// Triangle vertices (in world coordinates)
  final Vector2 vertex1; // Top
  final Vector2 vertex2; // Bottom left/right
  final Vector2 vertex3; // Bottom right/left

  /// Number of lights per edge
  final int lightsPerEdge;

  /// Colors for the lights
  static const List<Color> lightColors = [
    Color(0xFFFF4444), // Red
    Color(0xFF44FF44), // Green
    Color(0xFFFFDD44), // Gold
    Color(0xFF4488FF), // Blue
    Color(0xFFFF88FF), // Pink
  ];

  /// Animation state
  double _time = 0;
  final Random _random = Random();
  late final List<_LightBulb> _bulbs;

  /// Center of the triangle (for fog piercing)
  late final Vector2 triangleCenter;

  /// Approximate radius for fog piercing
  late final double fogPierceRadius;

  ChristmasLights({
    required this.vertex1,
    required this.vertex2,
    required this.vertex3,
    this.lightsPerEdge = 6,
  }) : super(position: Vector2.zero(), anchor: Anchor.topLeft);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Calculate center of triangle
    triangleCenter = Vector2(
      (vertex1.x + vertex2.x + vertex3.x) / 3,
      (vertex1.y + vertex2.y + vertex3.y) / 3,
    );

    // Calculate fog pierce radius (distance from center to farthest vertex + padding)
    final d1 = triangleCenter.distanceTo(vertex1);
    final d2 = triangleCenter.distanceTo(vertex2);
    final d3 = triangleCenter.distanceTo(vertex3);
    fogPierceRadius = max(max(d1, d2), d3) + 50;

    // Create light bulbs along triangle edges
    _bulbs = [];
    _addEdgeLights(vertex1, vertex2);
    _addEdgeLights(vertex2, vertex3);
    _addEdgeLights(vertex3, vertex1);
  }

  /// Add lights along an edge between two vertices
  void _addEdgeLights(Vector2 from, Vector2 to) {
    for (var i = 0; i < lightsPerEdge; i++) {
      final t = i / lightsPerEdge;
      final pos = Vector2(
        from.x + (to.x - from.x) * t,
        from.y + (to.y - from.y) * t,
      );
      _bulbs.add(_LightBulb(
        position: pos,
        color: lightColors[_random.nextInt(lightColors.length)],
        phase: _random.nextDouble() * 2 * pi,
        speed: 1.5 + _random.nextDouble() * 1.5,
      ));
    }
  }

  /// Get the triangle vertices for fog piercing
  List<Vector2> get triangleVertices => [vertex1, vertex2, vertex3];

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw soft glow inside the triangle
    final path = Path()
      ..moveTo(vertex1.x, vertex1.y)
      ..lineTo(vertex2.x, vertex2.y)
      ..lineTo(vertex3.x, vertex3.y)
      ..close();

    // Gradient glow from center
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.amber.withValues(alpha: 0.12),
          Colors.amber.withValues(alpha: 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(
        center: Offset(triangleCenter.x, triangleCenter.y),
        radius: fogPierceRadius,
      ));
    canvas.drawPath(path, glowPaint);

    // Draw individual light bulbs
    for (final bulb in _bulbs) {
      final brightness = 0.5 + 0.5 * sin(_time * bulb.speed + bulb.phase);
      final bulbColor = bulb.color.withValues(alpha: 0.4 + 0.6 * brightness);

      // Glow around bulb
      final bulbGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            bulbColor,
            bulbColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(bulb.position.x, bulb.position.y),
          radius: 15,
        ));
      canvas.drawCircle(
        Offset(bulb.position.x, bulb.position.y),
        15,
        bulbGlowPaint,
      );

      // Bright center
      canvas.drawCircle(
        Offset(bulb.position.x, bulb.position.y),
        4,
        Paint()..color = Colors.white.withValues(alpha: brightness * 0.9),
      );
    }
  }
}

/// Individual light bulb data
class _LightBulb {
  final Vector2 position;
  final Color color;
  final double phase;
  final double speed;

  _LightBulb({
    required this.position,
    required this.color,
    required this.phase,
    required this.speed,
  });
}

/// Data class for placing triangular Christmas lights
class ChristmasLightsData {
  /// Triangle vertices
  final double x1, y1; // Top vertex
  final double x2, y2; // Bottom vertex 1
  final double x3, y3; // Bottom vertex 2

  /// Lights per edge
  final int lightsPerEdge;

  const ChristmasLightsData({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.x3,
    required this.y3,
    this.lightsPerEdge = 6,
  });

  ChristmasLights toComponent() {
    return ChristmasLights(
      vertex1: Vector2(x1, y1),
      vertex2: Vector2(x2, y2),
      vertex3: Vector2(x3, y3),
      lightsPerEdge: lightsPerEdge,
    );
  }

  /// Get center of the triangle
  Vector2 get center => Vector2(
    (x1 + x2 + x3) / 3,
    (y1 + y2 + y3) / 3,
  );
}
