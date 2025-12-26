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

  /// Distance threshold for collecting (in pixels) - base value for main floor
  static const double _baseCollectDistance = 150.0;

  /// Distance at which memories start becoming visible - base value for main floor
  static const double _baseVisibilityStartDistance = 400.0;

  /// Distance at which memories are fully visible - base value for main floor
  static const double _baseVisibilityFullDistance = 200.0;

  /// Upstairs scale multiplier (matches player scale difference)
  static const double _upstairsMultiplier = 2.0;

  /// Get current collect distance based on level
  double get collectDistance {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseCollectDistance * _upstairsMultiplier;
    }
    return _baseCollectDistance;
  }

  /// Get current visibility start distance based on level
  double get visibilityStartDistance {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseVisibilityStartDistance * _upstairsMultiplier;
    }
    return _baseVisibilityStartDistance;
  }

  /// Get current visibility full distance based on level
  double get visibilityFullDistance {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseVisibilityFullDistance * _upstairsMultiplier;
    }
    return _baseVisibilityFullDistance;
  }

  /// The persistently assigned sprite type for this memory
  late final MemorySpriteType _spriteType;

  /// Whether this memory is flipped horizontally
  late final bool _flippedX;

  /// Scale effect when player is nearby
  static const double normalScale = 1.0;
  static const double activeScale = 1.2; // 20% larger when in range
  static const double scaleSpeed = 3.0; // How fast to scale up/down

  double _currentScale = normalScale;

  /// Whether this memory is highlighted as the nearest one
  bool _isHighlighted = false;

  /// The glow effect component
  _SparkleGlow? _sparkleGlow;

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

  /// Whether this memory is highlighted (nearest to player)
  bool get isHighlighted => _isHighlighted;

  /// Set the highlighted state (called from game to mark nearest memory)
  set isHighlighted(bool value) {
    if (_isHighlighted == value) return;
    _isHighlighted = value;

    if (_isHighlighted && _sparkleGlow == null) {
      // Add sparkle glow effect
      _sparkleGlow = _SparkleGlow(memorySize: size.x);
      add(_sparkleGlow!);
    } else if (!_isHighlighted && _sparkleGlow != null) {
      // Remove sparkle glow effect
      _sparkleGlow?.removeFromParent();
      _sparkleGlow = null;
    }
  }

  /// Check if player is close enough to collect
  bool get isPlayerInRange {
    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);
    return distance <= collectDistance;
  }

  /// Mark this memory as already collected (used when loading a level with persisted state)
  void markAsCollected() {
    if (_collected) return;
    _collected = true;
    // Level-triggering and endgame memories stay visible
    if (!memory.persistsAfterCollection) {
      opacity = 0.0; // Hide the memory sprite
    }
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
    // Persistent memories (level/endgame triggers) can always be tapped
    // Regular memories can only be tapped once
    if (_collected && !memory.persistsAfterCollection) return;

    if (isPlayerInRange) {
      collect();
    } else {
      // Optional: show feedback that player is too far
      debugPrint('Too far to collect memory: ${memory.caption}');
    }
  }

  /// Called when the player collects this memory
  void collect() {
    // Persistent memories can be triggered multiple times
    // Regular memories can only be collected once
    if (_collected && !memory.persistsAfterCollection) return;

    // Only mark as collected on first collection (for counting purposes)
    // EXCEPT level triggers - they should remain usable for going up/down stairs
    if (!_collected && !memory.triggersLevel) {
      _collected = true;
    }

    game.triggerMemory(memory);

    // Persistent memories stay visible and interactive
    // Regular memories are removed after collection
    if (!memory.persistsAfterCollection) {
      removeFromParent();
    }
  }

  /// Silently collect this memory (for debug) - no overlay shown
  void collectSilently() {
    if (_collected) return;
    _collected = true;
    game.collectMemorySilently(memory);
    if (!memory.persistsAfterCollection) {
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

  /// Whether this memory triggers the endgame
  final bool isEndgameTrigger;

  /// Whether this memory unlocks a coupon reward
  final bool isCouponReward;

  /// Custom coupon text/details (optional)
  final String? couponText;

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
    this.isEndgameTrigger = false,
    this.isCouponReward = false,
    this.couponText,
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
    this.isEndgameTrigger = false,
    this.isCouponReward = false,
    this.couponText,
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
        isEndgameTrigger: isEndgameTrigger,
        isCouponReward: isCouponReward,
        couponText: couponText,
      ),
      showDebug: showDebug,
      baseScale: scale,
    );
  }
}

/// Sparkle glow effect that pulses around a memory item
class _SparkleGlow extends PositionComponent with HasGameReference<MemoryLaneGame> {
  final double memorySize;

  /// Animation phase (0 to 2π)
  double _phase = 0.0;

  /// Pulse speed in radians per second
  static const double _pulseSpeed = 5.0;

  /// Base glow radius multiplier
  static const double _baseRadius = 0.8;

  /// Pulse amplitude (how much the glow expands/contracts)
  static const double _pulseAmplitude = 0.15;

  _SparkleGlow({required this.memorySize})
      : super(
          position: Vector2.all(memorySize / 2),
          anchor: Anchor.center,
          priority: -1, // Render behind the sprite
        );

  @override
  void update(double dt) {
    super.update(dt);
    _phase = (_phase + _pulseSpeed * dt) % (2 * pi);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Calculate pulsing radius
    final pulseValue = sin(_phase);
    final radius = memorySize * (_baseRadius + _pulseAmplitude * pulseValue);

    // Draw outer glow (larger, more transparent)
    final outerPaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.2 + 0.1 * pulseValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.4);
    canvas.drawCircle(Offset.zero, radius * 1.3, outerPaint);

    // Draw middle glow
    final middlePaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.3 + 0.15 * pulseValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.25);
    canvas.drawCircle(Offset.zero, radius, middlePaint);

    // Draw inner bright core
    final innerPaint = Paint()
      ..color = const Color(0xFFFFFFAA).withValues(alpha: 0.4 + 0.2 * pulseValue)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.15);
    canvas.drawCircle(Offset.zero, radius * 0.6, innerPaint);

    // Draw sparkle rays
    _drawSparkleRays(canvas, radius, pulseValue);
  }

  void _drawSparkleRays(Canvas canvas, double radius, double pulseValue) {
    final rayPaint = Paint()
      ..color = const Color(0xFFFFFFDD).withValues(alpha: 0.5 + 0.3 * pulseValue)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw 4 rays that rotate slowly
    final rayRotation = _phase * 0.3; // Slower rotation
    for (var i = 0; i < 4; i++) {
      final angle = rayRotation + (i * pi / 2);
      final innerRadius = radius * 0.5;
      final outerRadius = radius * (1.1 + 0.2 * pulseValue);

      final start = Offset(cos(angle) * innerRadius, sin(angle) * innerRadius);
      final end = Offset(cos(angle) * outerRadius, sin(angle) * outerRadius);

      canvas.drawLine(start, end, rayPaint);
    }
  }
}
