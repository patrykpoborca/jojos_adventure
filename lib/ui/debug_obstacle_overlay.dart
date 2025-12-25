import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../game/memory_lane_game.dart' show DebugPlacementMode, GameState, MemoryLaneGame;

/// Debug overlay for obstacle placement mode
class DebugObstacleOverlay extends StatefulWidget {
  final MemoryLaneGame game;

  const DebugObstacleOverlay({super.key, required this.game});

  @override
  State<DebugObstacleOverlay> createState() => _DebugObstacleOverlayState();
}

class _DebugObstacleOverlayState extends State<DebugObstacleOverlay> {
  final TextEditingController _nameController = TextEditingController();
  String _statusMessage = 'Press SPACE to mark first corner';
  Vector2 _currentPosition = Vector2.zero();
  DebugPlacementMode _currentMode = DebugPlacementMode.obstacle;

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Obstacle';
    _currentMode = widget.game.placementMode;

    // Connect callbacks to game
    widget.game.onDebugMessage = (message) {
      if (mounted) {
        setState(() {
          _statusMessage = message;
        });
      }
    };

    widget.game.getObstacleName = () => _nameController.text;

    widget.game.onModeChanged = (mode) {
      if (mounted) {
        setState(() {
          _currentMode = mode;
          _nameController.text = mode == DebugPlacementMode.obstacle
              ? 'Obstacle'
              : 'Memory';
        });
      }
    };

    // Update position periodically
    _updatePosition();
  }

  void _updatePosition() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        // Only update if game is loaded and player exists
        if (widget.game.state != GameState.loading) {
          setState(() {
            _currentPosition = widget.game.player.position;
          });
        }
        _updatePosition();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    widget.game.onDebugMessage = null;
    widget.game.getObstacleName = null;
    widget.game.onModeChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with mode indicator
            Row(
              children: [
                Icon(
                  _currentMode == DebugPlacementMode.obstacle
                      ? Icons.crop_square
                      : Icons.photo_camera,
                  color: _currentMode == DebugPlacementMode.obstacle
                      ? Colors.amber
                      : Colors.lightBlueAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentMode == DebugPlacementMode.obstacle
                      ? 'OBSTACLE MODE'
                      : 'MEMORY MODE',
                  style: TextStyle(
                    color: _currentMode == DebugPlacementMode.obstacle
                        ? Colors.amber
                        : Colors.lightBlueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.amber),

            // Current position
            Text(
              'Position: (${_currentPosition.x.toInt()}, ${_currentPosition.y.toInt()})',
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Obstacle name input
            Row(
              children: [
                const Text(
                  'Name: ',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Enter obstacle name',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Colors.amber),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Colors.amber),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: Colors.amber, width: 2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap game area after typing to re-enable SPACE key',
              style: TextStyle(
                color: Colors.amber.withValues(alpha: 0.7),
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),

            // Status message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue),
              ),
              child: Text(
                _statusMessage,
                style: const TextStyle(
                  color: Colors.lightBlueAccent,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Instructions (tappable for touch devices)
            const Text(
              'Controls (tap to activate):',
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            _ControlRow(
              key_: 'M',
              action: 'Toggle mode',
              onTap: () => widget.game.togglePlacementMode(),
            ),
            _ControlRow(
              key_: 'SPACE',
              action: _currentMode == DebugPlacementMode.obstacle
                  ? 'Mark corner / Create'
                  : 'Place memory',
              onTap: () => widget.game.handleObstaclePlacement(),
            ),
            _ControlRow(
              key_: 'C',
              action: 'Cancel placement',
              onTap: () => widget.game.cancelObstaclePlacement(),
            ),
            _ControlRow(
              key_: 'P',
              action: 'Print all to console',
              onTap: () => widget.game.printAllObstacles(),
            ),
            _ControlRow(
              key_: 'L',
              action: 'Switch level',
              onTap: () => widget.game.toggleLevel(),
            ),
            _ControlRow(
              key_: 'G',
              action: 'Toggle phase',
              onTap: () => widget.game.togglePhase(),
            ),
            _ControlRow(
              key_: 'B',
              action: 'Collect all memories',
              onTap: () => widget.game.debugCollectAllMemories(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  final String key_;
  final String action;
  final VoidCallback? onTap;

  const _ControlRow({
    required this.key_,
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: onTap != null
                      ? Colors.amber.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                  border: onTap != null
                      ? Border.all(color: Colors.amber.withValues(alpha: 0.5))
                      : null,
                ),
                child: Text(
                  key_,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.touch_app,
                  color: Colors.amber.withValues(alpha: 0.5),
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
