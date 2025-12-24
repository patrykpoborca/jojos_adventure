import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:memory_lane/game/memory_lane_game.dart';
import 'package:memory_lane/game/world/memory_item.dart';
import 'package:memory_lane/game/world/obstacle.dart';

/// The game world - a top-down view of the house
class HouseMap extends PositionComponent with HasGameReference<MemoryLaneGame> {
  late final SpriteComponent backgroundSprite;

  /// The playable area bounds (inside the house)
  /// These values are approximate and should be adjusted based on the actual map
  Rect get playableBounds => Rect.fromLTWH(
        70, // Left margin (garland border)
        50, // Top margin (garland + title)
        mapSize.x - 140, // Width minus borders
        mapSize.y - 100, // Height minus borders
      );

  /// Returns the list of obstacle data for furniture and boundaries
  List<ObstacleData> getObstacleData() {
    return const [
      ObstacleData(x: 245, y: 314, width: 400, height: 53, label: 'entryWaySouth'),
      ObstacleData(x: 134, y: 114, width: 2965, height: 51, label: 'northBoundary'),
      ObstacleData(x: 3047, y: 119, width: 48, height: 1046, label: 'eastBoundary'),
      ObstacleData(x: 134, y: 1162, width: 2993, height: 3, label: 'southBoundary'),
      ObstacleData(x: 134, y: 933, width: 143, height: 231, label: 'southWestBoundary'),
      ObstacleData(x: 134, y: 338, width: 103, height: 573, label: 'westBoundary'),
      ObstacleData(x: 168, y: 446, width: 430, height: 54, label: 'northElCouch'),
      ObstacleData(x: 297, y: 607, width: 165, height: 55, label: 'ottoman'),
      ObstacleData(x: 337, y: 988, width: 177, height: 88, label: 'whiteChristmasTree'),
      ObstacleData(x: 899, y: 615, width: 136, height: 375, label: 'eastCenterStaircase'),
      ObstacleData(x: 618, y: 608, width: 83, height: 418, label: 'westCenterStaircase'),
      ObstacleData(x: 572, y: 596, width: 53, height: 162, label: 'livingRoomTv'),
      ObstacleData(x: 898, y: 120, width: 43, height: 334, label: 'builtIn'),
      ObstacleData(x: 1074, y: 288, width: 240, height: 119, label: 'diningTable'),
      ObstacleData(x: 1306, y: 158, width: 149, height: 105, label: 'greenChristmasTree'),
      ObstacleData(x: 1561, y: 338, width: 156, height: 124, label: 'patioTable'),
      ObstacleData(x: 1855, y: 384, width: 145, height: 340, label: 'fireplaceWall'),
      ObstacleData(x: 1451, y: 678, width: 309, height: 45, label: 'southPatioWall'),
      ObstacleData(x: 1470, y: 130, width: 47, height: 575, label: 'westPatioWall'),
      ObstacleData(x: 1984, y: 429, width: 485, height: 51, label: 'officeNorthWall'),
      ObstacleData(x: 2395, y: 464, width: 57, height: 701, label: 'eastHouseWallToGarage'),
      ObstacleData(x: 1952, y: 810, width: 483, height: 30, label: 'southOfficeWall'),
      ObstacleData(x: 1950, y: 947, width: 196, height: 38, label: 'southBathroomWall'),
      ObstacleData(x: 2140, y: 801, width: 269, height: 165, label: 'dogShowerAndShelves'),
      ObstacleData(x: 1741, y: 838, width: 96, height: 327, label: 'backStairs'),
      ObstacleData(x: 1104, y: 639, width: 165, height: 392, label: 'kitchenIsland'),
      ObstacleData(x: 1487, y: 901, width: 78, height: 178, label: 'kitchenTable'),
      ObstacleData(x: 2440, y: 452, width: 660, height: 166, label: 'garageDoor'),
    ];
  }

  /// Returns the list of memory item data
  /// Format: stylizedPhotoPath = cover, photos = slideshow images, levelTrigger = optional level
  List<MemoryItemData> getMemoryData() {
    return const [
      // Phase 1 memories (crawling)
      MemoryItemData.simple(x: 188, y: 243, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Going to sunday brunch! 1'),
      MemoryItemData.simple(x: 406, y: 594, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Halina-core-automon'),
      MemoryItemData.simple(x: 260, y: 517, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Jack time'),
      MemoryItemData.simple(x: 256, y: 822, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Watching out the window'),
      MemoryItemData.simple(x: 1418, y: 355, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Year 0 christmas'),
      MemoryItemData.simple(x: 1428, y: 617, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Prison cell'),
      MemoryItemData.simple(x: 1198, y: 424, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Board game time 1'),
      MemoryItemData.simple(x: 874, y: 400, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Bundle of joy (week 2)'),
      MemoryItemData.simple(x: 495, y: 937, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Christmas lights'),
      MemoryItemData.simple(x: 744, y: 581, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Going to bed 1'),
      MemoryItemData.simple(x: 2021, y: 868, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Smelly poop'),
      MemoryItemData.simple(x: 3178, y: 993, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Hanging with kevork?'),
      MemoryItemData.simple(x: 1298, y: 665, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Helmet boy'),

      // Phase 2 memories (walking)
      MemoryItemData.simple(x: 188, y: 243, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Going to sunday brunch! 2'),
      MemoryItemData.simple(x: 868, y: 259, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Pumpkin horror story'),
      MemoryItemData.simple(x: 835, y: 1105, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Bottle assembly factory'),
      MemoryItemData.simple(x: 1007, y: 992, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Hmm fuzzy memory'),
      MemoryItemData.simple(x: 1319, y: 800, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Grand parents memory'),
      MemoryItemData.simple(x: 1418, y: 355, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Year one christmas tree'),
      MemoryItemData.simple(x: 1506, y: 867, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Force feeding station'),
      MemoryItemData.simple(x: 1054, y: 305, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Board game 2'),
      MemoryItemData.simple(x: 744, y: 581, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Going to bed 2'),
      MemoryItemData.simple(x: 1963, y: 1096, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Stair climbing'),
      MemoryItemData.simple(x: 2079, y: 1026, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Dog cuddles'),
      MemoryItemData.simple(x: 2302, y: 562, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Working with dad'),
      MemoryItemData.simple(x: 1647, y: 624, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Chilling with grandma'),
      MemoryItemData.simple(x: 2143, y: 643, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Random office hang'),
      MemoryItemData.simple(x: 3174, y: 299, photoPath: 'memories/Memory.jpg', date: 'Date', caption: 'Hanging in the snow'),

      // Example with slideshow:
      // MemoryItemData(
      //   x: 500, y: 500,
      //   stylizedPhotoPath: 'memories/birthday_stylized.jpg',
      //   photos: ['memories/birthday_1.jpg', 'memories/birthday_2.jpg', 'memories/birthday_3.jpg'],
      //   date: 'Jan 2024',
      //   caption: 'First Birthday!',
      // ),
      //
      // Example with level trigger:
      // MemoryItemData(
      //   x: 1000, y: 800,
      //   stylizedPhotoPath: 'memories/adventure_cover.jpg',
      //   photos: ['memories/adventure_1.jpg'],
      //   date: 'Summer 2024',
      //   caption: 'A Special Adventure',
      //   levelTrigger: 'beach_level',
      // ),
    ];
  }

  /// The full size of the map image
  Vector2 get mapSize => backgroundSprite.size;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the background image
    final sprite = await game.loadSprite('house/background_of_level.png');

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
    if (MemoryLaneGame.debugObstaclePlacement) {
      _addDebugBounds();
    }
  }

  /// Adds all collision obstacles to the map
  void _addObstacles() {
    final showDebug = MemoryLaneGame.debugObstaclePlacement;

    for (final data in getObstacleData()) {
      add(data.toObstacle(showDebug: showDebug));
    }
  }

  /// Adds all memory items to the map
  void _addMemories() {
    final showDebug = MemoryLaneGame.debugObstaclePlacement;

    for (final data in getMemoryData()) {
      add(data.toMemoryItem(showDebug: showDebug));
    }
  }

  void _addDebugBounds() {
    // This helps visualize the playable area during development
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
