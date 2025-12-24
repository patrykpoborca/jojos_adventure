# Development Standards

**Last Updated**: 2025-12-23

This directory contains development standards, templates, and guidelines for Memory Lane.

## Contents

| Document | Description |
|----------|-------------|
| [feature-development.md](./feature-development.md) | Feature development workflow and templates |

## Code Standards

### Dart Style

Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style):

- Use `lowerCamelCase` for variables and functions
- Use `UpperCamelCase` for classes and types
- Use `lowercase_with_underscores` for files
- Prefer `final` over `var` when value won't change

### File Organization

```dart
// 1. Library directive (if applicable)
library memory_lane;

// 2. Imports - grouped and sorted
import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../game/memory_lane_game.dart';

// 3. Part directives (if applicable)

// 4. Code
```

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Files | snake_case | `baby_player.dart` |
| Classes | PascalCase | `BabyPlayer` |
| Variables | camelCase | `currentMemory` |
| Constants | camelCase | `maxSpeed` |
| Private | _prefix | `_internalState` |

## Git Standards

### Branch Naming

```
feature/memory-item-glow
bugfix/collision-detection
refactor/player-movement
```

### Commit Messages

```
feat: Add memory item collision detection
fix: Correct joystick sensitivity
refactor: Extract photo loading logic
docs: Update architecture documentation
```

### Before Committing

1. Run `flutter analyze` - no errors
2. Run `flutter test` - all pass
3. Update relevant changelog
4. Review changes for secrets/credentials

## Testing Standards

### Test File Location

```
test/
├── game/
│   ├── memory_lane_game_test.dart
│   └── actors/
│       └── baby_player_test.dart
└── ui/
    └── polaroid_overlay_test.dart
```

### Test Naming

```dart
void main() {
  group('BabyPlayer', () {
    test('should move when joystick is active', () {
      // ...
    });

    test('should trigger memory on collision', () {
      // ...
    });
  });
}
```

## Documentation Standards

### Code Comments

- Comment "why", not "what"
- Document public APIs with `///`
- Keep comments updated with code

```dart
/// Triggers the memory viewing overlay and pauses gameplay.
///
/// The [memory] parameter must not be null and should contain
/// a valid photo path.
void triggerMemory(Memory memory) {
  // Pause before showing overlay to prevent multiple triggers
  state = GameState.viewingMemory;
  // ...
}
```

### Feature Documentation

Every significant feature should have:
- `feature_description.md` - What and why
- `implementation_todo.md` - Technical checklist
- `changelog.md` - Development history

## Related Documentation

- [Feature Development](./feature-development.md)
- [Technical Architecture](../technical/README.md)
