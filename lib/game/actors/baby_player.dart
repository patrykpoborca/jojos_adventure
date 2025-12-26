import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' show Colors;

import '../input/floating_joystick.dart';
import '../memory_lane_game.dart';
import '../world/obstacle.dart';
import '../world/character.dart' show Character, DebugCircleComponent;
import '../world/walking_character.dart';

/// Direction the baby is facing
enum BabyDirection { down, up, left, right }

/// Movement mode - crawling initially, walking after all memories collected
enum MovementMode { crawling, walking }

/// The player-controlled baby avatar with sprite animations
class BabyPlayer extends SpriteAnimationComponent
    with HasGameReference<MemoryLaneGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  final FloatingJoystick floatingJoystick;

  /// Whether collision is enabled (can be toggled for debug)
  bool collisionEnabled = true;

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
  static const double _baseWalkSpeed = 75; // 180 reduced by 40%

  /// Upstairs scale multiplier (matches player scale difference)
  static const double _upstairsMultiplier = 2.0;

  /// Sprite frame configuration
  static const int frameColumns = 4;
  static const int frameRows = 5;
  static const double animationStepTime = 0.15;

  /// Display size for the baby sprite
  static const double displaySize = 64 * 2;

  /// Collision hitbox offset for crawling mode (positive = right/down)
  static const double crawlCollisionOffsetX = 0.0;
  static const double crawlCollisionOffsetY = 0.0;

  /// Collision hitbox offset for walking mode (positive = right/down)
  static const double walkCollisionOffsetX = -20.0;
  static const double walkCollisionOffsetY = 0.0;

  /// Walking sprite aspect ratio (calculated in onLoad)
  double _walkingAspectRatio = 1.0;

  // Animation maps for each movement mode
  late final Map<BabyDirection, SpriteAnimation> _crawlAnimations;
  late final Map<BabyDirection, SpriteAnimation> _walkAnimations;
  late final SpriteAnimation _crawlIdle;
  late final SpriteAnimation _walkIdle;

  // Current state
  MovementMode _movementMode = MovementMode.crawling;
  BabyDirection _currentDirection = BabyDirection.down;
  BabyDirection _previousDirection = BabyDirection.down;
  bool _isMoving = false;

  /// References to hitbox components for position updates
  CircleHitbox? _hitbox;
  DebugCircleComponent? _debugHitbox;

  /// Keyboard input direction (set from main.dart key handlers)
  Vector2 keyboardDirection = Vector2.zero();

  /// Current sprite tilt angle (radians) for diagonal movement
  double _currentTilt = 0.0;

  /// Deadzone angle (degrees) - no tilt within this range of cardinal directions
  static const double _tiltDeadzone = 7.0;

  /// Maximum tilt angle (degrees) for diagonal movement
  static const double _maxTiltDegrees = 15.0;

  /// Tilt interpolation speed (higher = faster response)
  static const double _tiltLerpSpeed = 12.0;

  BabyPlayer({required this.joystick, required this.floatingJoystick})
      : super(
          size: Vector2.all(displaySize), // Square for crawling
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
    final hitboxRadius = displaySize * 0.3;
    final hitboxPosition = Vector2(
      displaySize / 2 + crawlCollisionOffsetX,
      displaySize * 0.6 + crawlCollisionOffsetY,
    );
    _hitbox = CircleHitbox(
      radius: hitboxRadius,
      position: hitboxPosition,
      anchor: Anchor.center,
      collisionType: CollisionType.active,
    );
    add(_hitbox!);

    // Debug visualization for player hitbox (only visible when debug panel is open)
    _debugHitbox = DebugCircleComponent(
      radius: hitboxRadius,
      position: hitboxPosition,
      anchor: Anchor.center,
      color: Colors.green,
      filled: true,
    );
    add(_debugHitbox!);
  }

  /// Updates hitbox position based on current movement mode
  void _updateHitboxPosition() {
    final offsetX = _movementMode == MovementMode.crawling
        ? crawlCollisionOffsetX
        : walkCollisionOffsetX;
    final offsetY = _movementMode == MovementMode.crawling
        ? crawlCollisionOffsetY
        : walkCollisionOffsetY;

    final newPosition = Vector2(
      displaySize / 2 + offsetX,
      displaySize * 0.6 + offsetY,
    );

    _hitbox?.position = newPosition;
    _debugHitbox?.position = newPosition;
  }

  Future<void> _loadAnimations() async {
    // Load crawling sprite sheet
    final crawlImage = await game.images.load('sprites/crawling_sprite.png');
    final crawlFrameWidth = crawlImage.width / frameColumns;
    final crawlFrameHeight = crawlImage.height / frameRows;
    final crawlSheet = SpriteSheet(
      image: crawlImage,
      srcSize: Vector2(crawlFrameWidth, crawlFrameHeight),
    );

    // Load walking sprite sheet
    final walkImage = await game.images.load('sprites/walking_sprite.png');
    final walkFrameWidth = walkImage.width / frameColumns;
    final walkFrameHeight = walkImage.height / frameRows;
    final walkSheet = SpriteSheet(
      image: walkImage,
      srcSize: Vector2(walkFrameWidth, walkFrameHeight),
    );

    // Store walking sprite aspect ratio for when we switch to walking
    _walkingAspectRatio = walkFrameWidth / walkFrameHeight;

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

    // Combine joystick, floating joystick, and keyboard input
    Vector2 inputDirection = Vector2.zero();

    // Check control mode and use appropriate input source
    if (game.controlMode == MovementControlMode.joystick) {
      // Fixed joystick mode
      if (!joystick.delta.isZero()) {
        inputDirection = joystick.relativeDelta.clone();
      }
    } else {
      // Positional/floating joystick mode
      if (!floatingJoystick.relativeDelta.isZero()) {
        inputDirection = floatingJoystick.relativeDelta.clone();
      }
    }

    // Keyboard input works in both modes as fallback
    if (inputDirection.isZero() && !keyboardDirection.isZero()) {
      inputDirection = keyboardDirection.normalized();
    }

    // Check if there's any input
    if (!inputDirection.isZero()) {
      _isMoving = true;

      // Calculate intended movement
      var delta = inputDirection * speed * dt;

      // If colliding, allow sliding along obstacles
      if (_isColliding && !_collisionDirection.isZero()) {
        // Project movement onto the surface tangent (perpendicular to collision normal)
        final tangent = Vector2(-_collisionDirection.y, _collisionDirection.x);
        final slideAmount = delta.dot(tangent);
        delta = tangent * slideAmount;
      }

      position.add(delta);

      // Determine direction based on input (track previous for smooth tilt transition)
      final newDirection = _getDirectionFromInput(inputDirection);
      if (newDirection != _currentDirection) {
        _previousDirection = _currentDirection;
        _currentDirection = newDirection;
        // Adjust tilt to compensate for direction change
        _compensateTiltForDirectionChange(inputDirection);
      }

      // Calculate and apply diagonal tilt
      _updateTilt(inputDirection, dt);

      // Clamp position to house bounds
      _clampToHouseBounds();
    } else {
      _isMoving = false;
      // Smoothly return to no tilt when stopped
      _updateTilt(Vector2.zero(), dt);
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

    // Skip all collision handling if disabled (debug mode)
    if (!collisionEnabled) return;

    // Skip collision with non-obstacle components (memories, etc.)
    // Check if other is Obstacle or has Obstacle as parent
    final isObstacle = other is Obstacle || other.parent is Obstacle;

    // For Character, check if collision is enabled (has collisionRadius > 0)
    bool isCharacterWithCollision = false;
    if (other is Character) {
      isCharacterWithCollision = other.hasCollision;
    } else if (other.parent is Character) {
      isCharacterWithCollision = (other.parent as Character).hasCollision;
    }

    // For WalkingCharacter, also check if collision is enabled
    bool isWalkingCharacterWithCollision = false;
    if (other is WalkingCharacter) {
      isWalkingCharacterWithCollision = other.hasCollision;
    } else if (other.parent is WalkingCharacter) {
      isWalkingCharacterWithCollision = (other.parent as WalkingCharacter).hasCollision;
    }

    if (!isObstacle && !isCharacterWithCollision && !isWalkingCharacterWithCollision) return;

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

  /// Determines the cardinal direction from input vector
  BabyDirection _getDirectionFromInput(Vector2 input) {
    final angle = atan2(input.y, input.x);
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

  /// Gets the cardinal angle in degrees for a direction
  double _getCardinalAngle(BabyDirection direction, double inputAngle) {
    switch (direction) {
      case BabyDirection.right:
        return 0.0;
      case BabyDirection.down:
        return 90.0;
      case BabyDirection.left:
        // Handle wrap-around: left is at 180 or -180
        return inputAngle > 0 ? 180.0 : -180.0;
      case BabyDirection.up:
        return -90.0;
    }
  }

  /// Compensates the current tilt when direction changes to avoid snapping
  void _compensateTiltForDirectionChange(Vector2 input) {
    if (input.isZero()) return;

    final inputAngle = atan2(input.y, input.x) * 180 / pi;

    // Calculate what visual angle we had with the previous direction + tilt
    final previousCardinal = _getCardinalAngle(_previousDirection, inputAngle);
    final previousVisualAngle = previousCardinal + (_currentTilt * 180 / pi);

    // Calculate what tilt we need for the new direction to maintain that visual angle
    final newCardinal = _getCardinalAngle(_currentDirection, inputAngle);
    var compensatedTilt = previousVisualAngle - newCardinal;

    // Normalize to -180 to 180 range
    while (compensatedTilt > 180) {
      compensatedTilt -= 360;
    }
    while (compensatedTilt < -180) {
      compensatedTilt += 360;
    }

    // Clamp to reasonable tilt range and convert to radians
    final maxTiltRad = _maxTiltDegrees * pi / 180;
    _currentTilt = compensatedTilt.clamp(-_maxTiltDegrees * 2, _maxTiltDegrees * 2) * pi / 180;
    _currentTilt = _currentTilt.clamp(-maxTiltRad * 1.5, maxTiltRad * 1.5);
  }

  /// Updates the sprite tilt for diagonal movement
  void _updateTilt(Vector2 input, double dt) {
    double targetTilt = 0.0;

    if (!input.isZero()) {
      final inputAngle = atan2(input.y, input.x) * 180 / pi;

      // Get the center angle for the current cardinal direction
      final cardinalAngle = _getCardinalAngle(_currentDirection, inputAngle);

      // Calculate offset from cardinal direction
      double offset = inputAngle - cardinalAngle;

      // Normalize offset to -180 to 180 range
      while (offset > 180) {
        offset -= 360;
      }
      while (offset < -180) {
        offset += 360;
      }

      // Apply deadzone - no tilt within deadzone
      if (offset.abs() <= _tiltDeadzone) {
        targetTilt = 0.0;
      } else {
        // Calculate tilt amount beyond deadzone
        // Max offset from cardinal is 45 degrees (halfway to next cardinal)
        final effectiveOffset = offset.abs() - _tiltDeadzone;
        final maxEffectiveOffset = 45.0 - _tiltDeadzone;
        final tiltRatio = (effectiveOffset / maxEffectiveOffset).clamp(0.0, 1.0);

        // Apply tilt in the direction of the offset
        targetTilt = tiltRatio * _maxTiltDegrees * (offset > 0 ? 1 : -1);

        // Convert to radians
        targetTilt = targetTilt * pi / 180;
      }
    }

    // Smoothly interpolate to target tilt
    final lerpFactor = (_tiltLerpSpeed * dt).clamp(0.0, 1.0);
    _currentTilt += (targetTilt - _currentTilt) * lerpFactor;

    // Apply very small values as zero to prevent jitter
    if (_currentTilt.abs() < 0.001) {
      _currentTilt = 0.0;
    }

    // Apply tilt to sprite rotation
    angle = _currentTilt;
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

    // Apply proper aspect ratio for walking sprite
    size = Vector2(displaySize * _walkingAspectRatio, displaySize);

    // Update hitbox position for walking mode
    _updateHitboxPosition();

    _updateAnimation();
  }

  /// Switch to walking mode (async version for game phase transition)
  Future<void> switchToWalking() async {
    upgradeToWalking();
  }

  /// Resets to crawling mode (if needed)
  void resetToCrawling() {
    _movementMode = MovementMode.crawling;

    // Restore square size for crawling
    size = Vector2.all(displaySize);

    // Update hitbox position for crawling mode
    _updateHitboxPosition();

    _updateAnimation();
  }

  /// Keeps the player within the current map boundaries
  void _clampToHouseBounds() {
    final bounds = game.currentPlayableBounds;
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;

    position.x = position.x.clamp(
      bounds.left + halfWidth,
      bounds.right - halfWidth,
    );
    position.y = position.y.clamp(
      bounds.top + halfHeight,
      bounds.bottom - halfHeight,
    );
  }
}
