import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Manages music playback with smooth volume transitions
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  /// Default ambient music file
  static const String defaultMusicFile = 'chillhome_trim_a.mp3';
  static const String _defaultZoneId = '_default_ambient';

  /// Currently playing music tracks (by zone ID)
  final Map<String, _MusicTrack> _activeTracks = {};

  /// Target volumes for each zone (0.0 to 1.0)
  final Map<String, double> _targetVolumes = {};

  /// Set of currently active zones (excluding default)
  final Set<String> _activeZones = {};

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

  /// Whether audio is enabled
  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      stopAll();
    }
  }

  /// Start the default ambient music (call once at game start)
  Future<void> startAmbientMusic() async {
    if (!_enabled) return;

    // Already playing
    if (_activeTracks.containsKey(_defaultZoneId)) return;

    try {
      final player = await FlameAudio.loopLongAudio(
        'music/$defaultMusicFile',
        volume: 0.0,
      );

      _activeTracks[_defaultZoneId] = _MusicTrack(
        player: player,
        currentVolume: 0.0,
        maxVolume: defaultAmbientVolume,
      );
      _targetVolumes[_defaultZoneId] = defaultAmbientVolume;

      debugPrint('Started ambient music: $defaultMusicFile');
    } catch (e) {
      debugPrint('Error starting ambient music: $e');
    }
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

      // Apply volume
      final effectiveVolume = track.currentVolume * _masterVolume;
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

  /// Stop all music immediately
  void stopAll() {
    for (final track in _activeTracks.values) {
      track.player.stop();
    }
    _activeTracks.clear();
    _targetVolumes.clear();
    debugPrint('Stopped all music');
  }

  /// Play one-shot music for a memory (doesn't loop, plays on top)
  Future<void> playMemoryMusic(String musicFile, {double volume = 0.8}) async {
    if (!_enabled) return;

    try {
      await FlameAudio.play(
        'music/$musicFile',
        volume: volume * _masterVolume,
      );
      debugPrint('Playing memory music: $musicFile');
    } catch (e) {
      debugPrint('Error playing memory music $musicFile: $e');
    }
  }

  /// Dispose of all resources
  void dispose() {
    stopAll();
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
