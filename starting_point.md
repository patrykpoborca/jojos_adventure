# Project Manifest: "Memory Lane" - A First Year Celebration Game

## 1. Project Overview
**Concept:** A sentimental 2D top-down exploration game to celebrate our baby's first year of life.
**Target Audience:** My wife (a Christmas gift).
**Core Loop:** The player controls a baby avatar crawling through a house layout. The house is populated with "Memory Items" (toys, pacifiers, etc.). When the baby touches an item, the game pauses and displays a specific photo memory from the past year.
**End Condition:** Reaching the Christmas Tree in the living room, which triggers a final montage.

## 2. Technical Stack
* **Framework:** Flutter (Dart)
* **Game Engine:** Flame Engine (latest version)
* **Packages:**
    * `flame` (Core game loop)
    * `flame_audio` (SFX/Music)
    * `google_fonts` (For styling memory text)
* **Platform:** Mobile (Android/iOS) - Portrait or Landscape (preference: Landscape)

## 3. Game Mechanics & Requirements

### A. Movement & Camera
* **Control:** Virtual Joystick (on-screen).
* **Physics:** Top-down 2D. No gravity. Simple collision detection with walls/furniture.
* **Camera:** The camera must smoothly follow the player (Baby) as they move through the map.
* **Boundaries:** The player cannot leave the "House" area.

### B. Interaction System (The "Memory Trigger")
* **Entities:** "Memory Items" placed at specific coordinates.
* **Trigger:** When the Player hitbox overlaps with a Memory Item hitbox:
    1.  **Pause** the game engine.
    2.  **Play** a sound effect (e.g., a giggle or chime).
    3.  **Open Overlay:** Trigger a standard Flutter UI Overlay.
    4.  **Consumable:** Once viewed, the item disappears (or changes state) so it cannot be triggered again immediately.

### C. The UI Overlay (The "Polaroid")
* When a memory is triggered, a Flutter Widget overlay appears on top of the game canvas.
* **Visuals:** It should look like a Polaroid photo or a framed picture.
* **Content:** High-res image + Date + Short Caption.
* **Action:** A "Continue" button closes the overlay and resumes the game engine.

## 4. Proposed Architecture
* `lib/main.dart`: Entry point. Sets up `GameWidget` and registers the `overlayBuilderMap`.
* `lib/game/christmas_game.dart`: Main `FlameGame` class. Handles loading assets, adding the player, and managing game state.
* `lib/game/actors/baby_player.dart`: The player class (`SpriteAnimationComponent`). Handles movement logic and collision callbacks.
* `lib/game/world/memory_item.dart`: The interactive objects (`PositionComponent` with `CollisionCallbacks`). Holds the data for *which* photo to show.
* `lib/ui/photo_overlay.dart`: A pure Flutter Widget for displaying the memory.

## 5. Asset Placeholders (For Development)
*Use colored shapes (Rectangles/Circles) for now until assets are ready.*
* `baby_sprite`: Red Circle
* `house_background`: Large Green Rectangle (800x1200)
* `memory_item`: Yellow Box
* `obstacle`: Gray Box (Wall)

## 6. Implementation Phases (Kickoff Plan)
1.  **Phase 1 (Scaffold):** Initialize Flutter + Flame, set up the game loop, and render the background.
2.  **Phase 2 (Movement):** Implement the Virtual Joystick and Camera Follow logic.
3.  **Phase 3 (Triggers):** Create the `MemoryItem` class and basic collision detection.
4.  **Phase 4 (UI Integration):** Connect the collision event to the Flutter Overlay system to show a dummy photo.
