import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import '../memory_lane_game.dart';

/// A rectangular zone that triggers music playback when the player enters
class MusicZone extends PositionComponent with HasGameReference<MemoryLaneGame> {
  /// Unique identifier for this zone
  final String zoneId;

  /// Music file to play (relative to assets/audio/music/)
  final String musicFile;

  /// Maximum volume for this zone's music (0.0 to 1.0)
  final double maxVolume;

  /// Whether to show debug visualization
  final bool showDebug;

  /// Whether the player is currently in this zone
  bool _playerInZone = false;

  MusicZone({
    required Vector2 position,
    required Vector2 size,
    required this.zoneId,
    required this.musicFile,
    this.maxVolume = 1.0,
    this.showDebug = false,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add debug visualization if enabled
    if (showDebug) {
      add(RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.purple.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill,
      ));
      add(RectangleComponent(
        size: size,
        paint: Paint()
          ..color = Colors.purple
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Check if player is within this zone
    final playerPos = game.player.position;
    final zoneRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
    final isInZone = zoneRect.contains(Offset(playerPos.x, playerPos.y));

    if (isInZone && !_playerInZone) {
      // Player entered zone
      _playerInZone = true;
      _onEnterZone();
    } else if (!isInZone && _playerInZone) {
      // Player left zone
      _playerInZone = false;
      _onExitZone();
    }
  }

  void _onEnterZone() {
    AudioManager().playZoneMusic(zoneId, musicFile, maxVolume: maxVolume);
  }

  void _onExitZone() {
    AudioManager().fadeOutZone(zoneId);
  }
}

/// Data class for defining music zones in maps
class MusicZoneData {
  final double x;
  final double y;
  final double width;
  final double height;
  final String zoneId;
  final String musicFile;
  final double maxVolume;

  const MusicZoneData({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.zoneId,
    required this.musicFile,
    this.maxVolume = 1.0,
  });

  MusicZone toMusicZone({bool showDebug = false}) {
    return MusicZone(
      position: Vector2(x, y),
      size: Vector2(width, height),
      zoneId: zoneId,
      musicFile: musicFile,
      maxVolume: maxVolume,
      showDebug: showDebug,
    );
  }
}
