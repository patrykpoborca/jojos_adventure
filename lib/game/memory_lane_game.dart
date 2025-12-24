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

/// Memory data class representing a photo memory
class Memory {
  final String photoPath;
  final String date;
  final String caption;

  const Memory({
    required this.photoPath,
    required this.date,
    required this.caption,
  });
}

/// Main game class for Memory Lane
class MemoryLaneGame extends FlameGame with HasCollisionDetection {
  GameState state = GameState.loading;
  Memory? currentMemory;

  late final BabyPlayer player;
  late final JoystickComponent joystick;
  late final HouseMap houseMap;

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
  }

  @override
  void update(double dt) {
    // Only update game logic when exploring
    if (state == GameState.exploring) {
      super.update(dt);
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
