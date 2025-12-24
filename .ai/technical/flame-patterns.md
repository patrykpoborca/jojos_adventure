# Flame Engine Patterns

**Last Updated**: 2025-12-23

## Overview

Flame is a modular game engine built on Flutter. This document covers patterns and best practices specific to Memory Lane.

## Core Concepts

### FlameGame

The main game class that manages the game loop and component tree.

```dart
class MemoryLaneGame extends FlameGame
    with HasCollisionDetection {

  GameState state = GameState.loading;
  Memory? currentMemory;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load assets, add components
  }

  @override
  void update(double dt) {
    if (state == GameState.exploring) {
      super.update(dt);
    }
  }
}
```

### Components

Everything in Flame is a Component. Key component types:

| Type | Usage |
|------|-------|
| `PositionComponent` | Base for positioned objects |
| `SpriteComponent` | Static image rendering |
| `SpriteAnimationComponent` | Animated sprites |
| `CircleComponent` | Simple circle shape |
| `RectangleComponent` | Simple rectangle shape |

### Component Lifecycle

```dart
class MyComponent extends PositionComponent {
  @override
  Future<void> onLoad() async {
    // Called once when component is added
  }

  @override
  void update(double dt) {
    // Called every frame
  }

  @override
  void render(Canvas canvas) {
    // Custom rendering (usually handled by parent)
  }

  @override
  void onRemove() {
    // Cleanup when removed
  }
}
```

## Movement Pattern

### Joystick Integration

```dart
class BabyPlayer extends SpriteComponent {
  final JoystickComponent joystick;
  final double speed = 200;

  BabyPlayer({required this.joystick});

  @override
  void update(double dt) {
    if (joystick.direction != JoystickDirection.idle) {
      position += joystick.relativeDelta * speed * dt;
    }
  }
}
```

### Camera Follow

```dart
class MemoryLaneGame extends FlameGame {
  late CameraComponent camera;
  late BabyPlayer player;

  @override
  Future<void> onLoad() async {
    player = BabyPlayer();
    camera = CameraComponent(world: world);
    camera.follow(player);

    add(camera);
  }
}
```

## Collision Detection

### Setup

```dart
// Enable collision detection in game
class MemoryLaneGame extends FlameGame
    with HasCollisionDetection {
  // ...
}
```

### Adding Hitboxes

```dart
class BabyPlayer extends SpriteComponent
    with CollisionCallbacks {

  @override
  Future<void> onLoad() async {
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(
    Set<Vector2> points,
    PositionComponent other,
  ) {
    if (other is MemoryItem) {
      // Handle memory collision
    } else if (other is Obstacle) {
      // Handle wall collision
    }
  }
}
```

### Memory Item Collision

```dart
class MemoryItem extends PositionComponent
    with CollisionCallbacks {

  final Memory memory;
  MemoryItemState state = MemoryItemState.available;

  MemoryItem({required this.memory});

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  bool get isAvailable => state == MemoryItemState.available;

  void markCollected() {
    state = MemoryItemState.collected;
    // Update visual appearance
  }
}
```

## Overlay Pattern

### Registering Overlays

```dart
// In main.dart
GameWidget(
  game: game,
  overlayBuilderMap: {
    'polaroid': (context, game) => PolaroidOverlay(
      game: game as MemoryLaneGame,
    ),
    'montage': (context, game) => MontageScreen(
      game: game as MemoryLaneGame,
    ),
  },
  initialActiveOverlays: const [],
);
```

### Showing/Hiding Overlays

```dart
// Show overlay (pauses game if needed)
game.overlays.add('polaroid');

// Hide overlay
game.overlays.remove('polaroid');

// Check if showing
bool isShowing = game.overlays.isActive('polaroid');
```

### Overlay Widget

```dart
class PolaroidOverlay extends StatelessWidget {
  final MemoryLaneGame game;

  const PolaroidOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    final memory = game.currentMemory;
    if (memory == null) return const SizedBox();

    return Center(
      child: Container(
        // Polaroid styling
        child: Column(
          children: [
            Image.asset(memory.photoPath),
            Text(memory.date),
            Text(memory.caption),
            ElevatedButton(
              onPressed: () => game.resumeGame(),
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Audio Pattern

### Setup

```dart
import 'package:flame_audio/flame_audio.dart';

class MemoryLaneGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Preload audio
    await FlameAudio.audioCache.loadAll([
      'sfx/giggle.mp3',
      'sfx/chime.mp3',
    ]);
  }

  void playGiggle() {
    FlameAudio.play('sfx/giggle.mp3');
  }
}
```

### Background Music

```dart
// Start BGM
FlameAudio.bgm.play('music/background.mp3');

// Stop BGM
FlameAudio.bgm.stop();

// Pause/Resume with game
FlameAudio.bgm.pause();
FlameAudio.bgm.resume();
```

## Animation Pattern

### Sprite Animation

```dart
class BabyPlayer extends SpriteAnimationComponent {
  @override
  Future<void> onLoad() async {
    animation = await game.loadSpriteAnimation(
      'baby_crawl.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: 0.15,
        textureSize: Vector2.all(64),
      ),
    );
  }

  void setIdle() {
    animation = idleAnimation;
  }

  void setCrawling() {
    animation = crawlAnimation;
  }
}
```

## Best Practices

### Do

- Use `gameRef` to access the game from components
- Keep components focused and single-purpose
- Use mixins for shared functionality
- Preload assets in `onLoad`
- Handle `onRemove` for cleanup

### Don't

- Don't put UI logic in game components
- Don't block the game loop with heavy operations
- Don't forget to call `super` in lifecycle methods
- Don't create components every frame

## Common Gotchas

1. **Coordinate System**: Origin is top-left, Y increases downward
2. **Anchor Points**: Default anchor is top-left, set to center for rotation
3. **Load Order**: Children added in `onLoad` load after parent
4. **Overlay State**: Overlays persist until explicitly removed

## Related Documentation

- [Architecture Overview](./architecture-overview.md)
- [Technical README](./README.md)
- [Flame Official Docs](https://docs.flame-engine.org/)
