# Technical Documentation

**Last Updated**: 2025-12-23

This directory contains technical architecture and implementation documentation for Memory Lane.

## Contents

| Document | Description |
|----------|-------------|
| [architecture-overview.md](./architecture-overview.md) | System architecture and module structure |
| [flame-patterns.md](./flame-patterns.md) | Flame engine patterns and best practices |

## Technology Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (Dart) |
| Game Engine | Flame Engine (latest) |
| Audio | flame_audio |
| Fonts | google_fonts |
| Platform | Mobile (Android/iOS) |

## Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flame: ^latest
  flame_audio: ^latest
  google_fonts: ^latest
```

## Project Structure

```
lib/
├── main.dart                 # App entry point, GameWidget setup
├── game/
│   ├── memory_lane_game.dart # Main FlameGame class
│   ├── actors/
│   │   └── baby_player.dart  # Player character
│   └── world/
│       ├── house_map.dart    # Game world/level
│       └── memory_item.dart  # Interactive collectibles
└── ui/
    └── polaroid_overlay.dart # Photo display widget
```

## Quick Start

1. Install Flutter SDK
2. Run `flutter pub get`
3. Run `flutter run` (with device connected)

## Development Guidelines

1. Follow Dart style guide
2. Use Flame's component system
3. Keep game logic in Flame components
4. Keep UI logic in Flutter widgets
5. Use overlays for game/UI communication

## Related Documentation

- [Architecture Overview](./architecture-overview.md)
- [Flame Patterns](./flame-patterns.md)
- [Feature Standards](../standards/feature-development.md)
