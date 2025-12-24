import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// A collectible memory item that triggers a photo overlay when touched
class MemoryItem extends PositionComponent
    with CollisionCallbacks, HasGameReference<MemoryLaneGame> {
  /// The memory data associated with this item
  final Memory memory;

  /// Whether to show debug visualization
  final bool showDebug;

  /// Whether this memory has been collected
  bool _collected = false;

  MemoryItem({
    required Vector2 position,
    required this.memory,
    this.showDebug = false,
  }) : super(
          position: position,
          size: Vector2.all(64), // Pickup radius
          anchor: Anchor.center,
        );

  bool get isCollected => _collected;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add circular hitbox for collision detection
    add(CircleHitbox(
      radius: 32,
      position: size / 2,
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    ));

    // Add debug visualization if enabled
    if (showDebug) {
      // Outer glow circle
      add(CircleComponent(
        radius: 32,
        position: size / 2,
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.amber.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      ));
      // Inner circle
      add(CircleComponent(
        radius: 16,
        position: size / 2,
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.fill,
      ));
      // Border
      add(CircleComponent(
        radius: 32,
        position: size / 2,
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.amber
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ));
    }

    // TODO: Add actual sprite for memory item (glowing photo, sparkle, etc.)
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
