# UI Patterns

**Last Updated**: 2025-12-23

## Overview

Memory Lane uses minimal UI to keep focus on the game and photos. All UI should feel **unobtrusive and intuitive**.

## Core UI Components

### 1. Virtual Joystick

**Purpose**: Movement control for the baby avatar

**Design Specifications**:
- Position: Bottom-left corner (configurable)
- Size: ~120dp diameter
- Opacity: 50% when idle, 80% when active
- Style: Simple circle with inner knob

**Behavior**:
- Appears on touch
- Returns to center on release
- Smooth, responsive movement

```dart
// Flame's built-in joystick configuration
JoystickComponent(
  knob: CircleComponent(radius: 25, paint: knobPaint),
  background: CircleComponent(radius: 60, paint: bgPaint),
  margin: const EdgeInsets.only(left: 40, bottom: 40),
);
```

### 2. Polaroid Overlay

**Purpose**: Display photo memories when Memory Items are triggered

**Design Specifications**:
- Center of screen
- White frame border (~15% of photo width)
- Slight shadow for depth
- Rotation: subtle random tilt (-5 to +5 degrees)

**Content Layout**:
```
┌─────────────────────────────┐
│                             │
│    ┌───────────────────┐    │
│    │                   │    │
│    │      PHOTO        │    │
│    │                   │    │
│    │                   │    │
│    └───────────────────┘    │
│                             │
│    March 15, 2024           │
│    "First smile!"           │
│                             │
│       [ Continue ]          │
│                             │
└─────────────────────────────┘
```

**Typography**:
- Date: Handwritten font, 14sp, secondary color
- Caption: Handwritten font, 18sp, primary color
- Button: Sans-serif, 16sp, bold

### 3. Continue Button

**Purpose**: Dismiss Polaroid and resume gameplay

**Design Specifications**:
- Style: Rounded rectangle or pill shape
- Color: Primary with contrast text
- Size: Minimum 48x48dp touch target
- Position: Bottom of Polaroid, centered

**States**:
- Default: Primary color
- Pressed: Darker shade
- (No disabled state needed)

### 4. Memory Item Indicator

**Purpose**: Draw attention to collectible items

**Design Specifications**:
- Glow/pulse effect around item
- Color: Warm gold
- Animation: Slow pulse (1-2 second cycle)
- Collected state: No glow, slightly faded

### 5. Progress Indicator (Optional)

**Purpose**: Show how many memories have been found

**Design Specifications**:
- Position: Top corner, unobtrusive
- Format: "X / Y" or simple dots
- Visibility: Subtle, not distracting

## Overlay System

Memory Lane uses Flutter's overlay system for UI on top of the game canvas.

### Overlay Registration

```dart
GameWidget(
  game: game,
  overlayBuilderMap: {
    'polaroid': (context, game) => PolaroidOverlay(
      memory: (game as MemoryLaneGame).currentMemory,
      onContinue: () => game.resumeGame(),
    ),
  },
);
```

### Overlay Activation

```dart
// Show overlay
game.overlays.add('polaroid');

// Hide overlay
game.overlays.remove('polaroid');
```

## Animation Guidelines

### Timing

| Animation | Duration | Easing |
|-----------|----------|--------|
| Polaroid appear | 300ms | easeOut |
| Polaroid dismiss | 200ms | easeIn |
| Memory glow pulse | 1500ms | sinusoidal |
| Baby movement | Immediate | linear |

### Principles

1. **Responsive**: UI should feel immediate
2. **Natural**: Animations should feel organic
3. **Subtle**: Don't distract from content
4. **Consistent**: Same patterns throughout

## Touch Targets

All interactive elements must meet minimum sizes:

| Element | Minimum Size |
|---------|-------------|
| Continue Button | 48x48dp |
| Joystick Knob | 50dp diameter |
| Any tappable area | 44x44dp |

## Screen Orientation

**Preferred**: Landscape

The game should:
- Lock to landscape orientation
- Support both left and right landscape
- Adapt joystick position based on handedness (future feature)

## Related Documentation

- [Color System](./color-system.md)
- [Design README](./README.md)
- [Technical Architecture](../technical/README.md)
