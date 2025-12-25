import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';

import '../memory_lane_game.dart';

/// Direction for walking characters (matches baby player)
enum WalkingDirection { down, up, left, right }

/// A character that walks between waypoints using cardinal directions
class WalkingCharacter extends SpriteAnimationComponent
    with TapCallbacks, CollisionCallbacks, HasGameReference<MemoryLaneGame> {
  /// The character's name
  final String name;

  /// Path to sprite sheet (must have rows: down, up, left, right)
  final String spritePath;

  /// Sprite sheet configuration
  final int columns;
  final int rows;
  final double displaySize;
  final double animationSpeed;

  /// Base scale multiplier (Y axis)
  final double baseScale;

  /// X scale multiplier (relative to baseScale, 1.0 = same as baseScale)
  final double scaleX;

  /// Movement speed in pixels per second
  final double walkSpeed;

  /// List of waypoints to walk between
  final List<Vector2> waypoints;

  /// Whether to loop waypoints (true) or ping-pong (false)
  final bool loopWaypoints;

  /// Collision radius (0 = no collision)
  final double collisionRadius;

  /// Custom interaction message
  final String? interactionMessage;

  /// Whether to show debug visualization
  final bool showDebug;

  // Animation maps for each direction
  late final Map<WalkingDirection, SpriteAnimation> _walkAnimations;
  late final SpriteAnimation _idleAnimation;

  // Current state
  int _currentWaypointIndex = 0;
  int _waypointDirection = 1; // 1 = forward, -1 = backward (for ping-pong)
  WalkingDirection _currentDirection = WalkingDirection.down;
  bool _isMoving = false;

  /// Distance threshold for reaching a waypoint
  static const double _waypointThreshold = 5.0;

  /// Pause duration at each waypoint (seconds)
  final double waypointPauseDuration;
  double _pauseTimer = 0;

  /// Distance thresholds for visibility (fog of war)
  static const double _baseVisibilityStartDistance = 560.0;
  static const double _baseVisibilityFullDistance = 280.0;
  static const double _upstairsMultiplier = 2.0;

  /// Interaction distance
  static const double _baseInteractDistance = 150.0;

  /// Interaction cooldown
  double _interactionCooldown = 0;

  /// Interaction hearts
  final List<_InteractionHeart> _hearts = [];

  WalkingCharacter({
    required Vector2 position,
    required this.name,
    required this.spritePath,
    required this.waypoints,
    this.columns = 4,
    this.rows = 4,
    this.displaySize = 100.0,
    this.animationSpeed = 0.15,
    this.baseScale = 1.0,
    this.scaleX = 1.0,
    this.walkSpeed = 60.0,
    this.loopWaypoints = false,
    this.collisionRadius = 0.0,
    this.interactionMessage,
    this.waypointPauseDuration = 1.0,
    this.showDebug = false,
  }) : super(
          position: position,
          size: Vector2(displaySize * baseScale * scaleX, displaySize * baseScale),
          anchor: Anchor.center,
        );

  /// Whether this character has collision enabled
  bool get hasCollision => collisionRadius > 0;

  double get visibilityStartDistance {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseVisibilityStartDistance * _upstairsMultiplier;
    }
    return _baseVisibilityStartDistance;
  }

  double get visibilityFullDistance {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseVisibilityFullDistance * _upstairsMultiplier;
    }
    return _baseVisibilityFullDistance;
  }

  double get interactDistance {
    if (game.currentLevel == LevelId.upstairsNursery) {
      return _baseInteractDistance * _upstairsMultiplier;
    }
    return _baseInteractDistance;
  }

  bool get isPlayerInRange {
    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);
    return distance <= interactDistance;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteSize = displaySize;
    size = Vector2(spriteSize * baseScale * scaleX, spriteSize * baseScale);

    // Load sprite sheet
    final image = await game.images.load(spritePath);
    final frameWidth = (image.width ~/ columns).toDouble();
    final frameHeight = (image.height ~/ rows).toDouble();

    final spriteSheet = SpriteSheet(
      image: image,
      srcSize: Vector2(frameWidth, frameHeight),
    );

    // Create walking animations for each direction
    // Sprite sheet layout: row 0=north(up), 1=west(left), 2=east(right), 3=south(down)
    _walkAnimations = {
      WalkingDirection.up: spriteSheet.createAnimation(
        row: 0,
        stepTime: animationSpeed,
        to: columns,
      ),
      WalkingDirection.left: spriteSheet.createAnimation(
        row: 1,
        stepTime: animationSpeed,
        to: columns,
      ),
      WalkingDirection.right: spriteSheet.createAnimation(
        row: 2,
        stepTime: animationSpeed,
        to: columns,
      ),
      WalkingDirection.down: spriteSheet.createAnimation(
        row: 3,
        stepTime: animationSpeed,
        to: columns,
      ),
    };

    // Idle animation (first frame of down/south direction - row 3)
    if (rows > 4) {
      _idleAnimation = spriteSheet.createAnimation(
        row: 4,
        stepTime: 1.0,
        to: 1,
      );
    } else {
      // Use first frame of south (row 3) for idle
      _idleAnimation = SpriteAnimation.spriteList(
        [spriteSheet.getSprite(3, 0)],
        stepTime: 1.0,
      );
    }

    animation = _idleAnimation;

    // Add hitbox for tap detection
    add(CircleHitbox(
      radius: (spriteSize * baseScale) / 2 + 30,
      position: size / 2,
      anchor: Anchor.center,
      collisionType: CollisionType.passive,
    ));

    // Add collision hitbox if radius is set
    if (collisionRadius > 0) {
      final scaledCollisionRadius = collisionRadius * baseScale;
      add(CircleHitbox(
        radius: scaledCollisionRadius,
        position: size / 2,
        anchor: Anchor.center,
        collisionType: CollisionType.passive,
      ));

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

    // Debug visualization
    if (showDebug) {
      // Draw waypoints
      for (var i = 0; i < waypoints.length; i++) {
        final wp = waypoints[i];
        final relativePos = wp - position;
        add(CircleComponent(
          radius: 10,
          position: relativePos + size / 2,
          anchor: Anchor.center,
          paint: Paint()
            ..color = Colors.yellow.withValues(alpha: 0.7)
            ..style = PaintingStyle.fill,
        ));
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final playerPos = game.player.position;
    final distance = position.distanceTo(playerPos);

    // Update opacity based on distance (fog of war)
    if (distance >= visibilityStartDistance) {
      opacity = 0.0;
    } else if (distance <= visibilityFullDistance) {
      opacity = 1.0;
    } else {
      final fadeRange = visibilityStartDistance - visibilityFullDistance;
      final fadeProgress = (visibilityStartDistance - distance) / fadeRange;
      opacity = fadeProgress.clamp(0.0, 1.0);
    }

    // Update interaction cooldown
    if (_interactionCooldown > 0) {
      _interactionCooldown -= dt;
    }

    // Update hearts
    for (final heart in _hearts) {
      heart.update(dt);
    }
    _hearts.removeWhere((h) => h.isDone);

    // Handle waypoint movement
    if (waypoints.isNotEmpty) {
      _updateMovement(dt);
    }
  }

  void _updateMovement(double dt) {
    // Handle pause at waypoints
    if (_pauseTimer > 0) {
      _pauseTimer -= dt;
      _isMoving = false;
      _updateAnimation();
      return;
    }

    final targetWaypoint = waypoints[_currentWaypointIndex];
    final deltaX = targetWaypoint.x - position.x;
    final deltaY = targetWaypoint.y - position.y;

    // Check if we've reached the waypoint
    if (deltaX.abs() <= _waypointThreshold && deltaY.abs() <= _waypointThreshold) {
      _pauseTimer = waypointPauseDuration;
      _advanceWaypoint();
      return;
    }

    // Cardinal movement: move in one direction at a time
    // Prioritize the axis with greater distance, and stick to it until aligned
    _isMoving = true;
    Vector2 movement;

    // Determine which axis to move on (stick to current direction if still valid)
    final shouldMoveHorizontal = deltaX.abs() > _waypointThreshold;
    final shouldMoveVertical = deltaY.abs() > _waypointThreshold;

    if (shouldMoveHorizontal && shouldMoveVertical) {
      // Need to move on both axes - check if current direction is still valid
      final currentIsHorizontal = _currentDirection == WalkingDirection.left ||
                                   _currentDirection == WalkingDirection.right;
      final currentIsVertical = _currentDirection == WalkingDirection.up ||
                                 _currentDirection == WalkingDirection.down;

      // Stick to current axis if still valid, otherwise pick the longer axis
      if (currentIsHorizontal && shouldMoveHorizontal) {
        movement = _moveHorizontal(deltaX, dt);
      } else if (currentIsVertical && shouldMoveVertical) {
        movement = _moveVertical(deltaY, dt);
      } else if (deltaX.abs() >= deltaY.abs()) {
        movement = _moveHorizontal(deltaX, dt);
      } else {
        movement = _moveVertical(deltaY, dt);
      }
    } else if (shouldMoveHorizontal) {
      movement = _moveHorizontal(deltaX, dt);
    } else {
      movement = _moveVertical(deltaY, dt);
    }

    position.add(movement);
    _updateAnimation();
  }

  Vector2 _moveHorizontal(double deltaX, double dt) {
    if (deltaX > 0) {
      _currentDirection = WalkingDirection.right;
      return Vector2(walkSpeed * dt, 0);
    } else {
      _currentDirection = WalkingDirection.left;
      return Vector2(-walkSpeed * dt, 0);
    }
  }

  Vector2 _moveVertical(double deltaY, double dt) {
    if (deltaY > 0) {
      _currentDirection = WalkingDirection.down;
      return Vector2(0, walkSpeed * dt);
    } else {
      _currentDirection = WalkingDirection.up;
      return Vector2(0, -walkSpeed * dt);
    }
  }

  void _advanceWaypoint() {
    if (loopWaypoints) {
      // Loop: go to next, wrap around
      _currentWaypointIndex = (_currentWaypointIndex + 1) % waypoints.length;
    } else {
      // Ping-pong: reverse at ends
      _currentWaypointIndex += _waypointDirection;
      if (_currentWaypointIndex >= waypoints.length) {
        _currentWaypointIndex = waypoints.length - 2;
        _waypointDirection = -1;
      } else if (_currentWaypointIndex < 0) {
        _currentWaypointIndex = 1;
        _waypointDirection = 1;
      }
    }
  }

  void _updateAnimation() {
    if (_isMoving) {
      animation = _walkAnimations[_currentDirection]!;
    } else {
      animation = _idleAnimation;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Render interaction hearts
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final heart in _hearts) {
      if (heart.delay > 0) continue;

      textPainter.text = TextSpan(
        text: heart.symbol,
        style: TextStyle(
          fontSize: 16 + heart.scale * 10,
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
    }
  }

  void _onInteract() {
    debugPrint('Interacting with $name!');
    _interactionCooldown = 1.5;
    _spawnInteractionHearts();

    if (interactionMessage != null) {
      debugPrint(interactionMessage!);
    }
  }

  void _spawnInteractionHearts() {
    final random = Random();
    final count = 3 + random.nextInt(3);
    for (var i = 0; i < count; i++) {
      _hearts.add(_InteractionHeart(
        startX: size.x * 0.3 + random.nextDouble() * size.x * 0.4,
        startY: size.y * 0.3,
        delay: i * 0.1,
      ));
    }
  }
}

/// Floating heart animation for interactions
class _InteractionHeart {
  double x;
  double y;
  double alpha = 1.0;
  double scale = 0.0;
  double lifetime = 0;
  double delay;
  static const double maxLifetime = 1.5;

  late final String symbol;
  late final Color color;

  _InteractionHeart({
    required double startX,
    required double startY,
    this.delay = 0,
  })  : x = startX,
        y = startY {
    final random = Random();
    symbol = ['❤', '💕', '✨', '💗'][random.nextInt(4)];
    color = [Colors.pink, Colors.red, Colors.amber, Colors.pinkAccent][random.nextInt(4)];
  }

  void update(double dt) {
    if (delay > 0) {
      delay -= dt;
      return;
    }

    lifetime += dt;
    final progress = lifetime / maxLifetime;

    x += dt * 5 * sin(lifetime * 8);
    y -= dt * 40;

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

/// Data class for defining walking characters in maps
class WalkingCharacterData {
  final double x;
  final double y;
  final String name;
  final String spritePath;
  final List<List<double>> waypoints; // [[x1, y1], [x2, y2], ...]
  final int columns;
  final int rows;
  final double displaySize;
  final double animationSpeed;
  final double scale;
  final double scaleX; // X scale relative to scale (1.0 = same width, 0.9 = 10% narrower)
  final double walkSpeed;
  final bool loopWaypoints;
  final double collisionRadius;
  final String? interactionMessage;
  final double waypointPauseDuration;

  const WalkingCharacterData({
    required this.x,
    required this.y,
    required this.name,
    required this.spritePath,
    required this.waypoints,
    this.columns = 4,
    this.rows = 4,
    this.displaySize = 100.0,
    this.animationSpeed = 0.15,
    this.scale = 1.0,
    this.scaleX = 1.0,
    this.walkSpeed = 60.0,
    this.loopWaypoints = false,
    this.collisionRadius = 0.0,
    this.interactionMessage,
    this.waypointPauseDuration = 1.0,
  });

  WalkingCharacter toWalkingCharacter({bool showDebug = false}) {
    return WalkingCharacter(
      position: Vector2(x, y),
      name: name,
      spritePath: spritePath,
      waypoints: waypoints.map((wp) => Vector2(wp[0], wp[1])).toList(),
      columns: columns,
      rows: rows,
      displaySize: displaySize,
      animationSpeed: animationSpeed,
      baseScale: scale,
      scaleX: scaleX,
      walkSpeed: walkSpeed,
      loopWaypoints: loopWaypoints,
      collisionRadius: collisionRadius,
      interactionMessage: interactionMessage,
      waypointPauseDuration: waypointPauseDuration,
      showDebug: showDebug,
    );
  }
}
