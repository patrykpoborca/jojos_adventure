import 'package:flame/components.dart';
import 'package:flame/events.dart';

import '../audio/audio_manager.dart';
import '../memory_lane_game.dart';

/// A virtual joystick that calculates direction based on touch position
/// relative to the baby's position in world space (no visible joystick).
///
/// Since this component is added to the world, localPosition in drag events
/// is already in world coordinates after Flame's camera transformation.
class FloatingJoystick extends PositionComponent
    with HasGameReference<MemoryLaneGame>, DragCallbacks {
  /// Current drag direction (normalized, -1 to 1 range like JoystickComponent)
  Vector2 _relativeDelta = Vector2.zero();

  /// Whether currently touching
  bool _isTouching = false;

  /// Current touch position in world coordinates
  Vector2 _touchWorldPosition = Vector2.zero();

  /// Maximum distance for full speed (in world units)
  static const double _maxDistance = 200.0;

  /// Dead zone around player (in world units)
  static const double _deadZone = 40.0;

  FloatingJoystick() : super(priority: 1000);

  /// Get the relative delta (same interface as JoystickComponent)
  Vector2 get relativeDelta => _relativeDelta;

  /// Whether currently dragging
  bool get isDragging => _isTouching;

  @override
  bool containsLocalPoint(Vector2 point) {
    // This component covers the entire game area for input
    return true;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);

    // Unlock audio on first user interaction (required for web)
    AudioManager().unlockAudio();

    // Don't capture input if game is not in exploring state
    if (game.state != GameState.exploring) return;

    // Don't capture if control mode is joystick
    if (game.controlMode != MovementControlMode.positional) return;

    _isTouching = true;
    // localPosition is already in world coordinates for world components
    _touchWorldPosition = event.localPosition.clone();
    _updateDelta();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    if (!_isTouching) return;

    // Update touch position: start position + accumulated delta
    // Both are in world coordinates for world components
    _touchWorldPosition = event.localStartPosition + event.localDelta;
    _updateDelta();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _reset();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _reset();
  }

  void _updateDelta() {
    if (!_isTouching) {
      _relativeDelta = Vector2.zero();
      return;
    }

    // Get player's world position
    final playerPos = game.player.position;

    // Calculate direction from player to touch position (both in world coords)
    final delta = _touchWorldPosition - playerPos;
    final distance = delta.length;

    if (distance < _deadZone) {
      // Dead zone to prevent jitter when touching near the baby
      _relativeDelta = Vector2.zero();
      return;
    }

    // Normalize and scale based on distance from player
    final effectiveDistance = distance - _deadZone;
    final normalizedDistance = (effectiveDistance / _maxDistance).clamp(0.0, 1.0);
    _relativeDelta = delta.normalized() * normalizedDistance;
  }

  void _reset() {
    _isTouching = false;
    _relativeDelta = Vector2.zero();
  }

  // No render - this joystick is invisible
}
