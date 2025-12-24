import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:memory_lane/game/memory_lane_game.dart';
import 'package:memory_lane/game/world/memory_item.dart';
import 'package:memory_lane/game/world/obstacle.dart';

/// The upstairs nursery level - a cozy baby room
class UpstairsMap extends PositionComponent with HasGameReference<MemoryLaneGame> {
  late final SpriteComponent backgroundSprite;

  /// The playable area bounds (inside the room)
  Rect get playableBounds => Rect.fromLTWH(
        20,
        20,
        mapSize.x - 40,
        mapSize.y - 40,
      );

  /// Returns the list of obstacle data for furniture and boundaries
  List<ObstacleData> getObstacleData() {
    return const [
      // Room boundaries
      ObstacleData(x: 84, y: 84, width: 1088, height: 714, label: 'northLeftWall'),
      ObstacleData(x: 85, y: 828, width: 349, height: 511, label: 'crib'),
      ObstacleData(x: 84, y: 1261, width: 43, height: 542, label: 'westWall'),
      ObstacleData(x: 84, y: 1780, width: 2072, height: 23, label: 'southWall'),
      ObstacleData(x: 2126, y: 84, width: 29, height: 1720, label: 'westWall'),
      ObstacleData(x: 1034, y: 84, width: 1113, height: 45, label: 'northWall'),
      ObstacleData(x: 1623, y: 84, width: 532, height: 815, label: 'wardrobe'),
      ObstacleData(x: 1104, y: 84, width: 525, height: 656, label: 'exitDoor'),
      ObstacleData(x: 1707, y: 1144, width: 334, height: 418, label: 'rockingChair'),
    ];
  }

  /// Returns the list of memory item data for the nursery
  List<MemoryItemData> getMemoryData() {
    return const [
      // ========================================
      // Phase 1 memories (crawling) - young_ photos
      // ========================================

      // Door memory - returns to main floor (phase 1)
      MemoryItemData(
        x: 1136,
        y: 1297,
        stylizedPhotoPath: 'assets/photos/young_middle_nursery.jpg',
        photos: [
          'assets/photos/young_middle_nursery.jpg'
        ],
        date: 'Date',
        caption: 'Back downstairs...',
        phase: GamePhase.crawling,
      ),
      MemoryItemData(
        x: 1564,
        y: 1327,
        stylizedPhotoPath: 'assets/photos/young_recliner.jpg',
        date: 'Date',
        caption: 'Boobie milkies!',
        phase: GamePhase.crawling,
      ),
      // Crib memory (phase 1)
      MemoryItemData.simple(
        x: 470,
        y: 1106,
        photoPath: 'assets/photos/young_in_crib.jpg',
        date: 'Date',
        caption: 'Sweet dreams',
        phase: GamePhase.crawling,
      ),

      // Changing table memory (phase 1)
      MemoryItemData.simple(
        x: 868,
        y: 842,
        photoPath: 'assets/photos/young_changing_station.jpg',
        date: 'Date',
        caption: 'Diaper duty',
        phase: GamePhase.crawling,
      ),

      MemoryItemData.simple(
        x: 868,
        y: 842,
        photoPath: 'assets/photos/young_changing_station.jpg',
        date: 'Date',
        caption: 'I like to chill while we change',
        phase: GamePhase.crawling,
      ),
      MemoryItemData(
        x: 1353,
        y: 786,
        stylizedPhotoPath: 'assets/photos/young_downstairs.jpg',
        date: 'Date',
        caption: 'Back downstairs...',
        levelTrigger: 'mainFloor',
        phase: GamePhase.crawling,
      ),

      MemoryItemData(
        x: 192,
        y: 1444,
        stylizedPhotoPath: 'assets/photos/young_bath_time.jpg',
        date: 'Date',
        caption: 'Back downstairs...',
        phase: GamePhase.crawling,
      ),


      // ========================================
      // Phase 2 memories (walking) - old_ photos
      // ========================================

      // Door memory - returns to main floor (phase 2)

      // Armchair memory (phase 2)
      MemoryItemData(
        x: 210, y: 1449,
        stylizedPhotoPath: 'assets/photos/old_bathtime.jpg',
        date: 'Date',
        caption: 'Bathtime, look I can wash my butt',
        photos: [
          'assets/photos/old_bath_time_2.jpg',
        ],
        phase: GamePhase.walking,
      ),
      MemoryItemData(
        x: 541, y: 1087,
        stylizedPhotoPath: 'assets/photos/old_crib_drunk.png',
        date: 'Date',
        caption: 'Older cribs!',
        phase: GamePhase.walking,
      ),
      MemoryItemData(
        x: 929, y: 886,
        stylizedPhotoPath: 'assets/photos/old_changing_pad.jpg',
        date: 'Date',
        caption: 'Older changing table!',
        phase: GamePhase.walking,
      )
    ];
  }

  /// The full size of the map image
  Vector2 get mapSize => backgroundSprite.size;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the background image
    final sprite = await game.loadSprite('house/upstairs_map.png');

    backgroundSprite = SpriteComponent(
      sprite: sprite,
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
    );

    add(backgroundSprite);

    // Add collision obstacles
    _addObstacles();

    // Add memory items
    _addMemories();

    // Debug: Add a visual indicator for playable bounds
    if (MemoryLaneGame.debugObstaclePlacementEnabled) {
      _addDebugBounds();
    }
  }

  /// Adds all collision obstacles to the map
  void _addObstacles() {
    final showDebug = MemoryLaneGame.debugObstaclePlacementEnabled;

    for (final data in getObstacleData()) {
      add(data.toObstacle(showDebug: showDebug));
    }
  }

  /// Adds memory items for the current game phase
  void _addMemories() {
    final showDebug = MemoryLaneGame.debugObstaclePlacementEnabled;
    final currentPhase = game.currentPhase;

    // Filter memories by current phase
    final phaseMemories = getMemoryData().where((m) => m.phase == currentPhase);

    for (final data in phaseMemories) {
      add(data.toMemoryItem(showDebug: showDebug));
    }

    // Update game's memory count for this phase
    game.setPhaseMemoryCount(phaseMemories.length);
  }

  void _addDebugBounds() {
    add(
      RectangleComponent(
        position: Vector2(playableBounds.left, playableBounds.top),
        size: Vector2(playableBounds.width, playableBounds.height),
        paint: Paint()
          ..color = Colors.green.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ),
    );
  }
}
