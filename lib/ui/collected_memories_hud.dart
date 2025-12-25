import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/memory_lane_game.dart';
import '../game/world/memory_item.dart';

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
  }

  @override
  void dispose() {
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
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
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
                padding: const EdgeInsets.only(right: 8),
                child: _AnimatedMemorySprite(
                  spriteTypeIndex: entry.key,
                ),
              );
            }),
            // Collected/Total counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$collected/$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
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
    // Static first frame with glow
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: _spriteSheet != null
            ? CustomPaint(
                size: const Size(32, 32),
                painter: _SpriteFramePainter(
                  spriteSheet: _spriteSheet!,
                  frameIndex: 0, // Always first frame
                  columns: _spriteType.columns,
                  rows: _spriteType.rows,
                ),
              )
            : Container(
                color: Colors.amber.withValues(alpha: 0.2),
                child: const Icon(
                  Icons.photo_album,
                  color: Colors.amber,
                  size: 16,
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
