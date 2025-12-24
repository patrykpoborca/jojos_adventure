# Domain Terminology

**Last Updated**: 2025-12-23

> **CRITICAL**: Use these terms consistently across all code, documentation, and communication. Inconsistent terminology leads to bugs and confusion.

## Core Entities

### Player / Baby

- **Baby**: The player-controlled character (avatar)
- **Baby Avatar**: The visual representation of the baby on screen
- **Player**: Reference to the user controlling the baby
- **Do NOT use**: Character, Hero, Protagonist, Sprite (except in technical contexts)

### World / Environment

- **House**: The game world/map - a top-down view of a home
- **Room**: A distinct area within the house (living room, bedroom, etc.)
- **Obstacle**: Impassable objects (walls, furniture) that block movement
- **Boundary**: The edge of the playable area
- **Do NOT use**: Level, Stage, World, Map (use "House" instead)

### Collectibles / Interactions

- **Memory Item**: Interactive objects that trigger photo displays
- **Memory**: A photo with associated date and caption
- **Polaroid**: The UI overlay displaying a memory (visual metaphor)
- **Christmas Tree**: The final goal object, triggers end sequence
- **Do NOT use**: Collectible, Pickup, Power-up, Item (use "Memory Item")

### Game States

- **Exploring**: Active gameplay, baby is moving
- **Viewing Memory**: Game paused, Polaroid overlay visible
- **Montage**: End sequence showing all collected memories
- **Do NOT use**: Playing, Paused (for memory viewing), Cutscene

### UI Elements

- **Joystick**: Virtual on-screen control for movement
- **Polaroid Overlay**: Flutter widget displaying memory photos
- **Continue Button**: Dismisses Polaroid and resumes gameplay
- **Do NOT use**: D-pad, Controller, Modal, Dialog

## Technical Terms

### Flame Engine Specific

- **Component**: Any game object in Flame (SpriteComponent, etc.)
- **GameWidget**: Flutter widget containing the Flame game
- **Overlay**: Flutter UI rendered on top of the game canvas
- **Hitbox**: Collision detection boundary

### Code Naming Conventions

| Concept | Class Name | File Name |
|---------|------------|-----------|
| Main game | `MemoryLaneGame` | `memory_lane_game.dart` |
| Baby player | `BabyPlayer` | `baby_player.dart` |
| Memory item | `MemoryItem` | `memory_item.dart` |
| Photo overlay | `PolaroidOverlay` | `polaroid_overlay.dart` |
| Joystick | `BabyJoystick` | `baby_joystick.dart` |

## Status Enumerations

### MemoryItemState

- `available` - Item can be triggered
- `viewing` - Currently displaying this memory
- `collected` - Already viewed, no longer interactive

### GameState

- `loading` - Assets loading
- `exploring` - Normal gameplay
- `viewingMemory` - Overlay visible
- `montage` - End sequence
- `complete` - Game finished

## Business Processes

### Memory Discovery Flow

1. Baby collides with Memory Item
2. Game state changes to `viewingMemory`
3. Polaroid Overlay appears with photo
4. User taps Continue
5. Memory Item state changes to `collected`
6. Game state returns to `exploring`

### End Game Flow

1. Baby collides with Christmas Tree
2. All memories verified as collected (or skipped)
3. Montage sequence begins
4. All photos displayed in chronological order
5. Game state changes to `complete`

## Glossary Quick Reference

| Term | Definition |
|------|------------|
| Baby | Player-controlled character |
| House | The game world |
| Memory Item | Interactive photo trigger |
| Memory | Photo + date + caption |
| Polaroid | Photo display overlay |
| Montage | End sequence |
| Joystick | Movement control |
