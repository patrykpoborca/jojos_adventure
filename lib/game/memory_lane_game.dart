import 'dart:math' show atan2, pi;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'actors/baby_player.dart';
import 'audio/audio_manager.dart';
import 'input/floating_joystick.dart';
import 'world/fog_of_war.dart';
import 'world/house_map.dart';
import 'world/memory_item.dart';
// import 'world/snow_effect.dart'; // Disabled for performance
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
  endgameNotReady, // Shown when player tries endgame before collecting all memories
  couponUnlock, // Special coupon reward dialog
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

/// Movement control mode
enum MovementControlMode {
  /// Traditional fixed joystick in corner
  joystick,

  /// Floating/positional - touch anywhere to create virtual joystick
  positional,
}

/// Info about a collected memory for HUD display
class CollectedMemoryInfo {
  /// The memory's unique key (stylizedPhotoPath)
  final String memoryKey;

  /// Index into MemorySpriteTypes.all for the sprite
  final int spriteTypeIndex;

  /// Caption of the memory
  final String caption;

  const CollectedMemoryInfo({
    required this.memoryKey,
    required this.spriteTypeIndex,
    required this.caption,
  });
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

  /// Whether this memory triggers the endgame sequence
  final bool isEndgameTrigger;

  /// Whether this memory unlocks a coupon reward
  final bool isCouponReward;

  /// Custom coupon text/details (optional)
  final String? couponText;

  const Memory({
    required this.stylizedPhotoPath,
    required this.photos,
    required this.date,
    required this.caption,
    this.levelTrigger,
    this.phase = GamePhase.crawling,
    this.musicFile,
    this.isEndgameTrigger = false,
    this.isCouponReward = false,
    this.couponText,
  });

  /// Convenience constructor for single photo memories
  const Memory.single({
    required String photoPath,
    required this.date,
    required this.caption,
    this.levelTrigger,
    this.phase = GamePhase.crawling,
    this.musicFile,
    this.isEndgameTrigger = false,
    this.isCouponReward = false,
    this.couponText,
  })  : stylizedPhotoPath = photoPath,
        photos = const [];

  /// Whether this memory has a slideshow (multiple photos)
  bool get hasSlideshow => photos.isNotEmpty;

  /// Whether this memory triggers a level
  bool get triggersLevel => levelTrigger != null;

  /// Whether this memory triggers a special dialog (level, endgame, or coupon)
  bool get triggersDialog => levelTrigger != null || isCouponReward;

  /// Whether this memory should stay visible after collection (level or endgame trigger)
  bool get persistsAfterCollection => triggersLevel || isEndgameTrigger;
}

/// Main game class for Memory Lane
class MemoryLaneGame extends FlameGame with HasCollisionDetection, KeyboardEvents {
  GameState state = GameState.loading;

  /// Currently pressed movement keys (for keyboard input)
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Memory? currentMemory;

  /// Type of overlay to show (memory, phase complete, or game complete)
  OverlayType overlayType = OverlayType.memory;

  late final BabyPlayer player;
  late final JoystickComponent joystick;
  late final FloatingJoystick floatingJoystick;
  late final PositionComponent _cameraAnchor;

  /// Current movement control mode
  MovementControlMode _controlMode = MovementControlMode.positional;

  /// Get current control mode
  MovementControlMode get controlMode => _controlMode;

  /// Current level being played
  LevelId currentLevel = LevelId.mainFloor;

  /// Previous level (for spawn position logic)
  LevelId? _previousLevel;

  /// Whether this is the first load of the game
  bool _isFirstLoad = true;

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

  /// List of collected memories with their sprite type indices (for HUD display)
  final List<CollectedMemoryInfo> _collectedMemories = [];

  /// Currently highlighted memory (nearest to player within threshold)
  MemoryItem? _highlightedMemory;

  /// Distance threshold for highlighting nearest memory
  static const double _highlightThreshold = 300.0;

  /// Upstairs multiplier for highlight threshold
  static const double _highlightThresholdUpstairsMultiplier = 2.0;

  /// Callback when collected memories list changes (for HUD updates)
  void Function(List<CollectedMemoryInfo> memories)? onMemoriesCollectedChanged;

  /// Callback when phase changes
  void Function(GamePhase newPhase)? onPhaseChanged;

  // ==========================================
  // RESPONSIVE CAMERA ZOOM
  // ==========================================
  /// Base zoom for main floor (phones see this)
  static const double _mainFloorBaseZoom = 0.5;

  /// Base zoom for upstairs nursery (phones see this)
  static const double _upstairsBaseZoom = 0.25;

  /// Base screen width (phone in landscape)
  static const double _baseScreenWidth = 800.0;

  /// Maximum zoom multiplier to prevent too much zoom on large screens
  static const double _maxZoomMultiplier = 1.4;

  /// Calculate responsive zoom multiplier based on screen size.
  /// Larger screens get higher zoom (more zoomed in) to see less of the map.
  double _getZoomMultiplier() {
    final screenWidth = size.x;
    if (screenWidth <= _baseScreenWidth) return 1.0;

    // Gradually increase zoom for larger screens
    final scale = 1.0 + ((screenWidth - _baseScreenWidth) / _baseScreenWidth) * 0.4;
    return scale.clamp(1.0, _maxZoomMultiplier);
  }

  /// Get responsive zoom for the current level
  double _getResponsiveZoom(LevelId levelId) {
    final baseZoom = levelId == LevelId.mainFloor
        ? _mainFloorBaseZoom
        : _upstairsBaseZoom;
    return baseZoom * _getZoomMultiplier();
  }

  // ==========================================
  // DEBUG MODE FOR PLACEMENT
  // ==========================================
  /// Set to true to enable debug placement mode at startup
  static const bool debugObstaclePlacementEnabled = false;

  /// Runtime toggle for debug panel visibility
  static bool showDebugPanel = debugObstaclePlacementEnabled;

  /// Tracks if game has already started (survives hot reload)
  static bool _hasStartedOnce = false;

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

  /// Callback to notify UI when cinematic mode changes (ending video)
  void Function(bool cinematic)? onCinematicModeChanged;

  /// Callback to notify UI when full-screen overlays are shown/hidden
  void Function(bool hasOverlay)? onOverlayChanged;

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

    // Snow effect disabled for performance on mobile devices
    // (10,000 particles with gradient shaders was too heavy)
    // await world.add(SnowEffectFactory.createForGame(this));

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

    // Create floating joystick for positional mode
    floatingJoystick = FloatingJoystick();
    await world.add(floatingJoystick);

    // Create player (pass both joysticks)
    player = BabyPlayer(joystick: joystick, floatingJoystick: floatingJoystick);
    await world.add(player);

    // Create camera anchor (invisible component that camera follows)
    _cameraAnchor = PositionComponent(position: player.position.clone());
    await world.add(_cameraAnchor);

    // Calculate total memories for the current phase (across all levels)
    _calculateTotalMemoriesForPhase();

    // Add fog of war effect
    await world.add(FogOfWar());

    // Set up camera to follow the anchor (not player directly)
    camera.follow(_cameraAnchor, maxSpeed: 300, snap: true);

    // Add joystick to camera viewport (HUD)
    camera.viewport.add(joystick);

    // Set initial joystick visibility based on control mode
    _updateJoystickVisibility();

    // On web: Show start screen first (requires user interaction to unlock audio)
    // On mobile: Load level immediately and start playing
    // Skip start screen on hot reload (if game has already started)
    if (kIsWeb && !_hasStartedOnce) {
      showStartScreen();
    } else {
      await _loadLevel(currentLevel);
      state = GameState.exploring;
      _hasStartedOnce = true;
    }

    if (debugObstaclePlacementEnabled) {
      debugPrint('=== DEBUG PLACEMENT MODE ===');
      debugPrint('Press M to toggle between OBSTACLE and MEMORY mode');
      debugPrint('OBSTACLE: SPACE to mark corners, creates rectangle');
      debugPrint('MEMORY: SPACE to place memory point');
      debugPrint('Press C to cancel current placement');
      debugPrint('Press P to print all placed items');
      debugPrint('Press L to switch levels (debug)');
      debugPrint('Press G to toggle phase (crawling/walking)');
      debugPrint('Press U to toggle player collision');
      debugPrint('Press B to collect all memories except closest');
      debugPrint('============================');
    }
  }

  /// Calculate total memories across all levels for current phase (excluding level triggers)
  void _calculateTotalMemoriesForPhase() {
    resetPhaseMemoryCount();

    // Count memories from HouseMap (main floor)
    final houseMemories = HouseMap.getMemoryDataStatic()
        .where((m) => m.phase == currentPhase && m.levelTrigger == null)
        .length;

    // Count memories from UpstairsMap
    final upstairsMemories = UpstairsMap.getMemoryDataStatic()
        .where((m) => m.phase == currentPhase && m.levelTrigger == null)
        .length;

    _totalMemoriesInPhase = houseMemories + upstairsMemories;
    debugPrint('Phase ${currentPhase.name} has $_totalMemoriesInPhase collectible memories ($houseMemories main floor + $upstairsMemories upstairs)');
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Update camera zoom when screen size changes (e.g., rotation, window resize)
    if (currentMap != null) {
      camera.viewfinder.zoom = _getResponsiveZoom(currentLevel);
    }
  }

  /// Load a specific level
  Future<void> _loadLevel(LevelId levelId) async {
    // Clear any zone music and SFX zones from the previous level
    AudioManager().clearZoneMusic();
    AudioManager().clearSfxZones();

    // Reset memory sprite bag for fresh distribution
    MemorySpriteTypes.resetBag();

    // Remove current map if exists
    if (currentMap != null) {
      currentMap!.removeFromParent();
      currentMap = null;
    }

    // Create and add the new map, set level-specific ambient music
    switch (levelId) {
      case LevelId.mainFloor:
        currentMap = HouseMap();
        camera.viewfinder.zoom = _getResponsiveZoom(LevelId.mainFloor);
        // Set spawn position based on context
        // Note: currentLevel still holds the OLD level at this point
        if (_isFirstLoad) {
          player.position = Vector2(417, 219); // First game load position
        } else if (currentLevel == LevelId.upstairsNursery) {
          player.position = Vector2(756, 543); // Coming from upstairs
        } else {
          player.position = Vector2(417, 219); // Default to first load position
        }
        player.scale = Vector2.all(1.0); // Normal size for large house
        await AudioManager().switchAmbientMusic(AudioManager.mainFloorAmbient);
        break;
      case LevelId.upstairsNursery:
        currentMap = UpstairsMap();
        camera.viewfinder.zoom = _getResponsiveZoom(LevelId.upstairsNursery);
        player.position = Vector2(1334, 800); // Near the exit door
        player.scale = Vector2.all(2.0); // Larger baby for small room
        await AudioManager().switchAmbientMusic(AudioManager.upstairsAmbient);
        break;
    }

    await world.add(currentMap!);

    // Track level transitions
    _previousLevel = currentLevel;
    currentLevel = levelId;
    _isFirstLoad = false;

    debugPrint('Loaded level: $levelId (previous: $_previousLevel, firstLoad: $_isFirstLoad)');
  }

  /// Switch to a different level
  Future<void> switchToLevel(LevelId levelId) async {
    if (levelId == currentLevel) return;

    state = GameState.loading;
    await _loadLevel(levelId);

    // Fallback check: ensure phase transition happens if all memories collected
    _checkPhaseTransitionFallback();

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

  /// Fallback check to ensure phase transition happens if all memories are collected
  /// This catches edge cases where the normal trigger might have been missed
  void _checkPhaseTransitionFallback() {
    if (_memoriesCollectedInPhase >= _totalMemoriesInPhase && _totalMemoriesInPhase > 0) {
      debugPrint('Fallback check: Phase ${currentPhase.name} complete! ($_memoriesCollectedInPhase/$_totalMemoriesInPhase)');
      // Schedule the phase complete for next frame to avoid interrupting level load
      Future.microtask(() {
        if (state == GameState.exploring) {
          _onPhaseComplete();
        }
      });
    }
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
    _collectedMemories.clear();
    onMemoriesCollectedChanged?.call(List.unmodifiable(_collectedMemories));

    // Calculate total memories for the new phase
    _calculateTotalMemoriesForPhase();

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

  /// Toggle player collision on/off (for debug)
  void togglePlayerCollision() {
    player.collisionEnabled = !player.collisionEnabled;
    debugPrint('Player collision: ${player.collisionEnabled ? 'ON' : 'OFF'}');
  }

  /// Debug: Collect all memories for current phase (triggers phase transition)
  void debugCollectAllMemories() {
    if (currentMap == null) return;

    // Find ALL MemoryItem components for debugging
    final allMemories = currentMap!.children.whereType<MemoryItem>().toList();
    debugPrint('Debug: Found ${allMemories.length} total MemoryItem components');
    for (final m in allMemories) {
      debugPrint('  - ${m.memory.caption}: collected=${m.isCollected}, triggersLevel=${m.memory.triggersLevel}');
    }

    // Find all uncollected MemoryItem components in the current map (excluding level triggers)
    final memories = allMemories
        .where((m) => !m.isCollected && !m.memory.triggersLevel)
        .toList();

    if (memories.isEmpty) {
      debugPrint('No uncollected memories found in current level');
      return;
    }

    // Collect all memories silently (no overlay)
    int collected = 0;
    for (final memory in memories) {
      memory.collectSilently();
      collected++;
    }

    debugPrint('Debug: Collected $collected memories from current level');
  }

  /// Silently collect a memory (for debug) - tracks it without showing overlay
  void collectMemorySilently(Memory memory) {
    _onMemoryCollected(memory);
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
    // Update player position for SFX distance calculations
    AudioManager().updatePlayerPosition(player.position.x, player.position.y);

    // Update audio manager (handles music fading and SFX zones)
    AudioManager().update(dt);

    // Only update game logic when exploring
    if (state == GameState.exploring) {
      super.update(dt);

      // Update camera anchor to follow player's smooth camera target
      _cameraAnchor.position = player.cameraTarget;

      // Update which memory is highlighted (nearest within threshold)
      _updateNearestMemoryHighlight();

      // Update obstacle preview if placing
      if (showDebugPanel) {
        updatePreview();
      }
    }

    // Update keyboard direction for player
    _updateKeyboardDirection();
  }

  /// Movement keys for WASD and arrows
  static final _movementKeys = {
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyA,
    LogicalKeyboardKey.keyS,
    LogicalKeyboardKey.keyD,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
  };

  /// Update player keyboard direction based on pressed keys
  void _updateKeyboardDirection() {
    final direction = Vector2.zero();

    // Up
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y -= 1;
    }
    // Down
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y += 1;
    }
    // Left
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x -= 1;
    }
    // Right
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x += 1;
    }

    player.keyboardDirection = direction;
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Unlock audio on first key press (required for web)
    if (event is KeyDownEvent) {
      AudioManager().unlockAudio();
    }

    // Track movement keys
    if (_movementKeys.contains(event.logicalKey)) {
      if (event is KeyDownEvent) {
        _pressedKeys.add(event.logicalKey);
      } else if (event is KeyUpEvent) {
        _pressedKeys.remove(event.logicalKey);
      }
      return KeyEventResult.handled;
    }

    // Debug keys only on key down
    if (event is KeyDownEvent) {
      // Backtick toggles debug panel
      if (event.logicalKey == LogicalKeyboardKey.backquote) {
        toggleDebugPanel();
        return KeyEventResult.handled;
      }

      // Other debug keys only when panel is visible
      if (showDebugPanel) {
        if (event.logicalKey == LogicalKeyboardKey.space) {
          handleObstaclePlacement();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
          cancelObstaclePlacement();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
          printAllObstacles();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
          togglePlacementMode();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
          toggleLevel();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyG) {
          togglePhase();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
          togglePlayerCollision();
          return KeyEventResult.handled;
        } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
          debugCollectAllMemories();
          return KeyEventResult.handled;
        }
      } else {
        // Debug panel is closed - spacebar triggers nearby memory
        if (event.logicalKey == LogicalKeyboardKey.space) {
          if (state == GameState.exploring && _highlightedMemory != null) {
            triggerMemory(_highlightedMemory!.memory);
            return KeyEventResult.handled;
          }
        }
      }
    }

    return KeyEventResult.ignored;
  }

  /// Toggles the debug panel visibility
  void toggleDebugPanel() {
    showDebugPanel = !showDebugPanel;
    debugPrint('Debug panel: ${showDebugPanel ? "ON" : "OFF"}, callback: ${onDebugPanelToggled != null}');
    onDebugPanelToggled?.call(showDebugPanel);
  }

  /// Toggles between joystick and positional control modes
  void toggleControlMode() {
    _controlMode = _controlMode == MovementControlMode.joystick
        ? MovementControlMode.positional
        : MovementControlMode.joystick;
    _updateJoystickVisibility();
    debugPrint('Control mode: ${_controlMode.name}');
  }

  /// Sets the control mode directly
  void setControlMode(MovementControlMode mode) {
    if (_controlMode == mode) return;
    _controlMode = mode;
    _updateJoystickVisibility();
    debugPrint('Control mode set to: ${_controlMode.name}');
  }

  /// Paints for joystick visibility control
  Paint? _joystickKnobPaint;
  Paint? _joystickBackgroundPaint;

  /// Updates joystick visibility based on control mode
  void _updateJoystickVisibility() {
    // Cache original paints on first call
    _joystickKnobPaint ??= Paint()..color = const Color(0xAAD4A574);
    _joystickBackgroundPaint ??= Paint()..color = const Color(0x44D4A574);

    // Show/hide fixed joystick by changing paint alpha
    if (_controlMode == MovementControlMode.joystick) {
      (joystick.knob as CircleComponent).paint = _joystickKnobPaint!;
      (joystick.background as CircleComponent).paint = _joystickBackgroundPaint!;
    } else {
      // Make fully transparent
      (joystick.knob as CircleComponent).paint = Paint()..color = const Color(0x00000000);
      (joystick.background as CircleComponent).paint = Paint()..color = const Color(0x00000000);
    }
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

    // Handle endgame trigger specially
    if (memory.isEndgameTrigger) {
      // Check if all walking phase memories are collected (excluding endgame trigger itself)
      final allMemoriesCollected = _memoriesCollectedInPhase >= _totalMemoriesInPhase;

      if (allMemoriesCollected) {
        overlayType = OverlayType.gameComplete;
        debugPrint('Endgame triggered! All memories collected.');
      } else {
        overlayType = OverlayType.endgameNotReady;
        debugPrint('Endgame not ready: $_memoriesCollectedInPhase/$_totalMemoriesInPhase memories collected');
      }
    } else {
      overlayType = OverlayType.memory;
    }

    state = GameState.viewingMemory;
    overlays.add('polaroid');
    onOverlayChanged?.call(true);
  }

  /// Resumes the game after viewing a memory (and track collection)
  void resumeGame() {
    // Track the collected memory
    if (currentMemory != null) {
      _onMemoryCollected(currentMemory!);
    }

    overlays.remove('polaroid');
    onOverlayChanged?.call(false);
    currentMemory = null;
    state = GameState.exploring;
  }

  /// Cancels the overlay without collecting the memory
  void cancelOverlay() {
    overlays.remove('polaroid');
    onOverlayChanged?.call(false);
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

        // Only count memories that aren't level triggers (matching _totalMemoriesInPhase calculation)
        // Level-trigger memories don't count towards phase progress
        final countsTowardsPhase = !memory.triggersLevel;
        if (countsTowardsPhase) {
          _memoriesCollectedInPhase++;
        }
        debugPrint('Memory collected: $_memoriesCollectedInPhase/$_totalMemoriesInPhase in ${currentPhase.name} phase (countsTowardsPhase: $countsTowardsPhase)');

        // Track collected memory with sprite type for HUD (all memories, not just countable ones)
        final spriteIndex = MemorySpriteTypes.getSpriteIndexForMemory(memory.stylizedPhotoPath);
        if (spriteIndex != null) {
          _collectedMemories.add(CollectedMemoryInfo(
            memoryKey: memory.stylizedPhotoPath,
            spriteTypeIndex: spriteIndex,
            caption: memory.caption,
          ));
          onMemoriesCollectedChanged?.call(List.unmodifiable(_collectedMemories));
        }

        // Check if all memories in this phase are collected
        // Only trigger phase complete for non-level-trigger memories (player is about to switch levels otherwise)
        if (countsTowardsPhase && _memoriesCollectedInPhase >= _totalMemoriesInPhase) {
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
    onOverlayChanged?.call(true);
  }

  /// Shows the game complete overlay
  void showGameCompleteOverlay() {
    overlayType = OverlayType.gameComplete;
    state = GameState.viewingMemory;
    overlays.add('polaroid');
    onOverlayChanged?.call(true);
  }

  /// Shows the settings menu overlay
  void showSettings() {
    overlays.add('settings');
    onOverlayChanged?.call(true);
    // Don't change game state - allow game to continue in background
  }

  /// Hides the settings menu overlay
  void hideSettings() {
    overlays.remove('settings');
    onOverlayChanged?.call(false);
  }

  /// Shows the start screen overlay
  void showStartScreen() {
    overlays.add('startScreen');
  }

  /// Hides the start screen and starts the game
  Future<void> hideStartScreen() async {
    overlays.remove('startScreen');

    // On web, level wasn't loaded yet - load it now after user interaction
    if (kIsWeb && currentMap == null) {
      await _loadLevel(currentLevel);
    }

    // Mark that game has started (survives hot reload)
    _hasStartedOnce = true;

    // Game is now ready to play
    state = GameState.exploring;
  }

  /// Transition to a new game phase
  Future<void> transitionToPhase(GamePhase newPhase) async {
    if (newPhase == currentPhase) return;

    currentPhase = newPhase;
    _memoriesCollectedInPhase = 0;
    _collectedMemoryKeys.clear();
    _collectedMemories.clear();
    onMemoriesCollectedChanged?.call(List.unmodifiable(_collectedMemories));

    // Calculate total memories for the new phase
    _calculateTotalMemoriesForPhase();

    // Update player sprite for walking phase
    if (newPhase == GamePhase.walking) {
      await player.switchToWalking();
    }

    // Reload current level to show new phase memories
    await _loadLevel(currentLevel);

    onPhaseChanged?.call(newPhase);
    debugPrint('Transitioned to ${newPhase.name} phase');
  }

  /// Add to the total memory count for the current phase (called by maps)
  /// This accumulates across levels. Call resetPhaseMemoryCount before loading levels.
  void addPhaseMemoryCount(int count) {
    _totalMemoriesInPhase += count;
    debugPrint('Phase ${currentPhase.name} now has $_totalMemoriesInPhase total memories');
  }

  /// Reset the phase memory count (call before loading a new phase)
  void resetPhaseMemoryCount() {
    _totalMemoriesInPhase = 0;
  }

  /// Check if a memory is already collected (by its key)
  bool isMemoryCollected(String stylizedPhotoPath, GamePhase phase) {
    final memoryKey = '${stylizedPhotoPath}_${phase.name}';
    return _collectedMemoryKeys.contains(memoryKey);
  }

  /// Legacy method for backwards compatibility
  @Deprecated('Use addPhaseMemoryCount instead')
  void setPhaseMemoryCount(int count) {
    _totalMemoriesInPhase = count;
    debugPrint('Phase ${currentPhase.name} has $count memories');
  }

  /// Get memories collected progress
  int get memoriesCollected => _memoriesCollectedInPhase;
  int get totalMemories => _totalMemoriesInPhase;

  /// Get list of collected memories for HUD display
  List<CollectedMemoryInfo> get collectedMemories => List.unmodifiable(_collectedMemories);

  /// Get the direction (angle in radians) to the nearest uncollected memory
  /// Returns null if no uncollected memories exist on the current level
  /// Angle is 0 = up, positive = clockwise (for Transform.rotate in Flutter)
  double? getDirectionToNearestMemory() {
    if (currentMap == null) return null;

    // Find all uncollected memory items on current level
    // Exclude: level triggers, endgame triggers, and already collected
    final memories = currentMap!.children
        .whereType<MemoryItem>()
        .where((m) =>
            !m.isCollected &&
            !m.memory.triggersLevel &&
            !m.memory.isEndgameTrigger &&
            m.memory.phase == currentPhase)
        .toList();

    if (memories.isEmpty) return null;

    // Get fresh player position
    final playerPos = player.position.clone();

    // Find the nearest one
    MemoryItem? nearest;
    double nearestDistance = double.infinity;

    for (final memory in memories) {
      final distance = playerPos.distanceTo(memory.position);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = memory;
      }
    }

    if (nearest == null) return null;

    // Calculate angle from player to memory
    // In game coords: x increases right, y increases down
    // atan2(dy, dx) gives angle from positive x-axis
    // We want: 0 = up, positive = clockwise
    final dx = nearest.position.x - playerPos.x;
    final dy = nearest.position.y - playerPos.y;

    // atan2 returns: 0 = right, π/2 = down, π = left, -π/2 = up
    // We want: 0 = up, π/2 = right, π = down, -π/2 = left
    // So add π/2 to rotate the reference frame
    return atan2(dy, dx) + (pi / 2);
  }

  /// Get the distance to the nearest uncollected memory (for UI feedback)
  double? getDistanceToNearestMemory() {
    if (currentMap == null) return null;

    final memories = currentMap!.children
        .whereType<MemoryItem>()
        .where((m) =>
            !m.isCollected &&
            !m.memory.triggersLevel &&
            !m.memory.isEndgameTrigger &&
            m.memory.phase == currentPhase)
        .toList();

    if (memories.isEmpty) return null;

    final playerPos = player.position;
    double nearestDistance = double.infinity;
    for (final memory in memories) {
      final distance = playerPos.distanceTo(memory.position);
      if (distance < nearestDistance) {
        nearestDistance = distance;
      }
    }

    return nearestDistance;
  }

  /// Updates which memory is highlighted based on player proximity
  void _updateNearestMemoryHighlight() {
    if (currentMap == null) return;

    // Calculate threshold based on level
    final threshold = currentLevel == LevelId.upstairsNursery
        ? _highlightThreshold * _highlightThresholdUpstairsMultiplier
        : _highlightThreshold;

    // Find all eligible memories (not collected, not triggers, current phase)
    final memories = currentMap!.children
        .whereType<MemoryItem>()
        .where((m) =>
            !m.isCollected &&
            !m.memory.triggersLevel &&
            !m.memory.isEndgameTrigger &&
            m.memory.phase == currentPhase)
        .toList();

    // Find the nearest memory within threshold
    MemoryItem? nearest;
    double nearestDistance = double.infinity;
    final playerPos = player.position;

    for (final memory in memories) {
      final distance = playerPos.distanceTo(memory.position);
      if (distance < nearestDistance && distance <= threshold) {
        nearestDistance = distance;
        nearest = memory;
      }
    }

    // Update highlighted state
    if (_highlightedMemory != nearest) {
      // Remove highlight from previous memory
      _highlightedMemory?.isHighlighted = false;

      // Add highlight to new nearest memory
      nearest?.isHighlighted = true;

      _highlightedMemory = nearest;
    }
  }

  /// Starts the ending video sequence
  void startMontage() {
    state = GameState.montage;
    onCinematicModeChanged?.call(true);
    overlays.add('endingVideo');
  }

  /// Hides the ending video overlay
  void hideEndingVideo() {
    overlays.remove('endingVideo');
    onCinematicModeChanged?.call(false);
    state = GameState.complete;
  }
}

