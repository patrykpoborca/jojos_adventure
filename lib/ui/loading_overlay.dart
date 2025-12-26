import 'package:flutter/material.dart';

import '../game/memory_lane_game.dart';
import 'responsive_sizing.dart';

/// Loading screen overlay with animated sprite
/// Shows during level transitions and game start
class LoadingOverlay extends StatefulWidget {
  final MemoryLaneGame game;

  const LoadingOverlay({super.key, required this.game});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  /// Sprite sheet configuration (4 columns x 2 rows)
  static const int _columns = 4;
  static const int _rows = 2;
  static const int _totalFrames = _columns * _rows;
  static const double _frameTime = 0.2; // seconds per frame
  static const double _minLoopTime = _totalFrames * _frameTime; // 1.6 seconds

  /// Path to the loading sprite sheet
  static const String _spritePath = 'assets/photos/loading_screen.png';

  late final AnimationController _animController;
  int _currentFrame = 0;
  bool _hasCompletedLoop = false;
  bool _isReadyToHide = false;
  double _elapsedTime = 0;

  @override
  void initState() {
    super.initState();

    // Animation controller for frame timing
    _animController = AnimationController(
      duration: Duration(milliseconds: (_frameTime * 1000).round()),
      vsync: this,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _totalFrames;
          _elapsedTime += _frameTime;

          // Check if we've completed at least one full loop
          if (_elapsedTime >= _minLoopTime) {
            _hasCompletedLoop = true;
          }

          // If loading is done and we've completed a loop, signal ready to hide
          if (_hasCompletedLoop && widget.game.state != GameState.loading) {
            _isReadyToHide = true;
            // Auto-hide after completing the current frame
            Future.delayed(Duration(milliseconds: (_frameTime * 1000).round()), () {
              if (mounted) {
                widget.game.hideLoading();
              }
            });
          }
        });

        // Continue animation if not ready to hide
        if (!_isReadyToHide) {
          _animController.forward(from: 0);
        }
      }
    });

    // Start the animation
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Size the sprite reasonably (not too large)
    final spriteDisplaySize = ResponsiveSizing.dimension(context, 120);

    return Material(
      color: const Color(0xFFFBFADE), // RGB(251	250	222	)
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated sprite
            SizedBox(
              width: spriteDisplaySize,
              height: spriteDisplaySize,
              child: Image.asset(
                _spritePath,
                fit: BoxFit.contain,
                // Use alignment and a clip to show only current frame
                alignment: _getFrameAlignment(),
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to a simple loading indicator if sprite not found
                  return CircularProgressIndicator(
                    color: const Color(0xFFD4A574),
                    strokeWidth: ResponsiveSizing.spacing(context, 3),
                  );
                },
              ),
            ),
            SizedBox(height: ResponsiveSizing.spacing(context, 16)),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: ResponsiveSizing.fontSize(context, 16),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate alignment to show the current frame from the sprite sheet
  Alignment _getFrameAlignment() {
    final col = _currentFrame % _columns;
    final row = _currentFrame ~/ _columns;

    // Convert to alignment (-1 to 1 range)
    // For a 4x2 grid:
    // col 0 = -1, col 1 = -0.33, col 2 = 0.33, col 3 = 1
    // row 0 = -1, row 1 = 1
    final xAlign = _columns > 1 ? (col / (_columns - 1)) * 2 - 1 : 0.0;
    final yAlign = _rows > 1 ? (row / (_rows - 1)) * 2 - 1 : 0.0;

    return Alignment(xAlign, yAlign);
  }
}

/// Alternative implementation using custom painting for precise frame extraction
class LoadingOverlayWithPainter extends StatefulWidget {
  final MemoryLaneGame game;

  const LoadingOverlayWithPainter({super.key, required this.game});

  @override
  State<LoadingOverlayWithPainter> createState() => _LoadingOverlayWithPainterState();
}

class _LoadingOverlayWithPainterState extends State<LoadingOverlayWithPainter>
    with SingleTickerProviderStateMixin {
  static const int _columns = 4;
  static const int _rows = 2;
  static const int _totalFrames = _columns * _rows;
  static const double _frameTime = 0.2;
  static const double _minLoopTime = _totalFrames * _frameTime;
  static const String _spritePath = 'assets/photos/loading_screen.png';

  late final AnimationController _animController;
  int _currentFrame = 0;
  bool _hasCompletedLoop = false;
  bool _isReadyToHide = false;
  double _elapsedTime = 0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: Duration(milliseconds: (_frameTime * 1000).round()),
      vsync: this,
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % _totalFrames;
          _elapsedTime += _frameTime;

          if (_elapsedTime >= _minLoopTime) {
            _hasCompletedLoop = true;
          }

          if (_hasCompletedLoop && widget.game.state != GameState.loading) {
            _isReadyToHide = true;
            Future.delayed(Duration(milliseconds: (_frameTime * 1000).round()), () {
              if (mounted) {
                widget.game.hideLoading();
              }
            });
          }
        });

        if (!_isReadyToHide) {
          _animController.forward(from: 0);
        }
      }
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spriteDisplaySize = ResponsiveSizing.dimension(context, 120);

    return Material(
      color: const Color(0xFFFBFADE), // RGB(251	250	222	)
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Use ClipRect with custom alignment to show single frame
                SizedBox(
                  width: spriteDisplaySize,
                  height: spriteDisplaySize,
                  child: ClipRect(
                    child: OverflowBox(
                      maxWidth: spriteDisplaySize * _columns,
                      maxHeight: spriteDisplaySize * _rows,
                      alignment: _getFrameAlignmentForClip(),
                      child: Image.asset(
                        _spritePath,
                        width: spriteDisplaySize * _columns,
                        height: spriteDisplaySize * _rows,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) {
                          return SizedBox(
                            width: spriteDisplaySize,
                            height: spriteDisplaySize,
                            child: CircularProgressIndicator(
                              color: const Color(0xFFD4A574),
                              strokeWidth: ResponsiveSizing.spacing(context, 3),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveSizing.spacing(context, 16)),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: ResponsiveSizing.fontSize(context, 16),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Darkening scrim over everything (including sprite)
          IgnorePointer(
            child: Container(
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  Alignment _getFrameAlignmentForClip() {
    final col = _currentFrame % _columns;
    final row = _currentFrame ~/ _columns;

    // For clip alignment, we need to offset so the desired frame is centered
    // col 0 needs alignment at left edge, col 3 at right edge
    final xAlign = _columns > 1 ? -1.0 + (col * 2.0 / (_columns - 1)) : 0.0;
    final yAlign = _rows > 1 ? -1.0 + (row * 2.0 / (_rows - 1)) : 0.0;

    return Alignment(-xAlign, -yAlign);
  }
}
