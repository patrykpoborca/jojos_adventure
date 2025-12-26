import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import '../memory_lane_game.dart';

/// A floating joystick that appears wherever the user touches
/// and provides directional input based on drag from touch start point
class FloatingJoystick extends PositionComponent
    with HasGameReference<MemoryLaneGame>, DragCallbacks {
  /// Current drag direction (normalized, -1 to 1 range like JoystickComponent)
  Vector2 _relativeDelta = Vector2.zero();

  /// Touch start position (center of virtual joystick)
  Vector2? _touchStart;

  /// Current touch position
  Vector2? _touchCurrent;

  /// Maximum drag distance for full speed
  static const double _maxDragDistance = 80.0;

  /// Visual feedback radius
  static const double _indicatorRadius = 60.0;
  static const double _knobRadius = 25.0;

  /// Colors matching the fixed joystick
  final Paint _backgroundPaint = Paint()..color = const Color(0x44D4A574);
  final Paint _knobPaint = Paint()..color = const Color(0xAAD4A574);
  final Paint _linePaint = Paint()
    ..color = const Color(0x66D4A574)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  FloatingJoystick() : super(priority: 1000);

  /// Get the relative delta (same interface as JoystickComponent)
  Vector2 get relativeDelta => _relativeDelta;

  /// Whether currently dragging
  bool get isDragging => _touchStart != null;

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

    _touchStart = event.localPosition.clone();
    _touchCurrent = event.localPosition.clone();
    _updateDelta();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);

    if (_touchStart == null) return;

    _touchCurrent = event.localStartPosition + event.localDelta;
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
    if (_touchStart == null || _touchCurrent == null) {
      _relativeDelta = Vector2.zero();
      return;
    }

    final delta = _touchCurrent! - _touchStart!;
    final distance = delta.length;

    if (distance < 5) {
      // Dead zone to prevent jitter
      _relativeDelta = Vector2.zero();
      return;
    }

    // Normalize and scale based on distance
    final normalizedDistance = (distance / _maxDragDistance).clamp(0.0, 1.0);
    _relativeDelta = delta.normalized() * normalizedDistance;
  }

  void _reset() {
    _touchStart = null;
    _touchCurrent = null;
    _relativeDelta = Vector2.zero();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Only render if in positional mode and currently dragging
    if (game.controlMode != MovementControlMode.positional) return;
    if (_touchStart == null) return;

    // Draw background circle at touch start
    canvas.drawCircle(
      Offset(_touchStart!.x, _touchStart!.y),
      _indicatorRadius,
      _backgroundPaint,
    );

    // Draw outline
    canvas.drawCircle(
      Offset(_touchStart!.x, _touchStart!.y),
      _indicatorRadius,
      _linePaint,
    );

    // Draw knob at current position (clamped to max distance)
    if (_touchCurrent != null) {
      final delta = _touchCurrent! - _touchStart!;
      final distance = delta.length;
      final clampedDistance = distance.clamp(0.0, _indicatorRadius);

      Vector2 knobPos;
      if (distance > 0) {
        knobPos = _touchStart! + delta.normalized() * clampedDistance;
      } else {
        knobPos = _touchStart!.clone();
      }

      canvas.drawCircle(
        Offset(knobPos.x, knobPos.y),
        _knobRadius,
        _knobPaint,
      );
    }
  }
}
