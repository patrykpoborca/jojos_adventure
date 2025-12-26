import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/memory_lane_game.dart';
import '../game/world/memory_item.dart';
import 'responsive_sizing.dart';

/// HUD overlay showing collected memories in the top left with animated sprites
class CollectedMemoriesHud extends StatefulWidget {
  final MemoryLaneGame game;

  const CollectedMemoriesHud({super.key, required this.game});

  @override
  State<CollectedMemoriesHud> createState() => _CollectedMemoriesHudState();
}

class _CollectedMemoriesHudState extends State<CollectedMemoriesHud> {
  List<CollectedMemoryInfo> _collectedMemories = [];
  int _totalMemories = 0;
  double? _directionToMemory;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _collectedMemories = widget.game.collectedMemories;
    _totalMemories = widget.game.totalMemories;

    widget.game.onMemoriesCollectedChanged = (memories) {
      if (mounted) {
        setState(() {
          _collectedMemories = memories;
          _totalMemories = widget.game.totalMemories;
        });
      }
    };

    // Update direction every 100ms for smooth compass
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted && widget.game.state == GameState.exploring) {
        final newDirection = widget.game.getDirectionToNearestMemory();
        if (newDirection != _directionToMemory) {
          setState(() {
            _directionToMemory = newDirection;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    widget.game.onMemoriesCollectedChanged = null;
    super.dispose();
  }

  /// Group memories by sprite type and count them
  Map<int, int> get _groupedMemories {
    final grouped = <int, int>{};
    for (final memory in _collectedMemories) {
      grouped[memory.spriteTypeIndex] = (grouped[memory.spriteTypeIndex] ?? 0) + 1;
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedMemories;
    final collected = _collectedMemories.length;
    final total = _totalMemories;

    // Always show the counter if there are memories to collect
    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: ResponsiveSizing.spacing(context, 12),
      left: ResponsiveSizing.spacing(context, 12),
      child: Container(
        padding: ResponsiveSizing.paddingAll(context, 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: ResponsiveSizing.borderRadius(context, 8),
          border: Border.all(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Memory sprites grouped by type
            ...grouped.entries.map((entry) {
              return Padding(
                padding: ResponsiveSizing.paddingOnly(context, right: 8),
                child: _AnimatedMemorySprite(
                  spriteTypeIndex: entry.key,
                ),
              );
            }),
            // Collected/Total counter
            Container(
              padding: ResponsiveSizing.paddingSymmetric(
                context,
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: ResponsiveSizing.borderRadius(context, 6),
              ),
              child: Text(
                '$collected/$total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveSizing.fontSize(context, 14),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Navigation arrow pointing to nearest memory
            if (_directionToMemory != null && collected < total)
              Padding(
                padding: ResponsiveSizing.paddingOnly(context, left: 8),
                child: _NavigationArrow(
                  direction: _directionToMemory!,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Animated memory sprite display
class _AnimatedMemorySprite extends StatefulWidget {
  final int spriteTypeIndex;

  const _AnimatedMemorySprite({
    required this.spriteTypeIndex,
  });

  @override
  State<_AnimatedMemorySprite> createState() => _AnimatedMemorySpriteState();
}

class _AnimatedMemorySpriteState extends State<_AnimatedMemorySprite> {
  ui.Image? _spriteSheet;
  late final MemorySpriteType _spriteType;

  @override
  void initState() {
    super.initState();
    _spriteType = MemorySpriteTypes.all[widget.spriteTypeIndex];
    _loadSpriteSheet();
  }

  Future<void> _loadSpriteSheet() async {
    final imageProvider = AssetImage('assets/images/${_spriteType.assetPath}');
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);

    imageStream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _spriteSheet = info.image;
        });
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    final spriteSize = ResponsiveSizing.dimension(context, 32);
    final borderRad = ResponsiveSizing.spacing(context, 6);
    // Static first frame with glow
    return Container(
      width: spriteSize,
      height: spriteSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRad),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: ResponsiveSizing.spacing(context, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRad),
        child: _spriteSheet != null
            ? CustomPaint(
                size: Size(spriteSize, spriteSize),
                painter: _SpriteFramePainter(
                  spriteSheet: _spriteSheet!,
                  frameIndex: 0, // Always first frame
                  columns: _spriteType.columns,
                  rows: _spriteType.rows,
                ),
              )
            : Container(
                color: Colors.amber.withValues(alpha: 0.2),
                child: Icon(
                  Icons.photo_album,
                  color: Colors.amber,
                  size: ResponsiveSizing.iconSize(context, 16),
                ),
              ),
      ),
    );
  }
}

/// Custom painter to draw a single frame from a sprite sheet
class _SpriteFramePainter extends CustomPainter {
  final ui.Image spriteSheet;
  final int frameIndex;
  final int columns;
  final int rows;

  _SpriteFramePainter({
    required this.spriteSheet,
    required this.frameIndex,
    required this.columns,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = spriteSheet.width / columns;
    final frameHeight = spriteSheet.height / rows;

    final col = frameIndex % columns;
    final row = frameIndex ~/ columns;

    final srcRect = Rect.fromLTWH(
      col * frameWidth,
      row * frameHeight,
      frameWidth,
      frameHeight,
    );

    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(spriteSheet, srcRect, dstRect, Paint());
  }

  @override
  bool shouldRepaint(_SpriteFramePainter oldDelegate) {
    return oldDelegate.frameIndex != frameIndex ||
           oldDelegate.spriteSheet != spriteSheet;
  }
}

/// Navigation arrow that points toward the nearest uncollected memory
class _NavigationArrow extends StatelessWidget {
  /// Direction in radians (from screenAngle)
  final double direction;

  const _NavigationArrow({required this.direction});

  @override
  Widget build(BuildContext context) {
    final arrowSize = ResponsiveSizing.dimension(context, 28);
    final iconSize = ResponsiveSizing.iconSize(context, 18);

    return Container(
      width: arrowSize,
      height: arrowSize,
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: ResponsiveSizing.spacing(context, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Transform.rotate(
        // Direction is already 0 = up, positive = clockwise
        // Icons.navigation points up by default, so use directly
        angle: direction,
        child: Icon(
          Icons.navigation,
          color: Colors.amber,
          size: iconSize,
        ),
      ),
    );
  }
}
