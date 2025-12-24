# Implementation: Memory Item Glow Effect

**Status**: Complete (Example)
**Branch**: feature/memory-item-glow
**Assignee**: AI Agent

## Technical Approach

Implement the glow effect using a combination of:
1. A `GlowDecorator` component that wraps Memory Items
2. Animated opacity for the pulse effect
3. Blur shader for the glow appearance

## Checklist

### Setup
- [x] Create feature branch
- [x] Review Memory Item current implementation
- [x] Review Flame decorator patterns

### Implementation
- [x] Create `GlowEffect` component
- [x] Add pulse animation (1.5s cycle)
- [x] Integrate with Memory Item
- [x] Add color token for glow
- [x] Handle collected state (remove glow)

### Testing
- [x] Unit test for animation timing
- [x] Unit test for state transitions
- [x] Manual testing on device

### Cleanup
- [x] Code review complete
- [x] Documentation updated
- [x] Changelog updated

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `lib/game/effects/glow_effect.dart` | Create | Glow effect component |
| `lib/game/world/memory_item.dart` | Modify | Add glow as child |
| `lib/theme/app_colors.dart` | Modify | Add memoryGlow token |
| `test/game/effects/glow_effect_test.dart` | Create | Unit tests |

## Implementation Details

### GlowEffect Component

```dart
class GlowEffect extends Component with HasGameRef {
  final double cycleDuration;
  final Color glowColor;
  double _elapsed = 0;

  @override
  void update(double dt) {
    _elapsed += dt;
    final progress = (_elapsed % cycleDuration) / cycleDuration;
    final opacity = (sin(progress * 2 * pi) + 1) / 2;
    // Apply opacity to glow paint
  }
}
```

### Memory Item Integration

```dart
class MemoryItem extends PositionComponent {
  late GlowEffect _glowEffect;

  @override
  Future<void> onLoad() async {
    _glowEffect = GlowEffect(
      cycleDuration: 1.5,
      glowColor: AppColors.memoryGlow,
    );
    add(_glowEffect);
  }

  void markCollected() {
    state = MemoryItemState.collected;
    _glowEffect.removeFromParent();
  }
}
```

## Notes

- Tested on Android emulator and physical iOS device
- Performance impact negligible (< 1ms per frame)
- Glow radius of 8-10 pixels works best visually
