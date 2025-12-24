import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// A collectible memory item that triggers a photo overlay when touched
class MemoryItem extends PositionComponent
    with CollisionCallbacks, TapCallbacks, HasGameReference<MemoryLaneGame> {
  /// The memory data associated with this item
  final Memory memory;

  /// Whether to show debug visualization
  final bool showDebug;

  /// Whether this memory has been collected
  bool _collected = false;

  /// Distance threshold for collecting (in pixels)
  static const double collectDistance = 150.0;

  MemoryItem({
    required Vector2 position,
    required this.memory,
    this.showDebug = false,
  }) : super(
          position: position,
          size: Vector2.all(100), // Tap area size (larger for easier tapping)
          anchor: Anchor.center,
        );

  bool get isCollected => _collected;

  /// Check if player is close enough to collect
  bool get isPlayerInRange {
    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);
    return distance <= collectDistance;
  }

  // Visual components for glow effect
  CircleComponent? _glowCircle;
  CircleComponent? _innerCircle;
  bool _wasInRange = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add circular hitbox for collision detection
    add(CircleHitbox(
      radius: 50,
      position: size / 2,
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    ));

    // Always add visual indicator (glow when in range)
    _glowCircle = CircleComponent(
      radius: 40,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.amber.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    add(_glowCircle!);

    _innerCircle = CircleComponent(
      radius: 20,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.amber.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );
    add(_innerCircle!);

    // Border
    add(CircleComponent(
      radius: 40,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.amber.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    // Debug: show collect radius
    if (showDebug) {
      add(CircleComponent(
        radius: collectDistance,
        position: size / 2,
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.green.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Update glow effect based on player proximity
    final inRange = isPlayerInRange;
    if (inRange != _wasInRange) {
      _wasInRange = inRange;
      _updateGlowEffect(inRange);
    }
  }

  void _updateGlowEffect(bool inRange) {
    if (inRange) {
      // Bright glow when in range
      _glowCircle?.paint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;
      _innerCircle?.paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
    } else {
      // Dim when out of range
      _glowCircle?.paint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      _innerCircle?.paint = Paint()
        ..color = Colors.amber.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_collected) return;

    if (isPlayerInRange) {
      collect();
    } else {
      // Optional: show feedback that player is too far
      debugPrint('Too far to collect memory: ${memory.caption}');
    }
  }

  /// Called when the player collects this memory
  void collect() {
    if (_collected) return;

    _collected = true;
    game.triggerMemory(memory);

    // TODO: Add collection animation
    // For now, just hide the item
    removeFromParent();
  }
}

/// Helper class to define memory item data
class MemoryItemData {
  final double x;
  final double y;

  /// Stylized cover photo path
  final String stylizedPhotoPath;

  /// List of regular photo paths for slideshow (can be empty)
  final List<String> photos;

  final String date;
  final String caption;

  /// Optional level ID to trigger after viewing
  final String? levelTrigger;

  const MemoryItemData({
    required this.x,
    required this.y,
    required this.stylizedPhotoPath,
    this.photos = const [],
    required this.date,
    required this.caption,
    this.levelTrigger,
  });

  /// Convenience constructor for simple single-photo memories
  const MemoryItemData.simple({
    required this.x,
    required this.y,
    required String photoPath,
    required this.date,
    required this.caption,
    this.levelTrigger,
  })  : stylizedPhotoPath = photoPath,
        photos = const [];

  MemoryItem toMemoryItem({bool showDebug = false}) {
    return MemoryItem(
      position: Vector2(x, y),
      memory: Memory(
        stylizedPhotoPath: stylizedPhotoPath,
        photos: photos,
        date: date,
        caption: caption,
        levelTrigger: levelTrigger,
      ),
      showDebug: showDebug,
    );
  }
}
