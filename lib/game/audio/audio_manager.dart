import 'dart:math' as math;

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Manages music playback with smooth volume transitions
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  /// Default ambient music files per level
  static const String mainFloorAmbient = 'chillhome_trim_a.mp3';
  static const String upstairsAmbient = 'nursery_trim_a.mp3';

  static const String _defaultZoneId = '_default_ambient';

  /// Currently playing ambient music file
  String? _currentAmbientFile;

  /// Currently playing music tracks (by zone ID)
  final Map<String, _MusicTrack> _activeTracks = {};

  /// Target volumes for each zone (0.0 to 1.0)
  final Map<String, double> _targetVolumes = {};

  /// Set of currently active zones (excluding default)
  final Set<String> _activeZones = {};

  /// Active SFX zone tracks (by zone ID)
  final Map<String, _SfxTrack> _sfxTracks = {};

  /// Player position (updated each frame for SFX distance calculation)
  double _playerX = 0;
  double _playerY = 0;

  /// Volume ramp speed (per second)
  static const double volumeRampSpeed = 0.5;

  /// Default ambient volume
  static const double defaultAmbientVolume = 0.6;

  /// Master volume
  double _masterVolume = 0.7;
  double get masterVolume => _masterVolume;
  set masterVolume(double value) {
    _masterVolume = value.clamp(0.0, 1.0);
  }

  /// Music volume multiplier (applied on top of master)
  double _musicVolume = 1.0;
  double get musicVolume => _musicVolume;
  set musicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
  }

  /// SFX volume multiplier (applied on top of master)
  double _sfxVolume = 1.0;
  double get sfxVolume => _sfxVolume;
  set sfxVolume(double value) {
    _sfxVolume = value.clamp(0.0, 1.0);
  }

  /// Whether audio is enabled
  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      stopAll();
    }
  }

  /// Start ambient music with the specified file
  Future<void> startAmbientMusic([String musicFile = mainFloorAmbient]) async {
    if (!_enabled) return;

    // Already playing this file
    if (_activeTracks.containsKey(_defaultZoneId) && _currentAmbientFile == musicFile) {
      return;
    }

    // Stop existing ambient if different file
    if (_activeTracks.containsKey(_defaultZoneId)) {
      final oldTrack = _activeTracks.remove(_defaultZoneId);
      _targetVolumes.remove(_defaultZoneId);
      oldTrack?.player.stop();
    }

    _currentAmbientFile = musicFile;

    try {
      final player = await FlameAudio.loopLongAudio(
        'music/$musicFile',
        volume: 0.0,
      );

      _activeTracks[_defaultZoneId] = _MusicTrack(
        player: player,
        currentVolume: 0.0,
        maxVolume: defaultAmbientVolume,
      );
      _targetVolumes[_defaultZoneId] = defaultAmbientVolume;

      debugPrint('Started ambient music: $musicFile');
    } catch (e) {
      debugPrint('Error starting ambient music: $e');
    }
  }

  /// Switch to a different ambient music file (for level transitions)
  Future<void> switchAmbientMusic(String musicFile) async {
    if (_currentAmbientFile == musicFile) return;
    await startAmbientMusic(musicFile);
  }

  /// Update the default ambient volume based on active zones
  void _updateAmbientVolume() {
    if (!_activeTracks.containsKey(_defaultZoneId)) return;

    // If any zone is active, fade out ambient; otherwise fade in
    if (_activeZones.isNotEmpty) {
      _targetVolumes[_defaultZoneId] = 0.0;
    } else {
      _targetVolumes[_defaultZoneId] = defaultAmbientVolume;
    }
  }

  /// Start playing music for a zone (will fade in)
  Future<void> playZoneMusic(String zoneId, String musicFile, {double maxVolume = 1.0}) async {
    if (!_enabled) return;

    // Track that we're in this zone
    _activeZones.add(zoneId);
    _updateAmbientVolume();

    // If already playing this zone, just update target volume
    if (_activeTracks.containsKey(zoneId)) {
      _targetVolumes[zoneId] = maxVolume;
      return;
    }

    try {
      // Start the music at 0 volume, looping
      final player = await FlameAudio.loopLongAudio(
        'music/$musicFile',
        volume: 0.0,
      );

      _activeTracks[zoneId] = _MusicTrack(
        player: player,
        currentVolume: 0.0,
        maxVolume: maxVolume,
      );
      _targetVolumes[zoneId] = maxVolume;

      debugPrint('Started music for zone: $zoneId ($musicFile)');
    } catch (e) {
      debugPrint('Error playing music $musicFile: $e');
    }
  }

  /// Start fading out music for a zone
  void fadeOutZone(String zoneId) {
    _activeZones.remove(zoneId);
    _updateAmbientVolume();

    if (_targetVolumes.containsKey(zoneId)) {
      _targetVolumes[zoneId] = 0.0;
    }
  }

  /// Update volume transitions (call each frame)
  void update(double dt) {
    if (!_enabled) return;

    final zonesToRemove = <String>[];

    for (final entry in _activeTracks.entries) {
      final zoneId = entry.key;
      final track = entry.value;
      final targetVolume = _targetVolumes[zoneId] ?? 0.0;

      // Ramp volume towards target
      if (track.currentVolume < targetVolume) {
        track.currentVolume = (track.currentVolume + volumeRampSpeed * dt)
            .clamp(0.0, targetVolume);
      } else if (track.currentVolume > targetVolume) {
        track.currentVolume = (track.currentVolume - volumeRampSpeed * dt)
            .clamp(targetVolume, track.maxVolume);
      }

      // Apply volume (master * music volume)
      final effectiveVolume = track.currentVolume * _masterVolume * _musicVolume;
      track.player.setVolume(effectiveVolume);

      // If fully faded out, mark for removal (but never remove ambient track)
      if (track.currentVolume <= 0.0 && targetVolume <= 0.0 && zoneId != _defaultZoneId) {
        zonesToRemove.add(zoneId);
      }
    }

    // Remove stopped tracks (zone music only, not ambient)
    for (final zoneId in zonesToRemove) {
      _stopZone(zoneId);
    }

    // Update SFX zones based on player distance
    _updateSfxZones(dt);
  }

  /// Stop a specific zone's music
  void _stopZone(String zoneId) {
    final track = _activeTracks.remove(zoneId);
    _targetVolumes.remove(zoneId);
    if (track != null) {
      track.player.stop();
      debugPrint('Stopped music for zone: $zoneId');
    }
  }

  /// Stop all zone music (keeps ambient playing) - call when switching levels
  void clearZoneMusic() {
    final zonesToStop = _activeTracks.keys
        .where((id) => id != _defaultZoneId)
        .toList();

    for (final zoneId in zonesToStop) {
      _stopZone(zoneId);
    }

    _activeZones.clear();
    _updateAmbientVolume();

    debugPrint('Cleared all zone music');
  }

  /// Stop all music immediately (including ambient)
  void stopAll() {
    for (final track in _activeTracks.values) {
      track.player.stop();
    }
    _activeTracks.clear();
    _targetVolumes.clear();
    _activeZones.clear();
    debugPrint('Stopped all music');
  }

  /// Play one-shot music for a memory (doesn't loop, plays on top)
  Future<void> playMemoryMusic(String musicFile, {double volume = 0.8}) async {
    if (!_enabled) return;

    try {
      await FlameAudio.play(
        'music/$musicFile',
        volume: volume * _masterVolume * _musicVolume,
      );
      debugPrint('Playing memory music: $musicFile');
    } catch (e) {
      debugPrint('Error playing memory music $musicFile: $e');
    }
  }

  // ==========================================
  // SFX ZONE MANAGEMENT
  // ==========================================

  /// Update player position for SFX distance calculations
  void updatePlayerPosition(double x, double y) {
    _playerX = x;
    _playerY = y;
  }

  /// Register a looping SFX zone
  Future<void> registerSfxZone({
    required String zoneId,
    required String sfxFile,
    required double x,
    required double y,
    double innerRadius = 50.0,
    double outerRadius = 300.0,
    double maxVolume = 0.8,
    bool loop = true,
  }) async {
    if (!_enabled) return;

    // Already registered
    if (_sfxTracks.containsKey(zoneId)) return;

    try {
      AudioPlayer player;
      if (loop) {
        player = await FlameAudio.loopLongAudio(
          'sfx/$sfxFile',
          volume: 0.0,
        );
      } else {
        // For one-shot, we'll create a player but handle play/stop differently
        player = await FlameAudio.loopLongAudio(
          'sfx/$sfxFile',
          volume: 0.0,
        );
      }

      _sfxTracks[zoneId] = _SfxTrack(
        player: player,
        x: x,
        y: y,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        maxVolume: maxVolume,
        isOneShot: !loop,
      );

      debugPrint('Registered SFX zone: $zoneId ($sfxFile) at ($x, $y)');
    } catch (e) {
      debugPrint('Error registering SFX zone $zoneId: $e');
    }
  }

  /// Remove an SFX zone
  void removeSfxZone(String zoneId) {
    final track = _sfxTracks.remove(zoneId);
    if (track != null) {
      track.player.stop();
      debugPrint('Removed SFX zone: $zoneId');
    }
  }

  /// Clear all SFX zones (call when switching levels)
  void clearSfxZones() {
    for (final track in _sfxTracks.values) {
      track.player.stop();
    }
    _sfxTracks.clear();
    debugPrint('Cleared all SFX zones');
  }

  /// Update SFX volumes based on player distance
  void _updateSfxZones(double dt) {
    for (final entry in _sfxTracks.entries) {
      final track = entry.value;

      // Calculate target volume based on distance
      track.targetVolume = track.calculateTargetVolume(_playerX, _playerY);

      // Handle one-shot SFX
      if (track.isOneShot) {
        final wasInRange = track.wasInRange;
        final isInRange = track.targetVolume > 0;

        if (isInRange && !wasInRange && !track.hasPlayed) {
          // Just entered range, play the sound
          track.hasPlayed = true;
          track.player.seek(Duration.zero);
          track.player.setVolume(track.maxVolume * _masterVolume * _sfxVolume);
          track.currentVolume = track.maxVolume;
        } else if (!isInRange && wasInRange) {
          // Left range, reset for next entry
          track.hasPlayed = false;
          track.player.setVolume(0);
          track.currentVolume = 0;
        }

        track.wasInRange = isInRange;
        continue;
      }

      // Smooth volume ramp for looping SFX
      if (track.currentVolume < track.targetVolume) {
        track.currentVolume = (track.currentVolume + volumeRampSpeed * dt)
            .clamp(0.0, track.targetVolume);
      } else if (track.currentVolume > track.targetVolume) {
        track.currentVolume = (track.currentVolume - volumeRampSpeed * dt)
            .clamp(track.targetVolume, track.maxVolume);
      }

      // Apply volume (master * sfx volume)
      final effectiveVolume = track.currentVolume * _masterVolume * _sfxVolume;
      track.player.setVolume(effectiveVolume);
    }
  }

  /// Dispose of all resources
  void dispose() {
    stopAll();
    clearSfxZones();
  }
}

/// Internal class to track a music player
class _MusicTrack {
  final AudioPlayer player;
  double currentVolume;
  final double maxVolume;

  _MusicTrack({
    required this.player,
    required this.currentVolume,
    required this.maxVolume,
  });
}

/// Internal class to track an SFX zone player
class _SfxTrack {
  final AudioPlayer player;
  final double x;
  final double y;
  final double innerRadius; // Full volume within this radius
  final double outerRadius; // Silent beyond this radius
  final double maxVolume;
  final bool isOneShot; // If true, plays once per zone entry
  double currentVolume;
  double targetVolume;

  // One-shot state tracking
  bool wasInRange = false;
  bool hasPlayed = false;

  _SfxTrack({
    required this.player,
    required this.x,
    required this.y,
    required this.innerRadius,
    required this.outerRadius,
    required this.maxVolume,
    this.isOneShot = false,
  })  : currentVolume = 0.0,
        targetVolume = 0.0;

  /// Calculate target volume based on distance from position
  double calculateTargetVolume(double playerX, double playerY) {
    final dx = playerX - x;
    final dy = playerY - y;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance <= innerRadius) {
      return maxVolume;
    } else if (distance >= outerRadius) {
      return 0.0;
    } else {
      // Linear falloff between inner and outer radius
      final falloffRange = outerRadius - innerRadius;
      final distanceInFalloff = distance - innerRadius;
      final falloffPercent = 1.0 - (distanceInFalloff / falloffRange);
      return maxVolume * falloffPercent;
    }
  }
}
