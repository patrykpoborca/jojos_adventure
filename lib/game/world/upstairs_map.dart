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
      ObstacleData(x: 0, y: 0, width: 576, height: 20, label: 'northWall'),
      ObstacleData(x: 0, y: 460, width: 576, height: 20, label: 'southWall'),
      ObstacleData(x: 0, y: 0, width: 20, height: 480, label: 'westWall'),
      ObstacleData(x: 556, y: 0, width: 20, height: 480, label: 'eastWall'),

      // Crib (left side)
      ObstacleData(x: 20, y: 280, width: 80, height: 140, label: 'crib'),

      // Changing table/dresser area (upper middle)
      ObstacleData(x: 130, y: 60, width: 150, height: 80, label: 'changingTable'),

      // Door area (center top) - smaller collision so player can approach
      ObstacleData(x: 280, y: 20, width: 60, height: 40, label: 'door'),

      // Closet (right side)
      ObstacleData(x: 400, y: 20, width: 156, height: 180, label: 'closet'),

      // Armchair (bottom right)
      ObstacleData(x: 380, y: 320, width: 100, height: 100, label: 'armchair'),

      // Nightstand with lamp (bottom right corner)
      ObstacleData(x: 490, y: 380, width: 60, height: 60, label: 'nightstand'),

      // Ottoman/pouf (near armchair)
      ObstacleData(x: 340, y: 400, width: 40, height: 40, label: 'ottoman'),

      // Toy basket (left of changing table)
      ObstacleData(x: 80, y: 140, width: 50, height: 50, label: 'toyBasket'),
    ];
  }

  /// Returns the list of memory item data for the nursery
  List<MemoryItemData> getMemoryData() {
    return const [
      // Door memory - returns to main floor
      MemoryItemData(
        x: 310,
        y: 100,
        stylizedPhotoPath: 'assets/photos/young_middle_nursery.jpg',
        photos: ['assets/photos/young_middle_nursery.jpg'],
        date: 'Date',
        caption: 'Back downstairs...',
        levelTrigger: 'mainFloor',
      ),

      // Crib memory
      MemoryItemData.simple(
        x: 60,
        y: 350,
        photoPath: 'assets/photos/young_in_crib.jpg',
        date: 'Date',
        caption: 'Sweet dreams',
      ),

      // Changing table memory
      MemoryItemData.simple(
        x: 200,
        y: 100,
        photoPath: 'assets/photos/young_changing_station.jpg',
        date: 'Date',
        caption: 'Diaper duty',
      ),

      // Armchair memory
      MemoryItemData.simple(
        x: 420,
        y: 360,
        photoPath: 'assets/photos/young_recliner.jpg',
        date: 'Date',
        caption: 'Story time',
      ),

      // Window/forest view memory
      MemoryItemData.simple(
        x: 250,
        y: 180,
        photoPath: 'assets/photos/young_middle_nursery.jpg',
        date: 'Date',
        caption: 'Watching the trees',
      ),

      // Closet area memory
      MemoryItemData.simple(
        x: 450,
        y: 220,
        photoPath: 'assets/photos/young_halena_couch.jpg',
        date: 'Date',
        caption: 'Getting dressed',
      ),
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
