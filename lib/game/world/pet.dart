import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// Defines a pet sprite configuration
class PetSpriteConfig {
  final String assetPath;
  final int columns;
  final int rows;
  final double displaySize;
  final double animationSpeed;

  const PetSpriteConfig({
    required this.assetPath,
    this.columns = 4,
    this.rows = 4,
    this.displaySize = 100.0,
    this.animationSpeed = 0.2,
  });

  int get frameCount => columns * rows;
}

/// An interactive pet character (dog, cat, etc.)
class Pet extends SpriteAnimationComponent
    with TapCallbacks, CollisionCallbacks, HasGameReference<MemoryLaneGame> {
  /// The pet's name
  final String name;

  /// Sprite configuration
  final PetSpriteConfig spriteConfig;

  /// Whether to show debug visualization
  final bool showDebug;

  /// Base scale multiplier
  final double baseScale;

  /// Whether the pet is flipped horizontally
  final bool flipped;

  /// Collision radius for blocking player movement (0 = no collision)
  final double collisionRadius;

  /// Distance threshold for interaction (in pixels) - base value for main floor
  static const double _baseInteractDistance = 150.0;

  /// Distance at which pets start becoming visible (fog of war) - base value
  /// 40% further than memories (400 * 1.4 = 560)
  static const double _baseVisibilityStartDistance = 560.0;

  /// Distance at which pets are fully visible - base value
  /// 40% further than memories (200 * 1.4 = 280)
  static const double _baseVisibilityFullDistance = 280.0;

  /// Upstairs scale multiplier (matches player scale difference)
  static const double _upstairsMultiplier = 2.0;

  /// Get current interact distance based on level
  double get interactDistance {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseInteractDistance * _upstairsMultiplier;
    }
    return _baseInteractDistance;
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

  /// Sleeping Z animation
  double _zTime = 0;
  final List<_SleepingZ> _sleepingZs = [];

  Pet({
    required Vector2 position,
    required this.name,
    required this.spriteConfig,
    this.showDebug = false,
    this.baseScale = 1.0,
    this.flipped = false,
    this.collisionRadius = 0.0,
  }) : super(
          position: position,
          size: Vector2.all(spriteConfig.displaySize * baseScale),
          anchor: Anchor.center,
        );

  /// Check if player is close enough to interact
  bool get isPlayerInRange {
    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);
    return distance <= interactDistance;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSize = spriteConfig.displaySize;
    size = Vector2.all(spriteSize * baseScale);

    // Load the sprite sheet
    final image = await game.images.load(spriteConfig.assetPath);
    final frameWidth = (image.width ~/ spriteConfig.columns).toDouble();
    final frameHeight = (image.height ~/ spriteConfig.rows).toDouble();

    final spriteSheet = SpriteSheet(
      image: image,
      srcSize: Vector2(frameWidth, frameHeight),
    );

    // Create looping animation from all frames
    final frames = <Sprite>[];
    for (var row = 0; row < spriteConfig.rows; row++) {
      for (var col = 0; col < spriteConfig.columns; col++) {
        frames.add(spriteSheet.getSprite(row, col));
      }
    }

    animation = SpriteAnimation.spriteList(
      frames,
      stepTime: spriteConfig.animationSpeed,
      loop: true,
    );

    // Start at a random frame
    final random = Random();
    animationTicker?.currentIndex = random.nextInt(frames.length);

    // Apply horizontal flip if needed
    if (flipped) {
      scale = Vector2(-1.0, 1.0);
    }

    // Add hitbox for tap detection
    add(CircleHitbox(
      radius: (spriteSize * baseScale) / 2 + 30,
      position: size / 2,
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    ));

    // Add collision obstacle hitbox if radius is set
    if (collisionRadius > 0) {
      final scaledCollisionRadius = collisionRadius * baseScale;
      debugPrint('Pet $name: Adding collision hitbox with radius $scaledCollisionRadius');
      add(CircleHitbox(
        radius: scaledCollisionRadius,
        position: size / 2,
        anchor: Anchor.center,
        collisionType: CollisionType.passive,
      ));

      // Debug visualization for collision
      if (showDebug) {
        add(CircleComponent(
          radius: scaledCollisionRadius,
          position: size / 2,
          anchor: Anchor.center,
          paint: Paint()
            ..color = Colors.red.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill,
        ));
      }
    }

    // Debug visualization for interaction range
    if (showDebug) {
      add(CircleComponent(
        radius: _baseInteractDistance,
        position: size / 2,
        anchor: Anchor.center,
        paint: Paint()
          ..color = Colors.blue.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);

    // Update opacity based on distance (fog of war effect)
    if (distance >= visibilityStartDistance) {
      opacity = 0.0;
    } else if (distance <= visibilityFullDistance) {
      opacity = 1.0;
    } else {
      final fadeRange = visibilityStartDistance - visibilityFullDistance;
      final fadeProgress = (visibilityStartDistance - distance) / fadeRange;
      opacity = fadeProgress.clamp(0.0, 1.0);
    }

    // Update sleeping Z animation
    _zTime += dt;
    if (_zTime >= 1.5) {
      _zTime = 0;
      _spawnSleepingZ();
    }

    // Update existing Zs
    for (final z in _sleepingZs) {
      z.update(dt);
    }
    _sleepingZs.removeWhere((z) => z.isDone);
  }

  void _spawnSleepingZ() {
    _sleepingZs.add(_SleepingZ(
      startX: size.x * 0.7,
      startY: size.y * 0.2,
    ));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render sleeping Zs
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final z in _sleepingZs) {
      textPainter.text = TextSpan(
        text: 'z',
        style: TextStyle(
          fontSize: 14 + z.scale * 8,
          color: Colors.white.withValues(alpha: z.alpha),
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: z.alpha * 0.5),
              blurRadius: 2,
            ),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(z.x, z.y));
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isPlayerInRange) {
      _onInteract();
    } else {
      debugPrint('Too far to pet $name');
    }
  }

  void _onInteract() {
    debugPrint('Petting $name!');
    // Could trigger a sound, animation change, or UI popup here
  }
}

/// Floating Z animation for sleeping pets
class _SleepingZ {
  double x;
  double y;
  double alpha = 1.0;
  double scale = 0.0;
  double lifetime = 0;
  static const double maxLifetime = 2.0;

  _SleepingZ({required double startX, required double startY})
      : x = startX,
        y = startY;

  void update(double dt) {
    lifetime += dt;
    final progress = lifetime / maxLifetime;

    // Float up and to the right
    x += dt * 15;
    y -= dt * 25;

    // Scale up then fade out
    if (progress < 0.3) {
      scale = progress / 0.3;
      alpha = 1.0;
    } else {
      scale = 1.0;
      alpha = 1.0 - ((progress - 0.3) / 0.7);
    }
  }

  bool get isDone => lifetime >= maxLifetime;
}

/// Data class for defining pets in maps
class PetData {
  final double x;
  final double y;
  final String name;
  final String spritePath;
  final int columns;
  final int rows;
  final double displaySize;
  final double animationSpeed;
  final double scale;
  final bool flipped;
  final double collisionRadius;

  const PetData({
    required this.x,
    required this.y,
    required this.name,
    required this.spritePath,
    this.columns = 4,
    this.rows = 4,
    this.displaySize = 100.0,
    this.animationSpeed = 0.2,
    this.scale = 1.0,
    this.flipped = false,
    this.collisionRadius = 0.0,
  });

  Pet toPet({bool showDebug = false}) {
    return Pet(
      position: Vector2(x, y),
      name: name,
      spriteConfig: PetSpriteConfig(
        assetPath: spritePath,
        columns: columns,
        rows: rows,
        displaySize: displaySize,
        animationSpeed: animationSpeed,
      ),
      showDebug: showDebug,
      baseScale: scale,
      flipped: flipped,
      collisionRadius: collisionRadius,
    );
  }
}
