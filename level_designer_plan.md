# Level Designer Tool - Comprehensive Plan

## Vision

A visual level design tool for top-down 2D games built with Flutter/Flame, designed to:
1. Enable rapid level creation with layers, zones, and collision data
2. Export to a well-defined schema that Flame can load
3. Support AI-assisted development through semantic naming
4. Serve as educational content for a game development course
5. **Be a forkable starting point** that developers can customize manually or with AI

---

## Repository Structure (Monorepo)

The toolkit lives in a single monorepo with multiple packages, designed for easy forking and customization:

```
flame_game_toolkit/
├── README.md                       # Getting started guide
├── melos.yaml                      # Monorepo management
├── pubspec.yaml                    # Workspace root
│
├── packages/
│   ├── level_schema/               # 📦 Shared schema definitions
│   │   ├── lib/
│   │   │   ├── level_schema.dart   # Barrel export
│   │   │   └── src/
│   │   │       ├── level.dart
│   │   │       ├── layer.dart
│   │   │       ├── zone.dart
│   │   │       ├── collision.dart
│   │   │       ├── trigger.dart
│   │   │       └── serialization/
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   ├── level_designer/             # 🎨 Desktop editor application
│   │   ├── lib/
│   │   ├── assets/                 # Editor UI assets
│   │   ├── test/
│   │   └── pubspec.yaml            # depends on level_schema
│   │
│   └── flame_level_loader/         # 🔥 Flame engine integration
│       ├── lib/
│       │   ├── flame_level_loader.dart
│       │   └── src/
│       │       ├── level_loader.dart
│       │       ├── zone_manager.dart
│       │       └── components/
│       ├── test/
│       └── pubspec.yaml            # depends on level_schema, flame
│
├── apps/
│   └── starter_game/               # 🎮 Template game project
│       ├── lib/
│       │   ├── main.dart
│       │   └── game/
│       ├── assets/
│       │   ├── images/
│       │   ├── audio/
│       │   └── levels/             # Level JSON files go here
│       ├── test/
│       └── pubspec.yaml            # depends on flame_level_loader
│
├── examples/
│   ├── simple_room/                # Minimal example
│   ├── multi_room_house/           # Room snapping example
│   └── memory_lane_style/          # Full game example (like yours)
│
└── docs/
    ├── CUSTOMIZATION.md            # How to tailor for your game
    ├── AI_PROMPTS.md               # Effective prompts for AI customization
    ├── SCHEMA_REFERENCE.md         # Complete schema documentation
    └── course/                     # Course materials
        ├── module_01/
        ├── module_02/
        └── ...
```

### Package Dependencies

```
┌─────────────────┐
│  level_schema   │  ← Pure Dart, no Flutter deps
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌────────┐  ┌──────────────────┐
│ level  │  │ flame_level_     │
│designer│  │ loader           │  ← Depends on Flame
└────────┘  └────────┬─────────┘
                     │
                     ▼
              ┌─────────────┐
              │ starter_game │  ← User's game
              └─────────────┘
```

### Why This Structure?

1. **Fork and Go**: Clone the repo, rename `starter_game`, start building
2. **Schema is King**: `level_schema` is the contract between editor and game
3. **Editor Independence**: Designer can run on desktop while game targets mobile
4. **AI-Friendly**: Each package has clear boundaries AI can understand
5. **Selective Updates**: Pull updates to packages without overwriting your game

---

## Core Concepts

### 1. Layers
Horizontal slices of the map stacked on the z-axis:
- **Background Layer** (z: 0) - Floor tiles, ground textures
- **Object Layer** (z: 1-N) - Furniture, decorations, interactive items
- **Foreground Layer** (z: N+1) - Elements that render above the player
- **Collision Layer** (invisible) - Defines walkable/blocked areas
- **Zone Layer** (invisible) - Semantic regions for AI/scripting

### 2. Rooms/Segments
Modular map pieces that can be:
- Designed independently
- Snapped together on a grid
- Connected via doorways/transitions
- Reused across levels

### 3. Zones
Named semantic regions within a room:
```
living_room/
├── tv_area/
│   ├── tv_stand (collision)
│   └── tv (object)
├── seating_area/
│   ├── couch (collision + object)
│   └── coffee_table (collision + object)
└── walkway (no collision)
```

### 4. Collision Shapes
- **Rectangle** - Most common, axis-aligned
- **Polygon** - For irregular shapes
- **Circle** - For round objects
- **Compound** - Multiple shapes grouped

---

## Schema Design (v1.0)

### File Format
JSON with clear structure, human-readable, AI-parseable.

### Top-Level Schema
```json
{
  "version": "1.0",
  "metadata": {
    "name": "main_floor",
    "description": "The main floor of the house",
    "author": "designer_name",
    "created": "2025-12-26T00:00:00Z",
    "modified": "2025-12-26T00:00:00Z",
    "tags": ["indoor", "house", "main_level"]
  },
  "settings": {
    "gridSize": 32,
    "width": 800,
    "height": 600,
    "backgroundColor": "#1a1a1a"
  },
  "layers": [...],
  "zones": [...],
  "collisions": [...],
  "connections": [...],
  "spawns": [...],
  "triggers": [...]
}
```

### Layer Schema
```json
{
  "id": "layer_background",
  "name": "Background",
  "type": "tile|object|foreground",
  "zIndex": 0,
  "visible": true,
  "locked": false,
  "opacity": 1.0,
  "elements": [
    {
      "id": "floor_tile_001",
      "type": "sprite",
      "asset": "assets/tiles/wood_floor.png",
      "x": 0,
      "y": 0,
      "width": 32,
      "height": 32,
      "rotation": 0,
      "flipX": false,
      "flipY": false,
      "zoneRef": "living_room.floor"
    }
  ]
}
```

### Zone Schema
```json
{
  "id": "zone_living_room",
  "name": "living_room",
  "description": "Main living area with TV and seating",
  "bounds": {
    "x": 100,
    "y": 100,
    "width": 300,
    "height": 250
  },
  "subzones": [
    {
      "id": "zone_tv_area",
      "name": "tv_area",
      "parent": "zone_living_room",
      "bounds": { "x": 100, "y": 100, "width": 150, "height": 100 }
    },
    {
      "id": "zone_seating_area",
      "name": "seating_area",
      "parent": "zone_living_room",
      "bounds": { "x": 100, "y": 200, "width": 150, "height": 150 }
    }
  ],
  "properties": {
    "ambient_sound": "living_room_ambience.mp3",
    "lighting": "warm"
  }
}
```

### Collision Schema
```json
{
  "id": "collision_couch",
  "name": "couch",
  "zoneRef": "living_room.seating_area",
  "shape": {
    "type": "rectangle",
    "x": 120,
    "y": 220,
    "width": 80,
    "height": 40
  },
  "properties": {
    "solid": true,
    "pushable": false,
    "friction": 0.8
  }
}
```

### Connection Schema (Room-to-Room)
```json
{
  "id": "connection_to_kitchen",
  "name": "Kitchen Doorway",
  "type": "doorway|stairs|portal",
  "from": {
    "room": "main_floor",
    "zone": "living_room",
    "bounds": { "x": 400, "y": 150, "width": 32, "height": 64 }
  },
  "to": {
    "room": "kitchen",
    "zone": "entrance",
    "spawnPoint": "from_living_room"
  },
  "transition": {
    "type": "fade|slide|instant",
    "duration": 0.3
  }
}
```

### Spawn Points Schema
```json
{
  "id": "spawn_start",
  "name": "Game Start",
  "x": 150,
  "y": 300,
  "direction": "up",
  "tags": ["player_start", "default"]
}
```

### Trigger Schema
```json
{
  "id": "trigger_memory_photo1",
  "name": "First Photo Memory",
  "zoneRef": "living_room.tv_area",
  "bounds": { "x": 110, "y": 110, "width": 24, "height": 24 },
  "triggerType": "collision|interaction|proximity",
  "action": {
    "type": "show_memory|play_sound|spawn_particle|custom",
    "payload": {
      "memoryId": "photo_first_steps"
    }
  },
  "conditions": {
    "requiresItem": null,
    "oneTime": true
  }
}
```

---

## Getting Started (User Workflow)

### Step 1: Fork & Clone
```bash
# Fork flame_game_toolkit on GitHub, then:
git clone https://github.com/YOUR_USERNAME/flame_game_toolkit.git
cd flame_game_toolkit
```

### Step 2: Setup Monorepo
```bash
# Install melos globally
dart pub global activate melos

# Bootstrap all packages
melos bootstrap
```

### Step 3: Rename Your Game
```bash
# Rename starter_game to your project
mv apps/starter_game apps/my_awesome_game

# Update pubspec.yaml name field
# Update imports as needed
```

### Step 4: Design Levels
```bash
# Run the level designer
cd packages/level_designer
flutter run -d macos  # or windows/linux
```

### Step 5: Build Your Game
```bash
cd apps/my_awesome_game
flutter run
```

### Step 6: Customize with AI
```
"Hey Claude, I want to add a day/night cycle to my game.
The schema is in packages/level_schema and my game is in apps/my_awesome_game.
Add a 'lighting' property to zones that can be 'indoor', 'outdoor_day', 'outdoor_night'."
```

---

## AI Customization Guide

The toolkit is designed for AI-assisted development. Here are effective patterns:

### Schema Extensions
```
PROMPT: "Add a 'destructible' property to collision objects in level_schema.
When true, the game should remove the collision after the player hits it 3 times.
Update flame_level_loader to handle this."

AI understands:
1. Modify packages/level_schema/lib/src/collision.dart
2. Add 'destructible' bool and 'hitPoints' int
3. Update flame_level_loader collision component
4. Schema change propagates cleanly
```

### Game Mechanics
```
PROMPT: "I want NPCs in my game. Add an 'npcs' array to the level schema with
properties: name, sprite, dialog[], patrol_path (list of zone refs).
Create a simple NPC component in flame_level_loader."

AI understands:
1. New schema type in level_schema
2. New component in flame_level_loader
3. How it integrates with existing zone system
```

### Level Designer Features
```
PROMPT: "Add an NPC placement tool to level_designer that lets me:
1. Place NPC spawn points
2. Define patrol paths by clicking zones
3. Edit dialog in a text panel"

AI understands:
1. New tool in level_designer/lib/editor/tools/
2. New panel for dialog editing
3. How it serializes to the schema we defined
```

### Zone-Based Queries (Runtime)
```dart
// In your game code, AI can write:
final kitchen = game.zoneManager.query("house.kitchen");
final stove = kitchen.getObject("stove");

// "Add steam particles above the stove when player enters kitchen"
kitchen.onPlayerEnter = () {
  game.add(SteamParticle(position: stove.position + Vector2(0, -20)));
};
```

### Effective Prompt Patterns

| Goal | Prompt Pattern |
|------|----------------|
| Add schema field | "Add [field] to [type] in level_schema. Update loader to handle it." |
| New game mechanic | "I want [mechanic]. Add schema support, loader component, and example." |
| Editor feature | "Add [tool/panel] to level_designer for [purpose]." |
| Customize starter | "In starter_game, change [X] to [Y]. Keep schema compatibility." |
| Debug/understand | "Explain how [feature] flows from schema → loader → game." |

---

## Level Designer Tool Architecture

### Tech Stack
- **Framework**: Flutter (cross-platform desktop)
- **State Management**: Riverpod
- **Rendering**: Custom painters + Flame (for preview)
- **File I/O**: dart:io for save/load
- **Export**: JSON (primary)

### Core Components

```
packages/level_designer/
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   └── router.dart
│   ├── editor/
│   │   ├── canvas/              # Main editing surface
│   │   │   ├── editor_canvas.dart
│   │   │   ├── grid_painter.dart
│   │   │   ├── layer_renderer.dart
│   │   │   └── selection_handler.dart
│   │   ├── tools/               # Editing tools
│   │   │   ├── tool_manager.dart
│   │   │   ├── select_tool.dart
│   │   │   ├── brush_tool.dart
│   │   │   ├── collision_tool.dart
│   │   │   ├── zone_tool.dart
│   │   │   └── eraser_tool.dart
│   │   ├── panels/              # UI panels
│   │   │   ├── layer_panel.dart
│   │   │   ├── zone_panel.dart
│   │   │   ├── properties_panel.dart
│   │   │   ├── asset_browser.dart
│   │   │   └── minimap_panel.dart
│   │   └── dialogs/
│   │       ├── export_dialog.dart
│   │       ├── room_connector.dart
│   │       └── zone_editor.dart
│   ├── preview/                 # Live game preview
│   │   ├── preview_game.dart
│   │   └── preview_player.dart
│   └── state/
│       ├── providers.dart       # Riverpod providers
│       ├── editor_state.dart
│       ├── level_state.dart
│       └── tool_state.dart
├── assets/
│   ├── icons/                   # Tool icons
│   └── themes/                  # Editor themes
└── pubspec.yaml
    # dependencies:
    #   level_schema:
    #     path: ../level_schema
    #   flame: ^1.x
    #   flutter_riverpod: ^2.x
```

### UI Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ Menu Bar: File | Edit | View | Layer | Zone | Tools | Help      │
├───────────┬─────────────────────────────────────┬───────────────┤
│           │                                     │               │
│  Asset    │                                     │  Properties   │
│  Browser  │         Editor Canvas               │    Panel      │
│           │                                     │               │
│  - Tiles  │         (Grid + Layers)             │  - Name       │
│  - Props  │                                     │  - Position   │
│  - Chars  │                                     │  - Size       │
│           │                                     │  - Zone       │
├───────────┤                                     │  - Collision  │
│           │                                     │               │
│  Layers   │                                     ├───────────────┤
│  Panel    │                                     │   Minimap     │
│           │                                     │               │
│  [+][-]   │                                     │   ┌─────┐     │
│  BG  ○    │                                     │   │     │     │
│  Obj ●    │                                     │   └─────┘     │
│  FG  ○    │                                     │               │
├───────────┼─────────────────────────────────────┴───────────────┤
│ Tool Bar: Select | Brush | Collision | Zone | Eraser | Hand     │
├─────────────────────────────────────────────────────────────────┤
│ Status: Layer: Objects | Zoom: 100% | Grid: 32x32 | (x, y)      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Room Snapping System

### Grid-Based Alignment
- Rooms have defined entry/exit points on edges
- Snapping occurs at grid boundaries
- Visual guides show alignment

### Connection Points
```json
{
  "roomId": "living_room",
  "connectionPoints": [
    {
      "id": "east_door",
      "edge": "east",
      "position": 0.5,  // 50% down the edge
      "width": 64,
      "compatibleWith": ["west_door", "any_door"]
    }
  ]
}
```

### Snap Behavior
1. Drag room near another room's edge
2. Compatible connection points highlight
3. Release to snap into position
4. Connections auto-created in schema

---

## Flame Engine Loader

### Loader Class
```dart
class LevelLoader {
  Future<GameLevel> loadFromJson(String jsonPath) async {
    final json = await rootBundle.loadString(jsonPath);
    final schema = LevelSchema.fromJson(jsonDecode(json));
    return _buildLevel(schema);
  }

  GameLevel _buildLevel(LevelSchema schema) {
    final level = GameLevel(
      name: schema.metadata.name,
      size: Vector2(schema.settings.width, schema.settings.height),
    );

    // Build layers
    for (final layer in schema.layers) {
      level.add(_buildLayer(layer));
    }

    // Build collision
    for (final collision in schema.collisions) {
      level.add(_buildCollision(collision));
    }

    // Build zones (for querying)
    level.zones = _buildZoneTree(schema.zones);

    // Build triggers
    for (final trigger in schema.triggers) {
      level.add(_buildTrigger(trigger));
    }

    return level;
  }
}
```

### Zone Query API
```dart
class ZoneManager {
  /// Find zone containing a point
  Zone? getZoneAt(Vector2 position);

  /// Get all objects in a zone
  List<Component> getObjectsInZone(String zonePath);

  /// Query for AI assistance
  ZoneQuery query(String path);
}

// Usage for AI assistance:
// "Create a particle effect between the couch and tv in the living room"
final couch = zoneManager.query("living_room.seating_area.couch").first;
final tv = zoneManager.query("living_room.tv_area.tv").first;
final midpoint = (couch.position + tv.position) / 2;
level.add(ParticleEffect(position: midpoint));
```

---

## AI-Friendly Features

### Semantic Naming Convention
```
{room_name}.{subzone_name}.{object_name}

Examples:
- living_room.tv_area.tv_stand
- kitchen.cooking_area.stove
- bedroom.bed_area.nightstand
```

### Queryable Schema
```dart
// AI can request:
"What objects are in the living room?"
→ Query: zones.where(parent == "living_room").objects

"Where is the couch?"
→ Query: objects.where(name == "couch").bounds

"What's near the TV?"
→ Query: objects.where(distance(position, tv.position) < 100)
```

### Documentation in Schema
```json
{
  "id": "zone_kitchen",
  "name": "kitchen",
  "description": "Cooking area with stove, fridge, and counter space",
  "ai_hints": {
    "mood": "warm, busy",
    "suggested_particles": ["steam", "cooking_smoke"],
    "suggested_sounds": ["sizzling", "fridge_hum"]
  }
}
```

---

## Implementation Phases

### Phase 1: Monorepo Setup & Schema Foundation
**Goal**: Establish project structure and define the complete schema

Tasks:
- [ ] Create `flame_game_toolkit` repository
- [ ] Setup melos.yaml for monorepo management
- [ ] Create `packages/level_schema` with all types:
  - [ ] `level.dart` - Root level container
  - [ ] `layer.dart` - Layer with elements
  - [ ] `zone.dart` - Semantic regions
  - [ ] `collision.dart` - Collision shapes
  - [ ] `trigger.dart` - Interactive triggers
  - [ ] `connection.dart` - Room-to-room links
  - [ ] `spawn.dart` - Spawn points
- [ ] Implement JSON serialization (json_serializable)
- [ ] Build schema validator
- [ ] Write comprehensive tests
- [ ] Create sample level JSON by hand

Deliverables:
- Working monorepo structure
- `level_schema` package with full types
- JSON schema documentation
- Sample level file

### Phase 2: Flame Loader Package
**Goal**: Load schema into Flame before building editor (validate schema works)

Tasks:
- [ ] Create `packages/flame_level_loader`
- [ ] Implement `LevelLoader` class
- [ ] Create Flame components for each schema type:
  - [ ] `LayerComponent` - renders layer elements
  - [ ] `CollisionComponent` - hitboxes
  - [ ] `TriggerComponent` - interaction areas
  - [ ] `ZoneComponent` - invisible region tracking
- [ ] Implement `ZoneManager` for runtime queries
- [ ] Create `apps/starter_game` with minimal game
- [ ] Test loading sample level JSON

Deliverables:
- `flame_level_loader` package
- Working `starter_game` that loads levels
- Zone query API

### Phase 3: Basic Editor Canvas
**Goal**: Visual canvas with grid and layer display

Tasks:
- [ ] Create `packages/level_designer` Flutter desktop app
- [ ] Setup Riverpod state management
- [ ] Implement zoomable/pannable canvas (InteractiveViewer)
- [ ] Add grid overlay with configurable size
- [ ] Implement layer system (add, remove, reorder, visibility)
- [ ] Create asset browser panel (file system based)
- [ ] Display sprites on canvas

Deliverables:
- Functional canvas with zoom/pan
- Layer panel with basic controls
- Asset browser

### Phase 4: Object Placement & Selection
**Goal**: Place and manipulate objects on canvas

Tasks:
- [ ] Implement select tool (click, box select)
- [ ] Add transform handles (drag, resize, rotate)
- [ ] Implement brush tool (stamp sprites)
- [ ] Add property panel for selected objects
- [ ] Implement undo/redo system (command pattern)
- [ ] Add copy/paste/delete functionality
- [ ] Keyboard shortcuts (Ctrl+Z, Ctrl+C, etc.)

Deliverables:
- Full object manipulation
- Undo/redo stack
- Property editing
- Keyboard shortcuts

### Phase 5: Collision Editor
**Goal**: Draw and edit collision shapes

Tasks:
- [ ] Implement rectangle collision tool
- [ ] Implement polygon collision tool (click to add points)
- [ ] Add collision visualization toggle
- [ ] Link collisions to objects (optional)
- [ ] Assign collisions to zones
- [ ] Export collision data to schema

Deliverables:
- Collision drawing tools
- Collision preview mode
- Collision in exported JSON

### Phase 6: Zone System
**Goal**: Define and manage semantic zones

Tasks:
- [ ] Implement zone drawing tool (rectangle regions)
- [ ] Create zone hierarchy panel (tree view)
- [ ] Add zone-to-object linking (drag & drop)
- [ ] Implement zone naming with path notation
- [ ] Add zone metadata editor (properties, ai_hints)
- [ ] Add zone visualization mode (color overlays)

Deliverables:
- Zone editor tools
- Zone hierarchy management
- Zone metadata editing

### Phase 7: Room System & Snapping
**Goal**: Multi-room level design

Tasks:
- [ ] Implement room concept (save/load individual room files)
- [ ] Add connection points to room edges
- [ ] Create room browser/library panel
- [ ] Implement snap-to-grid for rooms
- [ ] Auto-generate connections on snap
- [ ] Handle z-layer alignment between rooms
- [ ] Export combined level or separate room files

Deliverables:
- Room save/load
- Room snapping system
- Connection management
- Multi-room export

### Phase 8: Live Preview & Integration
**Goal**: Preview levels in editor, polish integration

Tasks:
- [ ] Embed Flame game widget in editor for live preview
- [ ] Sync editor changes to preview in real-time
- [ ] Add play/pause/reset controls
- [ ] Test player movement and collisions
- [ ] Create migration tool from Memory Lane's current format
- [ ] Performance optimization

Deliverables:
- Live preview mode
- Real-time sync
- Migration tooling

### Phase 9: Polish & Course Prep
**Goal**: Production-ready tool and educational content

Tasks:
- [ ] UI/UX polish (consistent styling, dark mode)
- [ ] Complete keyboard shortcut system
- [ ] Add welcome screen with tutorials
- [ ] Write CUSTOMIZATION.md guide
- [ ] Write AI_PROMPTS.md with effective patterns
- [ ] Create `examples/` projects:
  - [ ] `simple_room` - minimal example
  - [ ] `multi_room_house` - room snapping demo
  - [ ] `memory_lane_style` - full game example
- [ ] Record course module videos
- [ ] Create course curriculum

Deliverables:
- Polished application
- Complete documentation
- Example projects
- Course materials

---

## Migration Path (Memory Lane → Toolkit)

### Current State
Memory Lane uses:
- Hardcoded sprite positions in Dart code
- Obstacle data in `obstacle_data.dart`
- Memory items defined in `memory_data.dart`
- Custom `HouseMap` component

### Migration Strategy

1. **Export Current Data to Schema**
   ```dart
   // Create a one-time script to export existing obstacles/memories
   void exportToSchema() {
     final level = LevelSchema(
       metadata: Metadata(name: 'main_floor'),
       layers: [
         // Convert house background to layer
         Layer(id: 'bg', elements: [
           Element(asset: 'house_main_floor.png', x: 0, y: 0),
         ]),
       ],
       collisions: ObstacleData.mainFloorObstacles.map((o) =>
         Collision(
           id: o.name,
           name: o.name,
           shape: Rectangle(x: o.x, y: o.y, width: o.width, height: o.height),
         )
       ).toList(),
       triggers: MemoryData.memories.map((m) =>
         Trigger(
           id: m.key,
           name: m.caption,
           bounds: Bounds(x: m.x, y: m.y, width: 24, height: 24),
           action: Action(type: 'show_memory', payload: {'memoryId': m.key}),
         )
       ).toList(),
     );

     File('main_floor.json').writeAsStringSync(jsonEncode(level.toJson()));
   }
   ```

2. **Replace HouseMap with LevelLoader**
   - Keep game logic (player, camera, overlays)
   - Replace map loading with `LevelLoader.loadFromJson()`
   - Zone queries replace hardcoded position checks

3. **Gradual Enhancement**
   - Add zones to existing levels via editor
   - Enhance triggers with new capabilities
   - Keep game playable throughout migration

---

## Course Structure (Future)

### Module 1: Understanding the Schema
- Why structured level data matters
- JSON schema design principles
- Semantic naming for AI assistance

### Module 2: Building the Canvas
- Flutter CustomPainter deep dive
- Zoom, pan, and coordinate systems
- Layer rendering order

### Module 3: Tool Implementation
- State machines for tools
- Undo/redo patterns
- Selection and manipulation

### Module 4: Collision Systems
- Shape mathematics
- Collision detection theory
- Performance considerations

### Module 5: Zone-Based Design
- Semantic regions in games
- Hierarchical organization
- AI-queryable structures

### Module 6: Flame Integration
- Flame component system
- Loading dynamic content
- Runtime queries

### Module 7: Building Your Game
- Complete walkthrough
- From editor to playable game
- Publishing and sharing

---

## Success Metrics

1. **Usability**: New user can create a simple level in < 30 minutes
2. **Performance**: Handle 1000+ objects without lag
3. **Compatibility**: Export works flawlessly with Flame loader
4. **AI-Ready**: Claude can understand and modify levels via schema
5. **Educational**: Course completion leads to working game

---

## Open Questions

1. **Tiled Integration**: Support importing Tiled TMX files, or stay fully independent?
   - Pro: Leverage existing tilemap ecosystem
   - Con: Added complexity, schema translation needed

2. **Visual Scripting**: Add node-based scripting for complex triggers?
   - Could be Phase 10 stretch goal
   - Useful for non-programmers in the course

3. **Asset Pipeline**: How to handle asset references across packages?
   - Option A: Absolute paths from project root
   - Option B: Asset manifest with aliases
   - Option C: Copy assets into levels folder on export

4. **Collaborative Editing**: Real-time multiplayer editing?
   - Probably out of scope for v1
   - Could be course "advanced module"

5. **Version Control**: Level JSON diffs can be noisy
   - Consider stable key ordering in export
   - Maybe offer "pretty" vs "compact" export modes

6. **Plugin System**: Allow users to add custom tools/components?
   - Increases course value significantly
   - But also increases complexity

7. **Web Editor**: Should level_designer work in browser?
   - Flutter web supports desktop-like apps
   - File I/O more limited on web
   - Could reach more users

---

## Success Metrics

| Metric | Target |
|--------|--------|
| Fork to playable game | < 30 minutes |
| Create simple level in editor | < 15 minutes |
| AI can modify schema successfully | 90% of common prompts |
| Editor performance | 1000+ objects, 60fps |
| Course completion → working game | 80% of students |

---

## Next Steps

1. **Immediate**: Review this plan, identify any gaps
2. **Phase 1 Start**: Create `flame_game_toolkit` repo with monorepo structure
3. **Validate**: Build `level_schema` package, test with hand-written JSON
4. **Prove**: Load JSON in Flame via `flame_level_loader`
5. **Then**: Build editor knowing the schema actually works

---

## Repository Setup Commands

When ready to start Phase 1:

```bash
# Create the toolkit repo
mkdir flame_game_toolkit && cd flame_game_toolkit
git init

# Create monorepo structure
mkdir -p packages/level_schema/lib/src
mkdir -p packages/level_designer/lib
mkdir -p packages/flame_level_loader/lib/src
mkdir -p apps/starter_game/lib
mkdir -p examples
mkdir -p docs/course

# Initialize melos
cat > melos.yaml << 'EOF'
name: flame_game_toolkit
packages:
  - packages/*
  - apps/*
  - examples/*
command:
  bootstrap:
    usePubspecOverrides: true
EOF

# Create root pubspec for workspace
cat > pubspec.yaml << 'EOF'
name: flame_game_toolkit_workspace
publish_to: none

environment:
  sdk: ^3.0.0
EOF

# Bootstrap
dart pub global activate melos
melos bootstrap
```

---

*Document Version: 1.1*
*Last Updated: 2025-12-26*
*Structure: Monorepo with forkable starter game*
