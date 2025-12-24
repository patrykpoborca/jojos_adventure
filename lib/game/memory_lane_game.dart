import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'actors/baby_player.dart';
import 'world/house_map.dart';

/// Game state enumeration
enum GameState {
  loading,
  exploring,
  viewingMemory,
  montage,
  complete,
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

  const Memory({
    required this.stylizedPhotoPath,
    required this.photos,
    required this.date,
    required this.caption,
    this.levelTrigger,
  });

  /// Convenience constructor for single photo memories
  const Memory.single({
    required String photoPath,
    required this.date,
    required this.caption,
    this.levelTrigger,
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

  late final BabyPlayer player;
  late final JoystickComponent joystick;
  late final HouseMap houseMap;

  // ==========================================
  // DEBUG MODE FOR PLACEMENT
  // ==========================================
  /// Set to true to enable debug placement mode
  static const bool debugObstaclePlacement = true;

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

  /// List of placed obstacles (for output)
  final List<String> _placedObstacles = [];

  /// List of placed memories (for output)
  final List<String> _placedMemories = [];

  /// Get current placement mode
  DebugPlacementMode get placementMode => _placementMode;

  @override
  Color backgroundColor() => const Color(0xFFF5EBE0); // Warm cream

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the house map (background)
    houseMap = HouseMap();
    await world.add(houseMap);

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

    // Set up camera to follow player
    camera.follow(player, maxSpeed: 300, snap: true);
    camera.viewfinder.zoom = 0.5; // Adjust to see more of the house

    // Add joystick to camera viewport (HUD)
    camera.viewport.add(joystick);

    // Game is ready
    state = GameState.exploring;

    if (debugObstaclePlacement) {
      debugPrint('=== DEBUG PLACEMENT MODE ===');
      debugPrint('Press M to toggle between OBSTACLE and MEMORY mode');
      debugPrint('OBSTACLE: SPACE to mark corners, creates rectangle');
      debugPrint('MEMORY: SPACE to place memory point');
      debugPrint('Press C to cancel current placement');
      debugPrint('Press P to print all placed items');
      debugPrint('============================');
    }
  }

  @override
  void update(double dt) {
    // Only update game logic when exploring
    if (state == GameState.exploring) {
      super.update(dt);

      // Update obstacle preview if placing
      if (debugObstaclePlacement) {
        updatePreview();
      }
    }
  }

  /// Toggles between obstacle and memory placement modes
  void togglePlacementMode() {
    if (!debugObstaclePlacement) return;

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
    if (!debugObstaclePlacement) return;

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
    state = GameState.viewingMemory;
    overlays.add('polaroid');
  }

  /// Resumes the game after viewing a memory
  void resumeGame() {
    overlays.remove('polaroid');
    currentMemory = null;
    state = GameState.exploring;
  }

  /// Starts the end montage sequence
  void startMontage() {
    state = GameState.montage;
    // TODO: Implement montage sequence
  }
}

