# Memory Lane - AI Assistant Guide

## Project Overview

**Memory Lane** is a sentimental 2D top-down exploration game celebrating a baby's first year of life. It's a Christmas gift for the developer's wife.

**Core Concept**: A baby avatar crawls through a house, discovering Memory Items that reveal photo memories. The goal is to reach the Christmas tree for a final montage.

## Technology Stack

- **Framework**: Flutter (Dart)
- **Game Engine**: Flame Engine
- **Platform**: Mobile (Android/iOS, landscape preferred)
- **Audio**: flame_audio
- **Fonts**: google_fonts

## AI Documentation Structure

Memory Lane uses a centralized `.ai/` directory for all AI-related documentation:

### Quick Navigation

| Directory | Purpose |
|-----------|---------|
| `.ai/product/` | Vision, personas, feature prioritization |
| `.ai/design/` | Colors, typography, component patterns |
| `.ai/technical/` | Architecture, platform guides, Flame patterns |
| `.ai/features/` | Feature descriptions, implementation todos, changelogs |
| `.ai/standards/` | Development standards, templates |
| `.ai/agents/` | Agent configurations and coordination |

### Main Entry Point

**Start here**: `.ai/README.md` - Complete navigation hub with role-based and task-based guides

### Before Starting Any Task

1. **Check Product Context**: `.ai/product/product-vision.md`
2. **Review Domain Terminology**: `.ai/product/domain-terminology.md` (CRITICAL)
3. **Check Design System**: `.ai/design/`
4. **Review Technical Docs**: `.ai/technical/`
5. **Check Feature Specs**: `.ai/features/{feature_name}/`
6. **Create/Update Changelog**: `.ai/features/{feature_name}/changelog.md`

## Critical Domain Terms

Use these terms consistently - see `.ai/product/domain-terminology.md` for complete list:

| Term | Meaning | Don't Use |
|------|---------|-----------|
| Baby | Player character | Hero, Character, Player (for avatar) |
| House | Game world | Level, Stage, Map |
| Memory Item | Interactive collectible | Item, Pickup, Collectible |
| Memory | Photo + date + caption | Photo (alone) |
| Polaroid | Photo display overlay | Modal, Dialog, Popup |
| Joystick | Movement control | D-pad, Controller |

## Project Structure

```
lib/
├── main.dart                 # Entry point, GameWidget setup
├── game/
│   ├── memory_lane_game.dart # Main FlameGame class
│   ├── actors/
│   │   └── baby_player.dart  # Player character
│   └── world/
│       ├── house_map.dart    # Game world
│       └── memory_item.dart  # Interactive items
└── ui/
    └── polaroid_overlay.dart # Photo display widget
```

## Key Patterns

### Flame Game Loop

```dart
class MemoryLaneGame extends FlameGame with HasCollisionDetection {
  // Components are added as children
  // Update loop handles game logic
  // Overlays bridge to Flutter UI
}
```

### Memory Discovery Flow

1. Baby collides with Memory Item
2. Game pauses, sets `currentMemory`
3. Polaroid overlay shown via `overlays.add('polaroid')`
4. User taps Continue
5. Item marked collected, overlay removed, game resumes

### Game-UI Communication

```dart
// Show UI
game.overlays.add('polaroid');

// Hide UI
game.overlays.remove('polaroid');
```

## Development Guidelines

### Do

- Read existing code before modifying
- Use domain terminology consistently
- Update changelogs with every change
- Follow Flame component patterns
- Keep game logic in Flame components
- Keep UI logic in Flutter widgets

### Don't

- Invent new terms without updating terminology doc
- Add features beyond scope (this is a gift, not a product)
- Over-engineer simple solutions
- Skip the changelog updates
- Block the game loop with heavy operations

## File Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables: `camelCase`
- Constants: `camelCase`

## Commands

```bash
# Run the game
flutter run

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for release
flutter build apk  # Android
flutter build ios  # iOS
```

## Implementation Phases

From `starting_point.md`:

1. **Phase 1 (Scaffold)**: Flutter + Flame setup, game loop, background
2. **Phase 2 (Movement)**: Virtual Joystick, Camera Follow
3. **Phase 3 (Triggers)**: MemoryItem class, collision detection
4. **Phase 4 (UI Integration)**: Flutter Overlay system, Polaroid display

## Asset Placeholders

During development:
- Baby: Red Circle
- House Background: Green Rectangle (800x1200)
- Memory Item: Yellow Box
- Obstacle: Gray Box

## Success Criteria

1. Wife enjoys playing through the entire game
2. All photos viewable and recognizable
3. Game runs smoothly without crashes
4. Emotional impact achieved

## Questions?

- Check `.ai/README.md` for navigation
- Review specific docs in `.ai/` subdirectories
- Follow standards in `.ai/standards/feature-development.md`
