import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:memory_lane/game/memory_lane_game.dart';
import 'package:memory_lane/game/world/memory_item.dart';
import 'package:memory_lane/game/world/music_zone.dart';
import 'package:memory_lane/game/world/obstacle.dart';
import 'package:memory_lane/game/world/pet.dart';

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
        date: 'Jun 23, 2025',
        caption: 'Back downstairs...',
        phase: GamePhase.crawling,
      ),
      MemoryItemData(
        x: 1564,
        y: 1327,
        stylizedPhotoPath: 'assets/photos/young_recliner.jpg',
        date: 'Dec 24, 2024',
        caption: 'Boobie milkies!',
        phase: GamePhase.crawling,
      ),
      // Crib memory (phase 1)
      MemoryItemData.simple(
        x: 470,
        y: 1106,
        photoPath: 'assets/photos/young_in_crib.jpg',
        date: 'Feb 4, 2025',
        caption: 'Sweet dreams',
        phase: GamePhase.crawling,
      ),

      // Changing table memory (phase 1)
      MemoryItemData.simple(
        x: 868,
        y: 842,
        photoPath: 'assets/photos/young_changing_station.jpg',
        date: 'Feb 1, 2025',
        caption: 'Diaper duty',
        phase: GamePhase.crawling,
      ),
      MemoryItemData(
        x: 1353,
        y: 786,
        stylizedPhotoPath: 'assets/photos/young_downstairs.jpg',
        date: 'Apr 19, 2025',
        caption: 'Back downstairs...',
        levelTrigger: 'mainFloor',
        phase: GamePhase.crawling,
      ),

      MemoryItemData(
        x: 1353,
        y: 786,
        stylizedPhotoPath: 'assets/photos/old_down_stairs.jpg',
        date: 'Oct 18, 2025',
        caption: 'Back downstairs...',
        levelTrigger: 'mainFloor',
        phase: GamePhase.walking,
      ),

      MemoryItemData(
        x: 192,
        y: 1444,
        stylizedPhotoPath: 'assets/photos/young_bath_time.jpg',
        date: 'Jan 22, 2025',
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
        date: 'Nov 3, 2025',
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
        date: 'Nov 12, 2025',
        caption: 'Older changing table!',
        phase: GamePhase.walking,
      )
    ];
  }

  /// Returns the list of music zone data for the nursery
  List<MusicZoneData> getMusicZoneData() {
    return const [
      // Example: Nursery ambient music
      // MusicZoneData(
      //   x: 84, y: 800,
      //   width: 2000, height: 1000,
      //   zoneId: 'nursery',
      //   musicFile: 'lullaby.mp3',
      //   maxVolume: 0.5,
      // ),
    ];
  }

  /// Returns the list of pet data for the nursery
  List<PetData> getPetData() {
    return const [
      // Grinex - sleeping dog in the nursery
      PetData(
        x: 842, y: 1436,
        name: 'Grinex',
        spritePath: 'sprites/grinex.png',
        columns: 8,
        rows: 8,
        displaySize: 120,
        animationSpeed: 0.15,
        scale: 3.2, // Match upstairs scale
        flipped: false,
        collisionRadius: 80.0,
      ),
    ];
  }

  /// Returns the list of SFX zone data for the nursery
  List<SfxZoneData> getSfxZoneData() {
    return const [
      // Shower/bath running water sound
      SfxZoneData(
        x: 248, y: 1420,
        zoneId: 'bathtime',
        sfxFile: 'bathtime.mp3',
        innerRadius: 100.0,  // 2x scaled for upstairs
        outerRadius: 600.0,  // 2x scaled for upstairs
        maxVolume: 0.6,
        oneShot: false,
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

    // Add music zones
    _addMusicZones();

    // Add SFX zones
    await _addSfxZones();

    // Add pets
    _addPets();

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

  /// Scale for memory items on this map (larger for upstairs)
  static const double memoryScale = 2.5;

  /// Adds memory items for the current game phase
  void _addMemories() {
    final showDebug = MemoryLaneGame.debugObstaclePlacementEnabled;
    final currentPhase = game.currentPhase;

    // Filter memories by current phase
    final phaseMemories = getMemoryData().where((m) => m.phase == currentPhase);

    for (final data in phaseMemories) {
      add(data.toMemoryItem(showDebug: showDebug, scale: memoryScale));
    }

    // Update game's memory count for this phase
    game.setPhaseMemoryCount(phaseMemories.length);
  }

  /// Adds music zones to the map
  void _addMusicZones() {
    final showDebug = MemoryLaneGame.debugObstaclePlacementEnabled;

    for (final data in getMusicZoneData()) {
      add(data.toMusicZone(showDebug: showDebug));
    }
  }

  /// Adds SFX zones to the map
  Future<void> _addSfxZones() async {
    for (final data in getSfxZoneData()) {
      await data.register();
    }
  }

  /// Adds pets to the map
  void _addPets() {
    final showDebug = MemoryLaneGame.debugObstaclePlacementEnabled;

    for (final data in getPetData()) {
      add(data.toPet(showDebug: showDebug));
    }
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
