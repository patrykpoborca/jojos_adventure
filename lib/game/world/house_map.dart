import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:memory_lane/game/memory_lane_game.dart';
import 'package:memory_lane/game/world/christmas_lights.dart';
import 'package:memory_lane/game/world/memory_item.dart';
import 'package:memory_lane/game/world/music_zone.dart';
import 'package:memory_lane/game/world/obstacle.dart';
import 'package:memory_lane/game/world/character.dart';
import 'package:memory_lane/game/world/walking_character.dart';

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
      ObstacleData(x: 168, y: 346, width: 430, height: 130, label: 'northElCouch'),
      ObstacleData(x: 320, y: 607, width: 135, height: 55, label: 'ottoman'),
      ObstacleData(x: 337, y: 988, width: 177, height: 88, label: 'whiteChristmasTree'),
      ObstacleData(x: 899, y: 615, width: 100, height: 375, label: 'eastCenterStaircase'),
      ObstacleData(x: 618, y: 608, width: 83, height: 418, label: 'westCenterStaircase'),
      ObstacleData(x: 572, y: 596, width: 53, height: 162, label: 'livingRoomTv'),
      ObstacleData(x: 898, y: 120, width: 43, height: 334, label: 'builtIn'),
      ObstacleData(x: 1074, y: 288, width: 240, height: 119, label: 'diningTable'),
      ObstacleData(x: 1256, y: 138, width: 240, height: 120, label: 'greenChristmasTree'),
      ObstacleData(x: 1561, y: 338, width: 156, height: 124, label: 'patioTable'),
      ObstacleData(x: 1855, y: 384, width: 145, height: 340, label: 'fireplaceWall'),
      ObstacleData(x: 1451, y: 678, width: 309, height: 45, label: 'southPatioWall'),
      ObstacleData(x: 1470, y: 130, width: 47, height: 575, label: 'westPatioWall'),
      ObstacleData(x: 1984, y: 429, width: 485, height: 51, label: 'officeNorthWall'),
      ObstacleData(x: 2395, y: 464, width: 57, height: 575, label: 'eastHouseWallToGarage'),
      ObstacleData(x: 1952, y: 810, width: 483, height: 30, label: 'southOfficeWall'),
      ObstacleData(x: 1950, y: 947, width: 196, height: 38, label: 'southBathroomWall'),
      ObstacleData(x: 2140, y: 801, width: 269, height: 165, label: 'dogShowerAndShelves'),
      ObstacleData(x: 1741, y: 838, width: 96, height: 327, label: 'backStairs'),
      ObstacleData(x: 1104, y: 639, width: 165, height: 392, label: 'kitchenIsland'),
      ObstacleData(x: 1487, y: 901, width: 78, height: 178, label: 'kitchenTable'),
      ObstacleData(x: 2440, y: 452, width: 660, height: 166, label: 'garageDoor'),
    ];
  }

  /// Returns the list of memory item data (static version for cross-level counting)
  static List<MemoryItemData> getMemoryDataStatic() => _memoryData;

  /// Returns the list of memory item data
  /// Format: stylizedPhotoPath = cover, photos = slideshow images, levelTrigger = optional level
  List<MemoryItemData> getMemoryData() => _memoryData;

  static const List<MemoryItemData> _memoryData = [
      // ========================================
      // Phase 1 memories (crawling) - young_ photos
      // ========================================
      MemoryItemData.simple(
        x: 230, y: 243,
        photoPath: 'assets/photos/young_some_times_parents_travel.jpg',
        date: 'Jul 30, 2025', caption: 'Parents travel sometimes too!',
      ),
      MemoryItemData.simple(
        x: 406, y: 594,
        photoPath: 'assets/photos/young_halena_couch.jpg',
        date: 'Jul 3, 2025', caption: 'Halina-core-automon',
      ),
      // Jack time - slideshow with 2 photos!
      MemoryItemData(
        x: 260, y: 517,
        stylizedPhotoPath: 'assets/photos/young_jack_couch.jpg',
        photos: ['assets/photos/young_jack_couch_2.jpg'],
        date: 'Jan 3, 2025', caption: 'Jack time',
      ),
      MemoryItemData.simple(
        x: 256, y: 822,
        photoPath: 'assets/photos/old_window.jpg',
        date: 'Nov 29, 2025', caption: 'Watching out the window',
        phase: GamePhase.walking
      ),
      MemoryItemData.simple(
          x: 2712, y: 908,
          photoPath: 'assets/photos/young_road_trip.jpg',
          date: 'Feb 20, 2025', caption: 'Man it\'s cold outside',
          phase: GamePhase.crawling
      ),
      MemoryItemData.simple(
          x: 2712, y: 908,
          photoPath: 'assets/photos/exit_hero_image.png',
          date: 'Dec 21, 2025', caption: 'Ready for a road trip?',
          phase: GamePhase.walking,
          isEndgameTrigger: true,
      ),
      MemoryItemData(
        x: 1418, y: 355,
        stylizedPhotoPath: 'assets/photos/young_christmas.jpg',
        photos: [
          'assets/photos/young_christmas_one.jpg',
          'assets/photos/young_christmas_two.jpg',
        ],
        date: 'Dec 21, 2024', caption: 'Year 0 christmas',
      ),
      MemoryItemData.simple(
        x: 1428, y: 617,
        photoPath: 'assets/photos/young_baby_jail.jpg',
        date: 'Jul 21, 2025', caption: 'Prison cell',
      ),
      MemoryItemData.simple(
        x: 1198, y: 424,
        photoPath: 'assets/photos/young_board_games.jpg',
        date: 'Jan 26, 2025', caption: 'Board game times!',
      ),
      MemoryItemData(
        x: 874, y: 400,
        stylizedPhotoPath: 'assets/photos/young_bundle_ofjoy.jpg',
        photos: [
          'assets/photos/young_bundle_ofjoy_1.jpg',
          'assets/photos/young_bundle_ofjoy_2.jpg'
        ],
        date: 'Dec 22, 2024', caption: 'Bundle of joy (week 2)',
      ),
      MemoryItemData.simple(
        x: 495, y: 937,
        photoPath: 'assets/photos/young_christmas_tree.png',
        date: 'Jan 8, 2025', caption: 'Super boy',
      ),
      MemoryItemData.simple(
          x: 379, y: 491,
        photoPath: 'assets/photos/young_couch_sleep.jpg',
        date: 'Jan 5, 2025', caption: 'Nap times',
        phase: GamePhase.crawling
      ),
    MemoryItemData.simple(
        x: 575, y: 245,
        photoPath: 'assets/photos/young_game_start_memory.png',
        date: 'December 13, 2023', caption: 'Welcome to the house! Collect the memories!',
        phase: GamePhase.crawling
    ),

      MemoryItemData(
          x: 271, y: 645,
          stylizedPhotoPath: 'assets/photos/young_grandpa_couch.jpg',
          photos: [
            'assets/photos/young_ottoman.jpg',
          ],
          date: 'Mar 1, 2025', caption: 'Nap times',
          phase: GamePhase.crawling
      ),
      // Triggers upstairs nursery level (stays in crawling phase)
      MemoryItemData(
        x: 744, y: 581,
        stylizedPhotoPath: 'assets/photos/young_in_crib.png',
        date: 'Feb 4, 2025',
        caption: 'Let\'s go to the nursery',
        levelTrigger: 'upstairsNursery',
      ),
      MemoryItemData.simple(
        x: 2021, y: 868,
        photoPath: 'assets/photos/young_stinky_bathroom.jpg',
        date: 'Apr 30, 2025', caption: 'Smelly poop with mum',
      ),
      MemoryItemData.simple(
        x: 1298, y: 665,
        photoPath: 'assets/photos/young_countertop_sleep.jpg',
        date: 'Jan 25, 2025', caption: 'Nap time on the the countertop',
      ),

      // ========================================
      // Phase 2 memories (walking) - old_ photos
      // ========================================
      MemoryItemData.simple(
        x: 230, y: 243,
        photoPath: 'assets/photos/old_jojo_travels_too.jpg',
        date: 'Oct 10, 2025', caption: 'JoJo likes to come too sometimes!',
        phase: GamePhase.walking,
      ),
      MemoryItemData(
        x: 868, y: 259,
        stylizedPhotoPath: 'assets/photos/old_pumpkin_boy.jpg',
        photos: [
          'assets/photos/old_thanksgiving_1.jpg',
          'assets/photos/old_thanksgiving_2.jpg',
          'assets/photos/old_thanksgiving_3.jpg',
          'assets/photos/old_thanksgiving_4.jpg',
          'assets/photos/old_thanksgiving_5.jpg',
        ],
        date: 'Oct 18, 2025', caption: 'Pumpkin horror story',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 835, y: 1105,
        photoPath: 'assets/photos/old_bottle_factory.png',
        date: 'Date', caption: 'Bottle assembly factory',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 367, y: 466,
        photoPath: 'assets/photos/old_couch_chill.jpg',
        date: 'Nov 7, 2025', caption: 'Dad works too much',
        phase: GamePhase.walking,
      ),

      MemoryItemData.simple(
        x: 255, y: 642,
        photoPath: 'assets/photos/old_couch_fun.jpg',
        date: 'Nov 25, 2025', caption: 'Meeting Bennet!',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 1391, y: 1019,
        photoPath: 'assets/photos/old_heights.jpg',
        date: 'Nov 13, 2025', caption: 'Look how tall I am!',
        phase: GamePhase.walking,
      ),
      MemoryItemData(
        x: 1007, y: 992,
        stylizedPhotoPath: 'assets/photos/old_fall_1.png',
        photos: [
          'assets/photos/old_fall_2.png',
        ],
        date: 'Date', caption: 'Hmm fuzzy memory',
        phase: GamePhase.walking,
      ),
      // Grand parents memory - Thanksgiving slideshow with 5 photos!
      MemoryItemData(
        x: 1319, y: 800,
        stylizedPhotoPath: 'assets/photos/young_helmet_counter.jpg',
        date: 'Aug 10, 2025', caption: 'Helmet boy',
        phase: GamePhase.walking,
      ),
      MemoryItemData(
        x: 1418, y: 355,
        stylizedPhotoPath: 'assets/photos/old_parents_tree.jpg',
        photos: [
          'assets/photos/old_grandparents_tree.jpg',
          'assets/photos/old_inlaws_tree.jpg'
        ],
        date: 'Dec 1, 2025', caption: 'Year one christmas tree',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 1506, y: 867,
        photoPath: 'assets/photos/old_eating_countertop.jpg',
        date: 'Oct 18, 2025', caption: 'Force feeding station',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 1054, y: 305,
        photoPath: 'assets/photos/old_board_game2.png',
        date: 'Date', caption: 'I like crisps',
        phase: GamePhase.walking,
      ),
      MemoryItemData(
        x: 1251, y: 650,
        stylizedPhotoPath: 'assets/photos/old_cookies.jpg',
        photos: [
          'assets/photos/old_cookies_1.jpg',
          'assets/photos/old_cookies_2.jpg',
          'assets/photos/old_cookies_3.jpg',
        ],
        date: 'Dec 24, 2025', caption: 'Hey, this is recent!',
        phase: GamePhase.walking,
      ),
      MemoryItemData(
        x: 744, y: 581,
        stylizedPhotoPath: 'assets/photos/old_going_to_bed.jpg',
        date: 'Dec 3, 2025',
        caption: 'Jojo can walk up the stairs!',
        levelTrigger: 'upstairsNursery',
        phase: GamePhase.walking
      ),
      // Stairs memory - triggers upstairs level!
      MemoryItemData(
        x: 1958, y: 1116,
        stylizedPhotoPath: 'assets/photos/old_bathtime.jpg',
        date: 'Nov 3, 2025',
        caption: 'Climbing the stairs...',
        levelTrigger: 'upstairsNursery',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 2079, y: 1026,
        photoPath: 'assets/photos/young_dog_hang.jpg',
        date: 'Aug 24, 2025', caption: 'Dog cuddles',
        phase: GamePhase.crawling,
      ),
      MemoryItemData.simple(
        x: 2079, y: 1026,
        photoPath: 'assets/photos/old_dog_hang.jpg',
        date: 'Date', caption: 'Dog cuddles',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 2329, y: 544,
        photoPath: 'assets/photos/old_working.jpg',
        date: 'Sep 19, 2025', caption: 'Working with dad',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 2329, y: 544,
        photoPath: 'assets/photos/young_office_table.jpg',
        date: 'Feb 5, 2025', caption: 'Working with dad',
        phase: GamePhase.crawling,
      ),
      MemoryItemData.simple(
        x: 2965, y: 265,
        photoPath: 'assets/photos/old_outdoor.jpg',
        date: 'Nov 29, 2025', caption: 'Snowday!',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 2965, y: 265,
        photoPath: 'assets/photos/young_outdoors.jpg',
        date: 'Aug 31, 2025', caption: 'Outdoor vibes in the yard!',
        phase: GamePhase.crawling,
      ),
      MemoryItemData.simple(
        x: 2143, y: 643,
        photoPath: 'assets/photos/old_baby_office_hang.jpg',
        date: 'Dec 3, 2025', caption: 'OGs know this aint here but it was cute',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 1744, y: 522,
        photoPath: 'assets/photos/old_grandma_cuddles.jpg',
        date: 'May 4, 2025', caption: 'Hanging out with grandma!',
        phase: GamePhase.walking,
      ),
      MemoryItemData.simple(
        x: 1060, y: 910,
        photoPath: 'assets/photos/old_grandma_cuddles.jpg',
        date: 'May 4, 2025', caption: 'Shakes with grandma!',
        phase: GamePhase.crawling,
      ),

      MemoryItemData.simple(
        x: 1521, y: 854,
        photoPath: 'assets/photos/young_not_quite_here.jpg',
        date: 'Jul 28, 2025', caption: 'This is from grandmas!',
        phase: GamePhase.crawling,
      ),

      MemoryItemData(
        x: 2563, y: 414,
        stylizedPhotoPath: 'assets/photos/old_travel_1.jpg',
        photos: [
          'assets/photos/old_travel_2.jpg',
          'assets/photos/old_travel_3.jpg',
          'assets/photos/old_travel_4.jpg',
          'assets/photos/old_travel_5.jpg',
          'assets/photos/old_travel_6.jpg',
          'assets/photos/old_travel_7.jpg',
          'assets/photos/old_travel_8.jpg'
        ],
        date: 'Oct 7, 2025', caption: 'Secret outside adventure, it was in the yard right?!',
        phase: GamePhase.walking,
      ),
    ];

  /// Returns the list of rectangular music zone data
  /// Add music zones here to define areas with background music
  List<MusicZoneData> getMusicZoneData() {
    return const [
      MusicZoneData(
        x: 1992, y: 481, width: 482, height: 369,
        zoneId: 'dads_office',
        musicFile: 'franky.mp3',
        maxVolume: 0.6,
      ),
      MusicZoneData(
        x: 2454, y: 651, width: 606, height: 494,
        zoneId: 'garage',
        musicFile: 'kpop.mp3',
        maxVolume: 0.6,
      ),
    ];
  }

  /// Returns the list of polygon music zone data
  List<PolygonMusicZoneData> getPolygonMusicZoneData() {
    return [
      // Outdoor patio area - non-rectangular shape
      PolygonMusicZoneData(
        vertices: [
          Vector2(1938, 690),
          Vector2(1532, 688),
          Vector2(1530, 136),
          Vector2(3080, 159),
          Vector2(3090, 438),
          Vector2(2470, 453),
          Vector2(2470, 381),
          Vector2(1908, 395),
        ],
        zoneId: 'outdoor',
        musicFile: 'upbeat_trim_a.mp3',
        maxVolume: 0.4,
      ),
    ];
  }

  /// Returns the list of Christmas lights positions (triangles)
  List<ChristmasLightsData> getChristmasLightsData() {
    return const [
      // Green Christmas tree in dining area
      ChristmasLightsData(
        x1: 1387, y1: 143, // Top
        x2: 1444, y2: 302, // Bottom right
        x3: 1324, y3: 310, // Bottom left
        lightsPerEdge: 5,
      ),
      // White Christmas tree in living room
      ChristmasLightsData(
        x1: 432, y1: 878,  // Top
        x2: 364, y2: 1071, // Bottom left
        x3: 494, y3: 1071, // Bottom right
        lightsPerEdge: 5,
      ),
    ];
  }

  /// Returns the list of SFX zone data (point-based with distance falloff)
  List<SfxZoneData> getSfxZoneData() {
    return const [
      // TV in living room - continuous static/noise
      SfxZoneData(
        x: 598, y: 680,
        zoneId: 'living_room_tv',
        sfxFile: 'sxefil.mp3',
        innerRadius: 80,
        outerRadius: 350,
        maxVolume: 0.4,
        oneShot: false,
      ),
      // Fireplace crackling
      SfxZoneData(
        x: 1927, y: 550,
        zoneId: 'fireplace',
        sfxFile: 'fire.mp3',
        innerRadius: 100,
        outerRadius: 400,
        maxVolume: 0.5,
        oneShot: false,
      ),
      SfxZoneData(
        x: 1770, y: 160,
        zoneId: 'barbecue',
        sfxFile: 'sizzle.mp3',
        innerRadius: 100,
        outerRadius: 400,
        maxVolume: 0.5,
        oneShot: false,
      ),
      SfxZoneData(
        x: 1770, y: 160,
        zoneId: 'barbecue',
        sfxFile: 'sizzle.mp3',
        innerRadius: 100,
        outerRadius: 400,
        maxVolume: 0.5,
        oneShot: false,
      ),
      SfxZoneData(
        x: 978, y: 1075,
        zoneId: 'bark',
        sfxFile: 'bark.mp3',
        innerRadius: 150,
        outerRadius: 300,
        maxVolume: 0.5,
        oneShot: false,
      ),
      // Keyboard clacking in office area
      SfxZoneData(
        x: 2317, y: 550,
        zoneId: 'keyboard_clacking',
        sfxFile: 'clacking.mp3',
        innerRadius: 80,
        outerRadius: 300,
        maxVolume: 0.4,
        oneShot: false,
      ),

    ];
  }

  /// Returns the list of character data
  List<CharacterData> getCharacterData() {
    return const [
      // Willow - sleeping dog in the living room
      CharacterData(
        x: 320, y: 880,
        name: 'Willow',
        spritePath: 'sprites/willow.png',
        columns: 8,
        rows: 8,
        displaySize: 120,
        animationSpeed: 0.15,
        scale: 1.3,
        flipped: false,
        collisionRadius: 25.0,
        collisionOffsetY: 30.0,
        characterType: CharacterType.pet,
      ),
    ];
  }

  /// Returns the list of walking character data (characters that move between waypoints)
  List<WalkingCharacterData> getWalkingCharacterData() {
    return const [
      // Dad - walks around the office area
      WalkingCharacterData(
        x: 2103, y: 506,
        name: 'Dad',
        spritePath: 'sprites/father.png',
        waypoints: [
          [2103, 506],  // Start position (office)
          [2103, 691],  // Move down
          [2354, 698],  // Move right
        ],
        columns: 5,
        rows: 4,
        displaySize: 64,
        animationSpeed: 0.15,
        scale: 3.0,
        scaleX: 0.9, // 10% narrower
        walkSpeed: 60.0,
        loopWaypoints: false, // Ping-pong between waypoints
        collisionRadius: 0.0, // No collision
        interactionMessage: 'Hey buddy! Dad loves you!',
        waypointPauseDuration: 2.0,
      ),
      // Grandma - walks around the outdoor/yard area
      WalkingCharacterData(
        x: 2975, y: 306,
        name: 'Grandma',
        spritePath: 'sprites/grandma.png',
        waypoints: [
          [2975, 306],  // Start position
          [2200, 306],  // Walk left
        ],
        columns: 4,
        rows: 4,
        displaySize: 64,
        animationSpeed: 0.15,
        scale: 3.0,
        scaleX: 0.9,
        walkSpeed: 50.0, // Slightly slower than dad
        loopWaypoints: false, // Ping-pong between waypoints
        collisionRadius: 0.0,
        interactionMessage: 'Hello my little sweetheart!',
        waypointPauseDuration: 2.5,
      ),
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

    // Add music zones
    _addMusicZones();

    // Add SFX zones
    await _addSfxZones();

    // Add Christmas lights
    _addChristmasLights();

    // Add characters
    _addCharacters();

    // Add walking characters
    _addWalkingCharacters();

    // Add static decorations (car, etc.)
    await _addDecorations();

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
      final memoryItem = data.toMemoryItem(showDebug: showDebug);
      // Check if this memory was already collected
      if (game.isMemoryCollected(data.stylizedPhotoPath, currentPhase)) {
        memoryItem.markAsCollected();
      }
      add(memoryItem);
    }
  }

  /// Adds music zones to the map
  void _addMusicZones() {
    final showDebug = MemoryLaneGame.debugObstaclePlacementEnabled;

    // Add rectangular music zones
    for (final data in getMusicZoneData()) {
      add(data.toMusicZone(showDebug: showDebug));
    }

    // Add polygon music zones
    for (final data in getPolygonMusicZoneData()) {
      add(data.toMusicZone(showDebug: showDebug));
    }
  }

  /// Adds SFX zones to the map (registers with AudioManager)
  Future<void> _addSfxZones() async {
    for (final data in getSfxZoneData()) {
      await data.register();
    }
  }

  /// Adds Christmas lights to the map
  void _addChristmasLights() {
    for (final data in getChristmasLightsData()) {
      add(data.toComponent());
    }
  }

  /// Adds characters to the map
  void _addCharacters() {
    final showDebug = MemoryLaneGame.debugObstaclePlacementEnabled;

    for (final data in getCharacterData()) {
      add(data.toCharacter(showDebug: showDebug));
    }
  }

  /// Adds walking characters to the map
  void _addWalkingCharacters() {
    final showDebug = MemoryLaneGame.debugObstaclePlacementEnabled;

    for (final data in getWalkingCharacterData()) {
      add(data.toWalkingCharacter(showDebug: showDebug));
    }
  }

  /// Adds static decoration sprites (car, furniture, etc.)
  Future<void> _addDecorations() async {
    // SUV in the garage
    final suvSprite = await game.loadSprite('sprites/suv.png');
    add(SpriteComponent(
      sprite: suvSprite,
      position: Vector2(2685, 831),
      anchor: Anchor.center,
      scale: Vector2.all(0.25),
    ));

    // Collision box for the SUV
    add(const ObstacleData(
      x: 2758, y: 670,
      width: 100, height: 318,
      label: 'rivianr1s',
    ).toObstacle(showDebug: MemoryLaneGame.debugObstaclePlacementEnabled));
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
