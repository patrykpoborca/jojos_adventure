import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// Defines a sprite type for memory items
class MemorySpriteType {
  final String assetPath;
  final int columns;
  final int rows;
  final double displaySize;
  final double animationSpeed;

  const MemorySpriteType({
    required this.assetPath,
    required this.columns,
    required this.rows,
    this.displaySize = 80.0,
    this.animationSpeed = 0.15,
  });

  int get frameCount => columns * rows;
}

/// Available memory sprite types - add new sprites here
/// animationSpeed = seconds per frame (higher = slower)
class MemorySpriteTypes {
  static const List<MemorySpriteType> all = [
    MemorySpriteType(
      assetPath: 'sprites/memories.png',
      columns: 4,
      rows: 4,
      displaySize: 60.0,
      animationSpeed: 0.25,
    ),
    MemorySpriteType(
      assetPath: 'sprites/memories_2.png',
      columns: 4,
      rows: 4,
      displaySize: 64.0,
      animationSpeed: 0.25,
    ),
    MemorySpriteType(
      assetPath: 'sprites/memories_3.png',
      columns: 4,
      rows: 4,
      displaySize: 64.0,
      animationSpeed: 0.25,
    ),
    MemorySpriteType(
      assetPath: 'sprites/memories_4.png',
      columns: 4,
      rows: 4,
      displaySize: 84.0,
      animationSpeed: 0.25,
    ),
  ];

  static final Random _random = Random();

  /// Shuffled bag of sprite indices for even distribution
  static List<int> _bag = [];

  /// Persistent map of memory key -> sprite type index
  /// This ensures memories keep the same sprite across level loads
  static final Map<String, int> _assignedSprites = {};

  /// Reset the bag (call on game restart for fresh randomization)
  /// Note: Does NOT clear assigned sprites - those persist for the session
  static void resetBag() {
    _bag = [];
  }

  /// Fully reset all sprite assignments (call on new game)
  static void resetAll() {
    _bag = [];
    _assignedSprites.clear();
  }

  /// Get sprite type for a memory, using persistent assignment
  /// Uses memoryKey (e.g., stylizedPhotoPath) for consistent assignment
  static MemorySpriteType getForMemory(String memoryKey) {
    // Check if already assigned
    if (_assignedSprites.containsKey(memoryKey)) {
      return all[_assignedSprites[memoryKey]!];
    }

    // Assign a new sprite from the bag
    if (_bag.isEmpty) {
      _refillBag();
    }

    // Pick from bag using key hash for some consistency
    final keyHash = memoryKey.hashCode.abs() % _bag.length;
    final index = _bag.removeAt(keyHash);

    // Store the assignment
    _assignedSprites[memoryKey] = index;

    return all[index];
  }

  /// Get the sprite type index for a memory key (for tracking collected memories)
  static int? getSpriteIndexForMemory(String memoryKey) {
    return _assignedSprites[memoryKey];
  }

  /// Refill the bag with multiple copies of each type, shuffled
  static void _refillBag() {
    // Add each type multiple times for better distribution
    const copiesPerType = 3;
    _bag = [];
    for (var i = 0; i < all.length; i++) {
      for (var j = 0; j < copiesPerType; j++) {
        _bag.add(i);
      }
    }
    // Shuffle the bag
    _bag.shuffle(_random);
  }

  /// Get a random sprite type (legacy, use getForMemory for persistence)
  static MemorySpriteType getRandom() {
    return all[_random.nextInt(all.length)];
  }
}

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

  /// Distance at which memories start becoming visible
  static const double visibilityStartDistance = 400.0;

  /// Distance at which memories are fully visible
  static const double visibilityFullDistance = 200.0;

  /// The persistently assigned sprite type for this memory
  late final MemorySpriteType _spriteType;

  /// Whether this memory is flipped horizontally
  late final bool _flippedX;

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
  }) : _spriteType = MemorySpriteTypes.getForMemory(memory.stylizedPhotoPath),
       _flippedX = Random().nextBool(),
       super(
          position: position,
          size: Vector2.all(80.0 * baseScale), // Initial size, updated in onLoad
          anchor: Anchor.center,
        );

  bool get isCollected => _collected;

  /// Get the sprite type assigned to this memory
  MemorySpriteType get spriteType => _spriteType;

  /// Check if player is close enough to collect
  bool get isPlayerInRange {
    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);
    return distance <= collectDistance;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Update size based on the randomly selected sprite type
    final spriteSize = _spriteType.displaySize;
    size = Vector2.all(spriteSize * baseScale);

    // Load the sprite sheet
    final image = await game.images.load(_spriteType.assetPath);
    // Use floor division to get clean integer frame sizes (avoids sub-pixel rendering issues)
    final frameWidth = (image.width ~/ _spriteType.columns).toDouble();
    final frameHeight = (image.height ~/ _spriteType.rows).toDouble();

    final spriteSheet = SpriteSheet(
      image: image,
      srcSize: Vector2(frameWidth, frameHeight),
    );

    // Create looping animation from all frames
    final frames = <Sprite>[];
    for (var row = 0; row < _spriteType.rows; row++) {
      for (var col = 0; col < _spriteType.columns; col++) {
        frames.add(spriteSheet.getSprite(row, col));
      }
    }

    animation = SpriteAnimation.spriteList(
      frames,
      stepTime: _spriteType.animationSpeed,
      loop: true,
    );

    // Start at a random frame so memories don't synchronize
    final random = Random();
    final randomStartFrame = random.nextInt(frames.length);
    animationTicker?.currentIndex = randomStartFrame;

    // Apply random horizontal flip
    if (_flippedX) {
      scale = Vector2(-1.0, 1.0);
    }

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

    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);

    // Update opacity based on distance (fog of war effect)
    if (distance >= visibilityStartDistance) {
      opacity = 0.0;
    } else if (distance <= visibilityFullDistance) {
      opacity = 1.0;
    } else {
      // Gradual fade between full and start distances
      final fadeRange = visibilityStartDistance - visibilityFullDistance;
      final fadeProgress = (visibilityStartDistance - distance) / fadeRange;
      opacity = fadeProgress.clamp(0.0, 1.0);
    }

    // Smoothly scale up/down based on player proximity
    final targetScale = isPlayerInRange ? activeScale : normalScale;
    if (_currentScale != targetScale) {
      if (_currentScale < targetScale) {
        _currentScale = (_currentScale + scaleSpeed * dt).clamp(normalScale, activeScale);
      } else {
        _currentScale = (_currentScale - scaleSpeed * dt).clamp(normalScale, activeScale);
      }
      // Preserve horizontal flip when scaling
      final xScale = _flippedX ? -_currentScale : _currentScale;
      scale = Vector2(xScale, _currentScale);
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
