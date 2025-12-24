# Architecture Overview

**Last Updated**: 2025-12-23

## System Architecture

Memory Lane is a Flutter mobile application using the Flame game engine for 2D gameplay with Flutter widgets for UI overlays.

```
┌─────────────────────────────────────────────────────┐
│                    Flutter App                       │
├─────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────────────┐ │
│  │   GameWidget    │    │    Flutter UI Layer     │ │
│  │                 │    │  (Overlays, Dialogs)    │ │
│  │  ┌───────────┐  │    │                         │ │
│  │  │   Flame   │  │◄──►│  - PolaroidOverlay      │ │
│  │  │   Game    │  │    │  - MontageScreen        │ │
│  │  │   Loop    │  │    │  - (Future UI)          │ │
│  │  └───────────┘  │    │                         │ │
│  └─────────────────┘    └─────────────────────────┘ │
├─────────────────────────────────────────────────────┤
│                   Platform Layer                     │
│              (Android / iOS Native)                  │
└─────────────────────────────────────────────────────┘
```

## Module Structure

### Core Modules

#### `lib/main.dart`
- App entry point
- MaterialApp setup
- GameWidget configuration
- Overlay builder registration

#### `lib/game/memory_lane_game.dart`
- Main `FlameGame` class
- Game state management
- Asset loading
- Component management
- Overlay communication

### Actor Modules

#### `lib/game/actors/baby_player.dart`
- `BabyPlayer` extends `SpriteAnimationComponent`
- Movement logic (joystick input)
- Collision callbacks
- Animation states

### World Modules

#### `lib/game/world/house_map.dart`
- Background rendering
- Obstacle placement
- Room definitions
- Boundary management

#### `lib/game/world/memory_item.dart`
- `MemoryItem` extends `PositionComponent`
- Collision detection (hitbox)
- Memory data (photo, date, caption)
- State management (available/collected)

### UI Modules

#### `lib/ui/polaroid_overlay.dart`
- Pure Flutter widget
- Photo display with frame
- Date and caption rendering
- Continue button action

## Data Flow

### Memory Discovery Flow

```
1. Player Movement
   └── Joystick input → BabyPlayer.update()
                          └── Position change

2. Collision Detection
   └── BabyPlayer hitbox ∩ MemoryItem hitbox
         └── MemoryItem.onCollision()

3. Game State Change
   └── MemoryLaneGame.triggerMemory(memory)
         ├── Pause game loop
         ├── Set currentMemory
         └── overlays.add('polaroid')

4. UI Display
   └── PolaroidOverlay renders with memory data

5. Resume
   └── User taps Continue
         ├── overlays.remove('polaroid')
         ├── Mark item collected
         └── Resume game loop
```

## Key Patterns

### Component-Based Architecture

Flame uses a component tree similar to Flutter's widget tree:

```dart
MemoryLaneGame (FlameGame)
├── HouseMap (Component)
│   ├── Room1 (PositionComponent)
│   └── Room2 (PositionComponent)
├── BabyPlayer (SpriteComponent)
│   └── CircleHitbox
├── MemoryItem1 (PositionComponent)
│   └── RectangleHitbox
├── MemoryItem2 ...
└── JoystickComponent
```

### Game-UI Communication

```dart
// Game → UI: Show overlay
game.overlays.add('polaroid');

// UI → Game: Handle action
onContinue: () {
  final game = context.findGame<MemoryLaneGame>();
  game?.resumeGame();
}
```

### Collision System

```dart
class BabyPlayer extends SpriteComponent
    with CollisionCallbacks {

  @override
  void onCollisionStart(Set<Vector2> points, PositionComponent other) {
    if (other is MemoryItem && other.isAvailable) {
      gameRef.triggerMemory(other.memory);
    }
  }
}
```

## State Management

### Game States

```dart
enum GameState {
  loading,      // Assets loading
  exploring,    // Normal gameplay
  viewingMemory,// Overlay visible
  montage,      // End sequence
  complete,     // Game finished
}
```

### Memory Item States

```dart
enum MemoryItemState {
  available,    // Can be triggered
  viewing,      // Currently being viewed
  collected,    // Already viewed
}
```

## Asset Management

### Asset Loading

```dart
@override
Future<void> onLoad() async {
  // Load images
  await images.loadAll([
    'baby_sprite.png',
    'house_background.png',
    'memory_items.png',
  ]);

  // Load audio
  FlameAudio.bgm.initialize();
  await FlameAudio.audioCache.loadAll([
    'giggle.mp3',
    'chime.mp3',
  ]);
}
```

### Asset Organization

```
assets/
├── images/
│   ├── baby/
│   ├── house/
│   └── items/
├── audio/
│   ├── sfx/
│   └── music/
└── photos/
    └── memories/
```

## Performance Considerations

1. **Lazy Loading**: Load assets as needed per room
2. **Image Optimization**: Compress photos appropriately
3. **Object Pooling**: Reuse particle effects
4. **Efficient Hitboxes**: Simple shapes for collision

## Related Documentation

- [Flame Patterns](./flame-patterns.md)
- [Technical README](./README.md)
- [Feature Standards](../standards/feature-development.md)
