import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../memory_lane_game.dart';

/// Direction the baby is facing
enum BabyDirection { down, up, left, right }

/// Movement mode - crawling initially, walking after all memories collected
enum MovementMode { crawling, walking }

/// The player-controlled baby avatar with sprite animations
class BabyPlayer extends SpriteAnimationComponent
    with HasGameReference<MemoryLaneGame> {
  final JoystickComponent joystick;

  /// Movement speed in pixels per second
  static const double crawlSpeed = 100;
  static const double walkSpeed = 150;

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
        );

  /// Current movement speed based on mode
  double get speed =>
      (_movementMode == MovementMode.crawling ? crawlSpeed : walkSpeed) * 3;

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

    final wasMoving = _isMoving;
    final previousDirection = _currentDirection;

    // Check if joystick is active
    if (!joystick.delta.isZero()) {
      _isMoving = true;

      // Calculate movement
      final delta = joystick.relativeDelta * speed * dt;
      position.add(delta);

      // Determine direction based on joystick angle
      _currentDirection = _getDirectionFromJoystick();

      // Clamp position to house bounds
      _clampToHouseBounds();
    } else {
      _isMoving = false;
    }

    // Update animation if state changed
    if (_isMoving != wasMoving || _currentDirection != previousDirection) {
      _updateAnimation();
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

  /// Updates the current animation based on state
  void _updateAnimation() {
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

  /// Resets to crawling mode (if needed)
  void resetToCrawling() {
    _movementMode = MovementMode.crawling;
    _updateAnimation();
  }

  /// Keeps the player within the house boundaries
  void _clampToHouseBounds() {
    final houseMap = game.houseMap;
    final bounds = houseMap.playableBounds;
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
