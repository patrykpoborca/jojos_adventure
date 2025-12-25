import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'actors/baby_player.dart';
import 'audio/audio_manager.dart';
import 'world/house_map.dart';
import 'world/upstairs_map.dart';

/// Available levels in the game
enum LevelId {
  /// Main floor of the house
  mainFloor,

  /// Upstairs nursery
  upstairsNursery,
}

/// Game state enumeration
enum GameState {
  loading,
  exploring,
  viewingMemory,
  montage,
  complete,
}

/// Overlay type for the polaroid overlay
enum OverlayType {
  memory,
  phaseComplete,
  gameComplete,
}

/// Game phase - progression through the story
enum GamePhase {
  /// Phase 1: Baby is crawling, collecting early memories
  crawling,

  /// Phase 2: Toddler is walking, collecting later memories
  walking,
}

/// Debug placement mode
enum DebugPlacementMode {
  obstacle,
  memory,
}

/// Memory data class representing a photo memory
class Memory {
  /// Stylized cover photo (shown first as polaroid)
  final String stylizedPhotoPath;

  /// List of regular photos for the slideshow
  final List<String> photos;

  /// Date of the memory
  final String date;

  /// Caption/title for the memory
  final String caption;

  /// Optional level ID to trigger after viewing (shows yes/no dialog)
  final String? levelTrigger;

  /// Which phase this memory belongs to
  final GamePhase phase;

  /// Optional music file to play when viewing this memory
  final String? musicFile;

  const Memory({
    required this.stylizedPhotoPath,
    required this.photos,
    required this.date,
    required this.caption,
    this.levelTrigger,
    this.phase = GamePhase.crawling,
    this.musicFile,
  });

  /// Convenience constructor for single photo memories
  const Memory.single({
    required String photoPath,
    required this.date,
    required this.caption,
    this.levelTrigger,
    this.phase = GamePhase.crawling,
    this.musicFile,
  })  : stylizedPhotoPath = photoPath,
        photos = const [];

  /// Whether this memory has a slideshow (multiple photos)
  bool get hasSlideshow => photos.isNotEmpty;

  /// Whether this memory triggers a level
  bool get triggersLevel => levelTrigger != null;
}

/// Main game class for Memory Lane
class MemoryLaneGame extends FlameGame with HasCollisionDetection {
  GameState state = GameState.loading;
  Memory? currentMemory;

  /// Type of overlay to show (memory, phase complete, or game complete)
  OverlayType overlayType = OverlayType.memory;

  late final BabyPlayer player;
  late final JoystickComponent joystick;

  /// Current level being played
  LevelId currentLevel = LevelId.mainFloor;

  /// Reference to the current map component
  PositionComponent? currentMap;

  /// Current game phase
  GamePhase currentPhase = GamePhase.crawling;

  /// Number of memories collected in current phase
  int _memoriesCollectedInPhase = 0;

  /// Total memories available in current phase (set when level loads)
  int _totalMemoriesInPhase = 0;

  /// Set of collected memory keys (to avoid double-counting)
  final Set<String> _collectedMemoryKeys = {};

  /// Callback when phase changes
  void Function(GamePhase newPhase)? onPhaseChanged;

  // ==========================================
  // DEBUG MODE FOR PLACEMENT
  // ==========================================
  /// Set to true to enable debug placement mode at startup
  static const bool debugObstaclePlacementEnabled = true;

  /// Runtime toggle for debug panel visibility
  static bool showDebugPanel = debugObstaclePlacementEnabled;

  /// Current placement mode (obstacle or memory)
  DebugPlacementMode _placementMode = DebugPlacementMode.obstacle;

  /// First corner of obstacle being placed
  Vector2? _obstacleStart;

  /// Preview rectangle shown while placing
  RectangleComponent? _previewRect;

  /// Callback to notify UI of placement state changes
  void Function(String message)? onDebugMessage;

  /// Callback to get the item name from UI
  String Function()? getObstacleName;

  /// Callback to notify UI of mode changes
  void Function(DebugPlacementMode mode)? onModeChanged;

  /// Callback to notify UI when debug panel is toggled
  void Function(bool visible)? onDebugPanelToggled;

  /// List of placed obstacles (for output)
  final List<String> _placedObstacles = [];

  /// List of placed memories (for output)
  final List<String> _placedMemories = [];

  /// Get current placement mode
  DebugPlacementMode get placementMode => _placementMode;

  @override
  Color backgroundColor() => const Color(0xFFE8F4F8); // Light icy blue to match snowy background

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load and add the tiled background (behind everything)
    await _loadBackground();

    // Create joystick for movement control
    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 25,
        paint: Paint()..color = const Color(0xAAD4A574),
      ),
      background: CircleComponent(
        radius: 60,
        paint: Paint()..color = const Color(0x44D4A574),
      ),
      margin: const EdgeInsets.only(left: 40, bottom: 40),
    );

    // Create player
    player = BabyPlayer(joystick: joystick);
    await world.add(player);

    // Load the initial level
    await _loadLevel(currentLevel);

    // Set up camera to follow player
    camera.follow(player, maxSpeed: 300, snap: true);

    // Add joystick to camera viewport (HUD)
    camera.viewport.add(joystick);

    // Game is ready
    state = GameState.exploring;

    if (debugObstaclePlacementEnabled) {
      debugPrint('=== DEBUG PLACEMENT MODE ===');
      debugPrint('Press M to toggle between OBSTACLE and MEMORY mode');
      debugPrint('OBSTACLE: SPACE to mark corners, creates rectangle');
      debugPrint('MEMORY: SPACE to place memory point');
      debugPrint('Press C to cancel current placement');
      debugPrint('Press P to print all placed items');
      debugPrint('Press L to switch levels (debug)');
      debugPrint('Press G to toggle phase (crawling/walking)');
      debugPrint('============================');
    }
  }

  /// Load a specific level
  Future<void> _loadLevel(LevelId levelId) async {
    // Clear any zone music from the previous level
    AudioManager().clearZoneMusic();

    // Remove current map if exists
    if (currentMap != null) {
      currentMap!.removeFromParent();
      currentMap = null;
    }

    // Create and add the new map, set level-specific ambient music
    switch (levelId) {
      case LevelId.mainFloor:
        currentMap = HouseMap();
        camera.viewfinder.zoom = 0.5; // Zoomed out for large house
        player.position = Vector2(500, 500); // Starting position
        player.scale = Vector2.all(1.0); // Normal size for large house
        await AudioManager().switchAmbientMusic(AudioManager.mainFloorAmbient);
        break;
      case LevelId.upstairsNursery:
        currentMap = UpstairsMap();
        camera.viewfinder.zoom = 0.25; // Closer zoom for small room
        player.position = Vector2(1358, 647); // Near the exit door
        player.scale = Vector2.all(2.0); // Larger baby for small room
        await AudioManager().switchAmbientMusic(AudioManager.upstairsAmbient);
        break;
    }

    await world.add(currentMap!);
    currentLevel = levelId;
    debugPrint('Loaded level: $levelId');
  }

  /// Switch to a different level
  Future<void> switchToLevel(LevelId levelId) async {
    if (levelId == currentLevel) return;

    state = GameState.loading;
    await _loadLevel(levelId);
    state = GameState.exploring;
  }

  /// Switch to level by string ID (used by memory triggers)
  Future<void> switchToLevelByName(String levelName) async {
    final levelId = LevelId.values.firstWhere(
      (l) => l.name == levelName,
      orElse: () => currentLevel,
    );
    await switchToLevel(levelId);
  }

  /// Toggle between levels (for debug)
  Future<void> toggleLevel() async {
    final nextLevel = currentLevel == LevelId.mainFloor
        ? LevelId.upstairsNursery
        : LevelId.mainFloor;
    await switchToLevel(nextLevel);
  }

  /// Toggle between phases (for debug)
  Future<void> togglePhase() async {
    final nextPhase = currentPhase == GamePhase.crawling
        ? GamePhase.walking
        : GamePhase.crawling;

    currentPhase = nextPhase;
    _memoriesCollectedInPhase = 0;
    _collectedMemoryKeys.clear();

    // Update player sprite based on phase
    if (nextPhase == GamePhase.walking) {
      await player.switchToWalking();
    } else {
      player.resetToCrawling();
    }

    // Reload current level to show new phase memories
    await _loadLevel(currentLevel);

    onPhaseChanged?.call(nextPhase);
    debugPrint('Toggled to ${nextPhase.name} phase');
  }

  /// Get the playable bounds for the current level
  Rect get currentPlayableBounds {
    if (currentMap is HouseMap) {
      return (currentMap as HouseMap).playableBounds;
    } else if (currentMap is UpstairsMap) {
      return (currentMap as UpstairsMap).playableBounds;
    }
    // Default fallback
    return const Rect.fromLTWH(0, 0, 1000, 1000);
  }

  /// Load the background that shows behind the map
  Future<void> _loadBackground() async {
    final bgSprite = await loadSprite('house/backgrounds_for_maps.jpeg');

    // Scale the background to cover a large area (bigger than any level)
    // Main floor is ~3100x1200, so we need something larger
    const targetWidth = 6336.0;
    const targetHeight = 3000.0;

    // Single large background, centered with negative offset
    final bgComponent = SpriteComponent(
      sprite: bgSprite,
      position: Vector2(-750, -500),
      size: Vector2(targetWidth, targetHeight),
      priority: -100, // Render behind everything
    );

    await world.add(bgComponent);
  }

  @override
  void update(double dt) {
    // Update audio manager (handles music fading)
    AudioManager().update(dt);

    // Only update game logic when exploring
    if (state == GameState.exploring) {
      super.update(dt);

      // Update obstacle preview if placing
      if (showDebugPanel) {
        updatePreview();
      }
    }
  }

  /// Toggles the debug panel visibility
  void toggleDebugPanel() {
    showDebugPanel = !showDebugPanel;
    debugPrint('Debug panel: ${showDebugPanel ? "ON" : "OFF"}, callback: ${onDebugPanelToggled != null}');
    onDebugPanelToggled?.call(showDebugPanel);
  }

  /// Toggles between obstacle and memory placement modes
  void togglePlacementMode() {
    if (!showDebugPanel) return;

    // Cancel any in-progress placement
    cancelObstaclePlacement();

    // Toggle mode
    _placementMode = _placementMode == DebugPlacementMode.obstacle
        ? DebugPlacementMode.memory
        : DebugPlacementMode.obstacle;

    final modeName = _placementMode == DebugPlacementMode.obstacle ? 'OBSTACLE' : 'MEMORY';
    final msg = 'Switched to $modeName mode';
    debugPrint(msg);
    onDebugMessage?.call(msg);
    onModeChanged?.call(_placementMode);
  }

  /// Handles spacebar press for placement (obstacle or memory)
  void handleObstaclePlacement() {
    if (!showDebugPanel) return;

    if (_placementMode == DebugPlacementMode.memory) {
      _handleMemoryPlacement();
    } else {
      _handleObstaclePlacementInternal();
    }
  }

  /// Handles memory point placement
  void _handleMemoryPlacement() {
    final currentPos = player.position.clone();
    final name = getObstacleName?.call() ?? 'Memory ${_placedMemories.length + 1}';

    // Generate the code
    final memoryCode = "MemoryItemData(x: ${currentPos.x.toInt()}, y: ${currentPos.y.toInt()}, photoPath: 'memories/$name.jpg', date: 'Date', caption: '$name'),";

    _placedMemories.add(memoryCode);

    // Print to console
    debugPrint('\n=== MEMORY PLACED ===');
    debugPrint(memoryCode);
    debugPrint('=====================\n');

    // Add visual marker
    world.add(CircleComponent(
      position: currentPos.clone(),
      radius: 24,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.amber.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill,
    ));
    world.add(CircleComponent(
      position: currentPos.clone(),
      radius: 24,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ));

    final msg = 'Memory placed: $name at (${currentPos.x.toInt()}, ${currentPos.y.toInt()})';
    onDebugMessage?.call(msg);
  }

  /// Handles obstacle rectangle placement
  void _handleObstaclePlacementInternal() {
    final currentPos = player.position.clone();

    if (_obstacleStart == null) {
      // First press - mark start corner
      _obstacleStart = currentPos;

      // Create preview rectangle
      _previewRect = RectangleComponent(
        position: currentPos.clone(),
        size: Vector2.zero(),
        paint: Paint()
          ..color = Colors.blue.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
      world.add(_previewRect!);

      final msg = 'Start corner: (${currentPos.x.toInt()}, ${currentPos.y.toInt()}) - Move to opposite corner and press SPACE';
      debugPrint(msg);
      onDebugMessage?.call(msg);
    } else {
      // Second press - create obstacle
      final start = _obstacleStart!;
      final end = currentPos;

      // Calculate rectangle bounds
      final x = start.x < end.x ? start.x : end.x;
      final y = start.y < end.y ? start.y : end.y;
      final width = (end.x - start.x).abs();
      final height = (end.y - start.y).abs();

      // Get name from UI or use default
      final name = getObstacleName?.call() ?? 'Obstacle ${_placedObstacles.length + 1}';

      // Generate the code
      final obstacleCode = "ObstacleData(x: ${x.toInt()}, y: ${y.toInt()}, width: ${width.toInt()}, height: ${height.toInt()}, label: '$name'),";

      _placedObstacles.add(obstacleCode);

      // Print to console
      debugPrint('\n=== OBSTACLE CREATED ===');
      debugPrint(obstacleCode);
      debugPrint('========================\n');

      // Update preview to final color
      _previewRect?.paint = Paint()
        ..color = Colors.green.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;
      _previewRect?.position = Vector2(x, y);
      _previewRect?.size = Vector2(width, height);

      // Add border
      world.add(RectangleComponent(
        position: Vector2(x, y),
        size: Vector2(width, height),
        paint: Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ));

      final msg = 'Created: $name (${width.toInt()} x ${height.toInt()})';
      onDebugMessage?.call(msg);

      // Reset for next obstacle
      _obstacleStart = null;
      _previewRect = null;
    }
  }

  /// Cancels current obstacle placement
  void cancelObstaclePlacement() {
    if (_previewRect != null) {
      _previewRect?.removeFromParent();
      _previewRect = null;
    }
    _obstacleStart = null;
    const msg = 'Placement cancelled';
    debugPrint(msg);
    onDebugMessage?.call(msg);
  }

  /// Prints all placed items (obstacles and memories)
  void printAllObstacles() {
    debugPrint('\n========== ALL PLACED OBSTACLES ==========');
    debugPrint('// Copy these to house_map.dart getObstacleData():\n');
    for (final obstacle in _placedObstacles) {
      debugPrint(obstacle);
    }
    debugPrint('\n===========================================');

    debugPrint('\n========== ALL PLACED MEMORIES ==========');
    debugPrint('// Copy these to house_map.dart getMemoryData():\n');
    for (final memory in _placedMemories) {
      debugPrint(memory);
    }
    debugPrint('\n==========================================');

    onDebugMessage?.call('Printed ${_placedObstacles.length} obstacles, ${_placedMemories.length} memories');
  }

  /// Updates preview rectangle while placing
  void updatePreview() {
    if (_obstacleStart != null && _previewRect != null) {
      final start = _obstacleStart!;
      final end = player.position;

      final x = start.x < end.x ? start.x : end.x;
      final y = start.y < end.y ? start.y : end.y;
      final width = (end.x - start.x).abs();
      final height = (end.y - start.y).abs();

      _previewRect!.position = Vector2(x, y);
      _previewRect!.size = Vector2(width, height);
    }
  }

  /// Triggers a memory viewing overlay
  void triggerMemory(Memory memory) {
    if (state != GameState.exploring) return;

    currentMemory = memory;
    overlayType = OverlayType.memory;
    state = GameState.viewingMemory;
    overlays.add('polaroid');
  }

  /// Resumes the game after viewing a memory (and track collection)
  void resumeGame() {
    // Track the collected memory
    if (currentMemory != null) {
      _onMemoryCollected(currentMemory!);
    }

    overlays.remove('polaroid');
    currentMemory = null;
    state = GameState.exploring;
  }

  /// Called when a memory is collected
  void _onMemoryCollected(Memory memory) {
    if (memory.phase == currentPhase) {
      // Create a unique key for this memory
      final memoryKey = '${memory.stylizedPhotoPath}_${memory.phase.name}';

      // Only count if not already collected
      if (!_collectedMemoryKeys.contains(memoryKey)) {
        _collectedMemoryKeys.add(memoryKey);
        _memoriesCollectedInPhase++;
        debugPrint('Memory collected: $_memoriesCollectedInPhase/$_totalMemoriesInPhase in ${currentPhase.name} phase');

        // Check if all memories in this phase are collected
        if (_memoriesCollectedInPhase >= _totalMemoriesInPhase && !memory.triggersLevel) {
          _onPhaseComplete();
        }
      }
    }
  }

  /// Called when all memories in a phase are collected
  void _onPhaseComplete() {
    if (currentPhase == GamePhase.crawling) {
      debugPrint('Phase 1 complete! Showing phase transition dialog...');
      showPhaseCompleteOverlay();
    } else {
      debugPrint('All phases complete! Showing game complete dialog...');
      showGameCompleteOverlay();
    }
  }

  /// Shows the phase complete overlay
  void showPhaseCompleteOverlay() {
    overlayType = OverlayType.phaseComplete;
    state = GameState.viewingMemory;
    overlays.add('polaroid');
  }

  /// Shows the game complete overlay
  void showGameCompleteOverlay() {
    overlayType = OverlayType.gameComplete;
    state = GameState.viewingMemory;
    overlays.add('polaroid');
  }

  /// Transition to a new game phase
  Future<void> transitionToPhase(GamePhase newPhase) async {
    if (newPhase == currentPhase) return;

    currentPhase = newPhase;
    _memoriesCollectedInPhase = 0;
    _collectedMemoryKeys.clear();

    // Update player sprite for walking phase
    if (newPhase == GamePhase.walking) {
      await player.switchToWalking();
    }

    // Reload current level to show new phase memories
    await _loadLevel(currentLevel);

    onPhaseChanged?.call(newPhase);
    debugPrint('Transitioned to ${newPhase.name} phase');
  }

  /// Set the total memory count for the current phase (called by maps)
  void setPhaseMemoryCount(int count) {
    _totalMemoriesInPhase = count;
    debugPrint('Phase ${currentPhase.name} has $count memories');
  }

  /// Get memories collected progress
  int get memoriesCollected => _memoriesCollectedInPhase;
  int get totalMemories => _totalMemoriesInPhase;

  /// Starts the end montage sequence
  void startMontage() {
    state = GameState.montage;
    // TODO: Implement montage sequence
  }
}

