import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// Type of character for different behaviors
enum CharacterType {
  /// A pet (dog, cat) - shows sleeping Zs
  pet,

  /// A person (mom, dad) - no sleeping Zs
  person,
}

/// Defines a character sprite configuration
class CharacterSpriteConfig {
  final String assetPath;
  final int columns;
  final int rows;
  final double displaySize;
  final double animationSpeed;

  const CharacterSpriteConfig({
    required this.assetPath,
    this.columns = 4,
    this.rows = 4,
    this.displaySize = 100.0,
    this.animationSpeed = 0.2,
  });

  int get frameCount => columns * rows;
}

/// An interactive character (pet or person)
class Character extends SpriteAnimationComponent
    with TapCallbacks, CollisionCallbacks, HasGameReference<MemoryLaneGame> {
  /// The character's name
  final String name;

  /// Sprite configuration
  final CharacterSpriteConfig spriteConfig;

  /// Whether to show debug visualization
  final bool showDebug;

  /// Base scale multiplier
  final double baseScale;

  /// Whether the character is flipped horizontally
  final bool flipped;

  /// Collision radius for blocking player movement (0 = no collision)
  final double collisionRadius;

  /// Y offset for collision hitbox (positive = lower on sprite)
  final double collisionOffsetY;

  /// Type of character (affects behavior like sleeping Zs)
  final CharacterType characterType;

  /// Custom interaction message (optional)
  final String? interactionMessage;

  /// Distance threshold for interaction (in pixels) - base value for main floor
  static const double _baseInteractDistance = 150.0;

  /// Distance at which characters start becoming visible (fog of war) - base value
  static const double _baseVisibilityStartDistance = 560.0;

  /// Distance at which characters are fully visible - base value
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

  /// Sleeping Z animation (for pets only)
  double _zTime = 0;
  final List<_SleepingZ> _sleepingZs = [];

  /// Interaction indicator animation
  final List<_InteractionHeart> _hearts = [];
  double _interactionCooldown = 0;

  Character({
    required Vector2 position,
    required this.name,
    required this.spriteConfig,
    this.showDebug = false,
    this.baseScale = 1.0,
    this.flipped = false,
    this.collisionRadius = 0.0,
    this.collisionOffsetY = 0.0,
    this.characterType = CharacterType.pet,
    this.interactionMessage,
  }) : super(
          position: position,
          size: Vector2.all(spriteConfig.displaySize * baseScale),
          anchor: Anchor.center,
        );

  /// Whether this character has collision enabled
  bool get hasCollision => collisionRadius > 0;

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

    // Add hitboxes - either tap-only OR collision (which also handles tap)
    if (collisionRadius > 0) {
      // Use collision hitbox (also handles tap detection)
      final scaledCollisionRadius = collisionRadius * baseScale;
      final hitboxPosition = Vector2(size.x / 2, size.y / 2 + collisionOffsetY);
      debugPrint('Character $name: Adding collision hitbox with radius $scaledCollisionRadius');
      add(CircleHitbox(
        radius: scaledCollisionRadius,
        position: hitboxPosition,
        anchor: Anchor.center,
        collisionType: CollisionType.passive,
      ));

      // Debug visualization for collision (only visible when debug panel is open)
      add(DebugCircleComponent(
        radius: scaledCollisionRadius,
        position: hitboxPosition,
        anchor: Anchor.center,
        color: Colors.red,
        filled: true,
      ));
    } else {
      // No collision - add tap-only hitbox at center
      final tapRadius = (spriteSize * baseScale) / 2 + 30;
      add(CircleHitbox(
        radius: tapRadius,
        position: size / 2,
        anchor: Anchor.center,
        collisionType: CollisionType.passive,
      ));

      // Debug visualization for tap hitbox (only visible when debug panel is open)
      add(DebugCircleComponent(
        radius: tapRadius,
        position: size / 2,
        anchor: Anchor.center,
        color: Colors.grey,
        filled: false,
        strokeWidth: 1,
      ));
    }

    // Debug visualization for interaction range (only visible when debug panel is open)
    add(DebugCircleComponent(
      radius: _baseInteractDistance,
      position: size / 2,
      anchor: Anchor.center,
      color: Colors.blue,
      filled: false,
      strokeWidth: 1,
    ));
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

    // Update sleeping Z animation (pets only)
    if (characterType == CharacterType.pet) {
      _zTime += dt;
      if (_zTime >= 1.5) {
        _zTime = 0;
        _spawnSleepingZ();
      }

      for (final z in _sleepingZs) {
        z.update(dt);
      }
      _sleepingZs.removeWhere((z) => z.isDone);
    }

    // Update interaction hearts
    for (final heart in _hearts) {
      heart.update(dt);
    }
    _hearts.removeWhere((h) => h.isDone);

    // Update interaction cooldown
    if (_interactionCooldown > 0) {
      _interactionCooldown -= dt;
    }
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

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Render sleeping Zs (pets only)
    if (characterType == CharacterType.pet) {
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

    // Render interaction hearts
    for (final heart in _hearts) {
      if (heart.delay > 0) continue;

      textPainter.text = TextSpan(
        text: heart.symbol,
        style: TextStyle(
          fontSize: 21 + heart.scale * 13, // 30% larger
          color: heart.color.withValues(alpha: heart.alpha),
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: heart.alpha * 0.3),
              blurRadius: 3,
            ),
          ],
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(heart.x, heart.y));
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (isPlayerInRange && _interactionCooldown <= 0) {
      _onInteract();
    } else if (!isPlayerInRange) {
      debugPrint('Too far to interact with $name');
    }
  }

  void _onInteract() {
    debugPrint('Interacting with $name!');

    // Set cooldown to prevent spam
    _interactionCooldown = 1.5;

    // Trigger focused character interaction view
    game.startCharacterInteraction(this);
  }
}

/// Floating Z animation for sleeping characters
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

/// Floating heart/love animation for interactions
class _InteractionHeart {
  double x;
  double y;
  double alpha = 1.0;
  double scale = 0.0;
  double lifetime = 0;
  double delay;
  final bool isPerson;
  static const double maxLifetime = 1.5;

  // Different symbols for pets vs people
  late final String symbol;
  late final Color color;

  _InteractionHeart({
    required double startX,
    required double startY,
    this.delay = 0,
    this.isPerson = false,
  })  : x = startX,
        y = startY {
    final random = Random();
    if (isPerson) {
      // Hearts and sparkles for people
      symbol = ['❤', '💕', '✨', '💗'][random.nextInt(4)];
      color = [Colors.pink, Colors.red, Colors.amber, Colors.pinkAccent][random.nextInt(4)];
    } else {
      // Paw prints and hearts for pets
      symbol = ['❤', '🐾', '💕', '✨'][random.nextInt(4)];
      color = [Colors.pink, Colors.brown, Colors.red, Colors.amber][random.nextInt(4)];
    }
  }

  void update(double dt) {
    if (delay > 0) {
      delay -= dt;
      return;
    }

    lifetime += dt;
    final progress = lifetime / maxLifetime;

    // Float up with slight wobble
    x += dt * 5 * sin(lifetime * 8);
    y -= dt * 40;

    // Scale up quickly then fade out
    if (progress < 0.2) {
      scale = progress / 0.2;
      alpha = 1.0;
    } else {
      scale = 1.0;
      alpha = 1.0 - ((progress - 0.2) / 0.8);
    }
  }

  bool get isDone => lifetime >= maxLifetime;
}

/// Data class for defining characters in maps
class CharacterData {
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
  final double collisionOffsetY;
  final CharacterType characterType;
  final String? interactionMessage;

  const CharacterData({
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
    this.collisionOffsetY = 0.0,
    this.characterType = CharacterType.pet,
    this.interactionMessage,
  });

  Character toCharacter({bool showDebug = false}) {
    return Character(
      position: Vector2(x, y),
      name: name,
      spriteConfig: CharacterSpriteConfig(
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
      collisionOffsetY: collisionOffsetY,
      characterType: characterType,
      interactionMessage: interactionMessage,
    );
  }
}

// Keep Pet and PetData as aliases for backwards compatibility
typedef Pet = Character;
typedef PetData = CharacterData;
typedef PetSpriteConfig = CharacterSpriteConfig;

/// A circle component that only renders when debug panel is open
class DebugCircleComponent extends PositionComponent {
  final double radius;
  final Color color;
  final bool filled;
  final double strokeWidth;

  DebugCircleComponent({
    required this.radius,
    required super.position,
    required super.anchor,
    this.color = Colors.red,
    this.filled = true,
    this.strokeWidth = 2.0,
  }) : super(size: Vector2.all(radius * 2));

  @override
  void render(Canvas canvas) {
    // Only render when debug panel is open
    if (!MemoryLaneGame.showDebugPanel) return;

    final paint = Paint()
      ..color = color.withValues(alpha: filled ? 0.3 : 0.5)
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(Offset(radius, radius), radius, paint);
  }
}
