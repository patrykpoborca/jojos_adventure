import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/foundation.dart';

import '../memory_lane_game.dart';
import '../world/obstacle.dart';
import '../world/pet.dart';

/// Direction the baby is facing
enum BabyDirection { down, up, left, right }

/// Movement mode - crawling initially, walking after all memories collected
enum MovementMode { crawling, walking }

/// The player-controlled baby avatar with sprite animations
class BabyPlayer extends SpriteAnimationComponent
    with HasGameReference<MemoryLaneGame>, CollisionCallbacks {
  final JoystickComponent joystick;

  /// Whether we're currently colliding
  bool _isColliding = false;

  /// Whether we were colliding last frame (for detecting collision start)
  bool _wasColliding = false;

  /// Accumulated collision direction (normalized)
  Vector2 _collisionDirection = Vector2.zero();

  /// Position where collision started (for camera freeze)
  Vector2? _collisionStartPos;

  /// Frozen camera position during collision recovery
  Vector2? _frozenCameraPos;

  /// Distance threshold to resume camera movement after collision
  static const double _cameraResumeThreshold = 20.0;

  /// Smooth camera target for gradual unfreezing
  Vector2 _smoothCameraTarget = Vector2.zero();

  /// Whether the camera target has been initialized
  bool _cameraTargetInitialized = false;

  /// Movement speed in pixels per second (base values for main floor)
  static const double _baseCrawlSpeed = 60;
  static const double _baseWalkSpeed = 180;

  /// Upstairs scale multiplier (matches player scale difference)
  static const double _upstairsMultiplier = 2.0;

  /// Sprite frame configuration
  static const int frameColumns = 4;
  static const int frameRows = 5;
  static const double animationStepTime = 0.15;

  /// Display size for the baby sprite
  static const double displaySize = 64 * 2;

  // Animation maps for each movement mode
  late final Map<BabyDirection, SpriteAnimation> _crawlAnimations;
  late final Map<BabyDirection, SpriteAnimation> _walkAnimations;
  late final SpriteAnimation _crawlIdle;
  late final SpriteAnimation _walkIdle;

  // Current state
  MovementMode _movementMode = MovementMode.crawling;
  BabyDirection _currentDirection = BabyDirection.down;
  bool _isMoving = false;

  BabyPlayer({required this.joystick})
      : super(
          size: Vector2.all(displaySize),
          anchor: Anchor.center,
          priority: 100, // Render on top of map elements
        );

  /// Current movement speed based on mode and level
  double get speed {
    final baseSpeed = _movementMode == MovementMode.crawling
        ? _baseCrawlSpeed
        : _baseWalkSpeed;
    final levelMultiplier = game.currentLevel == LevelId.upstairsNursery
        ? _upstairsMultiplier
        : 1.0;
    return baseSpeed * 3 * levelMultiplier;
  }

  /// Current movement mode
  MovementMode get movementMode => _movementMode;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Start position (inside the house, left side)
    position = Vector2(150, 300);

    // Load sprite animations
    await _loadAnimations();

    // Set initial animation
    animation = _crawlIdle;

    // Add hitbox for collision detection (smaller than sprite for better feel)
    add(CircleHitbox(
      radius: displaySize * 0.3,
      position: Vector2(displaySize / 2, displaySize * 0.6),
      anchor: Anchor.center,
      collisionType: CollisionType.active,
    ));
  }

  Future<void> _loadAnimations() async {
    // Load crawling sprite sheet
    final crawlImage = await game.images.load('sprites/crawling_sprite.png');
    final crawlSheet = SpriteSheet(
      image: crawlImage,
      srcSize: Vector2(
        crawlImage.width / frameColumns,
        crawlImage.height / frameRows,
      ),
    );

    // Load walking sprite sheet
    final walkImage = await game.images.load('sprites/walking_sprite.png');
    final walkSheet = SpriteSheet(
      image: walkImage,
      srcSize: Vector2(
        walkImage.width / frameColumns,
        walkImage.height / frameRows,
      ),
    );

    // Create crawling animations for each direction
    _crawlAnimations = {
      BabyDirection.down: crawlSheet.createAnimation(
        row: 0,
        stepTime: animationStepTime,
        to: frameColumns,
      ),
      BabyDirection.up: crawlSheet.createAnimation(
        row: 1,
        stepTime: animationStepTime,
        to: frameColumns,
      ),
      BabyDirection.left: crawlSheet.createAnimation(
        row: 2,
        stepTime: animationStepTime,
        to: frameColumns,
      ),
      BabyDirection.right: crawlSheet.createAnimation(
        row: 3,
        stepTime: animationStepTime,
        to: frameColumns,
      ),
    };

    // Crawl idle (row 5, single frame)
    _crawlIdle = crawlSheet.createAnimation(
      row: 4,
      stepTime: 1.0, // Doesn't matter for single frame
      to: 1,
    );

    // Create walking animations for each direction
    _walkAnimations = {
      BabyDirection.down: walkSheet.createAnimation(
        row: 0,
        stepTime: animationStepTime,
        to: frameColumns,
      ),
      BabyDirection.up: walkSheet.createAnimation(
        row: 1,
        stepTime: animationStepTime,
        to: frameColumns,
      ),
      BabyDirection.left: walkSheet.createAnimation(
        row: 2,
        stepTime: animationStepTime,
        to: frameColumns,
      ),
      BabyDirection.right: walkSheet.createAnimation(
        row: 3,
        stepTime: animationStepTime,
        to: frameColumns,
      ),
    };

    // Walk idle (row 5, single frame)
    _walkIdle = walkSheet.createAnimation(
      row: 4,
      stepTime: 1.0,
      to: 1,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Initialize camera target on first update
    if (!_cameraTargetInitialized) {
      _smoothCameraTarget = position.clone();
      _cameraTargetInitialized = true;
    }

    final wasMoving = _isMoving;
    final previousDirection = _currentDirection;

    // Check if joystick is active
    if (!joystick.delta.isZero()) {
      _isMoving = true;

      // Calculate intended movement
      var delta = joystick.relativeDelta * speed * dt;

      // If colliding, allow sliding along obstacles
      if (_isColliding && !_collisionDirection.isZero()) {
        // Project movement onto the surface tangent (perpendicular to collision normal)
        final tangent = Vector2(-_collisionDirection.y, _collisionDirection.x);
        final slideAmount = delta.dot(tangent);
        delta = tangent * slideAmount;
      }

      position.add(delta);

      // Determine direction based on joystick angle
      _currentDirection = _getDirectionFromJoystick();

      // Clamp position to house bounds
      _clampToHouseBounds();
    } else {
      _isMoving = false;
    }

    // Handle camera freeze on collision
    _updateCameraTarget();

    // Track collision state for next frame
    _wasColliding = _isColliding;

    // Reset collision state (will be set again by onCollision if still colliding)
    _isColliding = false;
    _collisionDirection = Vector2.zero();

    // Update animation if state changed
    if (_isMoving != wasMoving || _currentDirection != previousDirection) {
      _updateAnimation();
    }
  }

  /// Updates the smooth camera target based on collision state
  void _updateCameraTarget() {
    // Detect collision start
    if (_isColliding && !_wasColliding) {
      // Just started colliding - freeze camera
      _collisionStartPos = position.clone();
      _frozenCameraPos = _smoothCameraTarget.clone();
    }

    // Check if we should unfreeze
    if (_frozenCameraPos != null && _collisionStartPos != null) {
      final distanceFromCollision = position.distanceTo(_collisionStartPos!);

      if (distanceFromCollision > _cameraResumeThreshold || !_isColliding) {
        // Moved far enough or no longer colliding - unfreeze
        _frozenCameraPos = null;
        _collisionStartPos = null;
      }
    }

    // Update smooth camera target
    if (_frozenCameraPos != null) {
      // Camera is frozen - keep target at frozen position
      _smoothCameraTarget = _frozenCameraPos!.clone();
    } else {
      // Smoothly interpolate towards player position
      final lerpFactor = 0.15;
      _smoothCameraTarget.x += (position.x - _smoothCameraTarget.x) * lerpFactor;
      _smoothCameraTarget.y += (position.y - _smoothCameraTarget.y) * lerpFactor;
    }
  }

  /// Get the camera target position (may be frozen during collision)
  Vector2 get cameraTarget => _smoothCameraTarget;

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Skip collision with non-obstacle components (memories, etc.)
    // Check if other is Obstacle, Pet, or has Pet/Obstacle as parent
    final isObstacle = other is Obstacle || other.parent is Obstacle;
    final isPet = other is Pet || other.parent is Pet;

    // Debug: log all collisions
    // debugPrint('Collision with: ${other.runtimeType}, parent: ${other.parent?.runtimeType}, isObstacle: $isObstacle, isPet: $isPet');

    if (!isObstacle && !isPet) return;

    _isColliding = true;

    // Calculate push-back direction from collision
    if (intersectionPoints.isNotEmpty) {
      // Find center of intersection
      final intersectionCenter = intersectionPoints.reduce((a, b) => a + b) /
          intersectionPoints.length.toDouble();

      // Push away from intersection point
      final pushDirection = position - intersectionCenter;
      if (pushDirection.length > 0) {
        pushDirection.normalize();
        _collisionDirection = pushDirection.clone();

        // Push player out of the obstacle
        position.add(pushDirection * 2.0);
      }
    }
  }

  /// Determines the cardinal direction from joystick input
  BabyDirection _getDirectionFromJoystick() {
    final angle = atan2(joystick.delta.y, joystick.delta.x);
    final degrees = angle * 180 / pi;

    // Convert angle to cardinal direction
    // Right: -45 to 45
    // Down: 45 to 135
    // Left: 135 to 180 or -180 to -135
    // Up: -135 to -45
    if (degrees >= -45 && degrees < 45) {
      return BabyDirection.right;
    } else if (degrees >= 45 && degrees < 135) {
      return BabyDirection.down;
    } else if (degrees >= -135 && degrees < -45) {
      return BabyDirection.up;
    } else {
      return BabyDirection.left;
    }
  }

  /// Offset to apply when facing south (down) to fix sprite alignment
  static const double _southFacingOffset = 50.0;
  double _currentYOffset = 0.0;

  /// Updates the current animation based on state
  void _updateAnimation() {
    // Apply Y offset when facing down to fix floating appearance
    final targetOffset = (_currentDirection == BabyDirection.down && _isMoving)
        ? _southFacingOffset
        : 0.0;
    if (_currentYOffset != targetOffset) {
      position.y += (targetOffset - _currentYOffset);
      _currentYOffset = targetOffset;
    }

    if (_movementMode == MovementMode.crawling) {
      animation = _isMoving
          ? _crawlAnimations[_currentDirection]!
          : _crawlIdle;
    } else {
      animation = _isMoving
          ? _walkAnimations[_currentDirection]!
          : _walkIdle;
    }
  }

  /// Upgrades the baby from crawling to walking
  void upgradeToWalking() {
    if (_movementMode == MovementMode.walking) return;

    _movementMode = MovementMode.walking;
    _updateAnimation();
  }

  /// Switch to walking mode (async version for game phase transition)
  Future<void> switchToWalking() async {
    upgradeToWalking();
  }

  /// Resets to crawling mode (if needed)
  void resetToCrawling() {
    _movementMode = MovementMode.crawling;
    _updateAnimation();
  }

  /// Keeps the player within the current map boundaries
  void _clampToHouseBounds() {
    final bounds = game.currentPlayableBounds;
    final halfSize = displaySize / 2;

    position.x = position.x.clamp(
      bounds.left + halfSize,
      bounds.right - halfSize,
    );
    position.y = position.y.clamp(
      bounds.top + halfSize,
      bounds.bottom - halfSize,
    );
  }
}
