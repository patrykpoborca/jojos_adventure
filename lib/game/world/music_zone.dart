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

/// A polygon zone that triggers music playback when the player enters
class PolygonMusicZone extends PositionComponent with HasGameReference<MemoryLaneGame> {
  /// Unique identifier for this zone
  final String zoneId;

  /// Music file to play (relative to assets/audio/music/)
  final String musicFile;

  /// Maximum volume for this zone's music (0.0 to 1.0)
  final double maxVolume;

  /// Whether to show debug visualization
  final bool showDebug;

  /// Polygon vertices (in world coordinates)
  final List<Vector2> vertices;

  /// Whether the player is currently in this zone
  bool _playerInZone = false;

  PolygonMusicZone({
    required this.vertices,
    required this.zoneId,
    required this.musicFile,
    this.maxVolume = 1.0,
    this.showDebug = false,
  }) : super(position: Vector2.zero());

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Add debug visualization if enabled
    if (showDebug && vertices.isNotEmpty) {
      add(_PolygonDebugComponent(vertices: vertices));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Check if player is within this polygon zone
    final playerPos = game.player.position;
    final isInZone = _isPointInPolygon(playerPos);

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

  /// Check if a point is inside the polygon using ray casting algorithm
  bool _isPointInPolygon(Vector2 point) {
    if (vertices.length < 3) return false;

    bool inside = false;
    int j = vertices.length - 1;

    for (int i = 0; i < vertices.length; i++) {
      final vi = vertices[i];
      final vj = vertices[j];

      if (((vi.y > point.y) != (vj.y > point.y)) &&
          (point.x < (vj.x - vi.x) * (point.y - vi.y) / (vj.y - vi.y) + vi.x)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  void _onEnterZone() {
    AudioManager().playZoneMusic(zoneId, musicFile, maxVolume: maxVolume);
  }

  void _onExitZone() {
    AudioManager().fadeOutZone(zoneId);
  }
}

/// Debug component to visualize polygon zones
class _PolygonDebugComponent extends PositionComponent {
  final List<Vector2> vertices;

  _PolygonDebugComponent({required this.vertices});

  @override
  void render(Canvas canvas) {
    if (vertices.length < 3) return;

    final path = Path();
    path.moveTo(vertices[0].x, vertices[0].y);
    for (int i = 1; i < vertices.length; i++) {
      path.lineTo(vertices[i].x, vertices[i].y);
    }
    path.close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x33AA00FF)
        ..style = PaintingStyle.fill,
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFAA00FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

/// Data class for defining polygon music zones in maps
class PolygonMusicZoneData {
  final List<Vector2> vertices;
  final String zoneId;
  final String musicFile;
  final double maxVolume;

  const PolygonMusicZoneData({
    required this.vertices,
    required this.zoneId,
    required this.musicFile,
    this.maxVolume = 1.0,
  });

  PolygonMusicZone toMusicZone({bool showDebug = false}) {
    return PolygonMusicZone(
      vertices: vertices,
      zoneId: zoneId,
      musicFile: musicFile,
      maxVolume: maxVolume,
      showDebug: showDebug,
    );
  }
}

/// Data class for defining SFX zones (point-based with distance falloff)
class SfxZoneData {
  /// Position of the sound source
  final double x;
  final double y;

  /// Unique identifier for this SFX zone
  final String zoneId;

  /// SFX file to play (relative to assets/audio/sfx/)
  final String sfxFile;

  /// Radius within which sound is at full volume
  final double innerRadius;

  /// Radius beyond which sound is silent
  final double outerRadius;

  /// Maximum volume (0.0 to 1.0)
  final double maxVolume;

  /// If true, plays once when entering range, resets when leaving
  /// If false, loops continuously with distance-based volume
  final bool oneShot;

  const SfxZoneData({
    required this.x,
    required this.y,
    required this.zoneId,
    required this.sfxFile,
    this.innerRadius = 50.0,
    this.outerRadius = 300.0,
    this.maxVolume = 0.8,
    this.oneShot = false,
  });

  /// Register this SFX zone with the AudioManager
  Future<void> register() async {
    await AudioManager().registerSfxZone(
      zoneId: zoneId,
      sfxFile: sfxFile,
      x: x,
      y: y,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      maxVolume: maxVolume,
      loop: !oneShot,
    );
  }
}
