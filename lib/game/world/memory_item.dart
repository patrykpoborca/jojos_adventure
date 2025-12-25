import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// A collectible memory item that triggers a photo overlay when touched
class MemoryItem extends SpriteAnimationComponent
    with CollisionCallbacks, TapCallbacks, HasGameReference<MemoryLaneGame> {
  /// The memory data associated with this item
  final Memory memory;

  /// Whether to show debug visualization
  final bool showDebug;

  /// Base scale multiplier for this memory
  final double baseScale;

  /// Whether this memory has been collected
  bool _collected = false;

  /// Distance threshold for collecting (in pixels)
  static const double collectDistance = 150.0;

  /// Sprite sheet configuration
  static const int sheetColumns = 3;
  static const int sheetRows = 2;
  static const double animationSpeed = 0.15;
  static const double spriteSize = 80.0;

  /// Scale effect when player is nearby
  static const double normalScale = 1.0;
  static const double activeScale = 1.2; // 20% larger when in range
  static const double scaleSpeed = 3.0; // How fast to scale up/down

  double _currentScale = normalScale;

  MemoryItem({
    required Vector2 position,
    required this.memory,
    this.showDebug = false,
    this.baseScale = 1.0,
  }) : super(
          position: position,
          size: Vector2.all(spriteSize * baseScale),
          anchor: Anchor.center,
        );

  bool get isCollected => _collected;

  /// Check if player is close enough to collect
  bool get isPlayerInRange {
    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);
    return distance <= collectDistance;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the sprite sheet (3 columns x 2 rows)
    final image = await game.images.load('sprites/memories.png');
    // Use floor division to get clean integer frame sizes (avoids sub-pixel rendering issues)
    final frameWidth = (image.width ~/ sheetColumns).toDouble();
    final frameHeight = (image.height ~/ sheetRows).toDouble();

    final spriteSheet = SpriteSheet(
      image: image,
      srcSize: Vector2(frameWidth, frameHeight),
    );

    // Create looping animation from all 6 frames (3 columns x 2 rows)
    final frames = <Sprite>[];
    for (var row = 0; row < sheetRows; row++) {
      for (var col = 0; col < sheetColumns; col++) {
        frames.add(spriteSheet.getSprite(row, col));
      }
    }

    animation = SpriteAnimation.spriteList(
      frames,
      stepTime: animationSpeed,
      loop: true,
    );

    // Start at a random frame so memories don't synchronize
    final random = Random();
    final randomStartFrame = random.nextInt(frames.length);
    animationTicker?.currentIndex = randomStartFrame;

    // Add circular hitbox for tap detection (larger than sprite for easier tapping)
    add(CircleHitbox(
      radius: (spriteSize * baseScale) / 2 + 20,
      position: size / 2,
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
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

    if (_collected) return;

    // Smoothly scale up/down based on player proximity
    final targetScale = isPlayerInRange ? activeScale : normalScale;
    if (_currentScale != targetScale) {
      if (_currentScale < targetScale) {
        _currentScale = (_currentScale + scaleSpeed * dt).clamp(normalScale, activeScale);
      } else {
        _currentScale = (_currentScale - scaleSpeed * dt).clamp(normalScale, activeScale);
      }
      scale = Vector2.all(_currentScale);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    // Level-triggering memories can always be tapped (even after collection)
    // Regular memories can only be tapped once
    if (_collected && !memory.triggersLevel) return;

    if (isPlayerInRange) {
      collect();
    } else {
      // Optional: show feedback that player is too far
      debugPrint('Too far to collect memory: ${memory.caption}');
    }
  }

  /// Called when the player collects this memory
  void collect() {
    // Level-triggering memories can be triggered multiple times
    // Regular memories can only be collected once
    if (_collected && !memory.triggersLevel) return;

    // Only mark as collected on first collection (for counting purposes)
    if (!_collected) {
      _collected = true;
    }

    game.triggerMemory(memory);

    // Level-triggering memories stay visible and interactive
    // Regular memories are removed after collection
    if (!memory.triggersLevel) {
      removeFromParent();
    }
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

  /// Which phase this memory belongs to
  final GamePhase phase;

  /// Optional music file to play when viewing
  final String? musicFile;

  const MemoryItemData({
    required this.x,
    required this.y,
    required this.stylizedPhotoPath,
    this.photos = const [],
    required this.date,
    required this.caption,
    this.levelTrigger,
    this.phase = GamePhase.crawling,
    this.musicFile,
  });

  /// Convenience constructor for simple single-photo memories
  const MemoryItemData.simple({
    required this.x,
    required this.y,
    required String photoPath,
    required this.date,
    required this.caption,
    this.levelTrigger,
    this.phase = GamePhase.crawling,
    this.musicFile,
  })  : stylizedPhotoPath = photoPath,
        photos = const [];

  MemoryItem toMemoryItem({bool showDebug = false, double scale = 1.0}) {
    return MemoryItem(
      position: Vector2(x, y),
      memory: Memory(
        stylizedPhotoPath: stylizedPhotoPath,
        photos: photos,
        date: date,
        caption: caption,
        levelTrigger: levelTrigger,
        phase: phase,
        musicFile: musicFile,
      ),
      showDebug: showDebug,
      baseScale: scale,
    );
  }
}
