import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The game world - a top-down view of the house
class HouseMap extends PositionComponent with HasGameReference {
  late final SpriteComponent backgroundSprite;

  /// The playable area bounds (inside the house)
  /// These values are approximate and should be adjusted based on the actual map
  Rect get playableBounds => Rect.fromLTWH(
        70, // Left margin (garland border)
        50, // Top margin (garland + title)
        mapSize.x - 140, // Width minus borders
        mapSize.y - 100, // Height minus borders
      );

  /// The full size of the map image
  Vector2 get mapSize => backgroundSprite.size;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the background image
    final sprite = await game.loadSprite('house/background_of_level.png');

    backgroundSprite = SpriteComponent(
      sprite: sprite,
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
    );

    add(backgroundSprite);

    // Debug: Add a visual indicator for playable bounds
    // Remove this in production
    _addDebugBounds();
  }

  void _addDebugBounds() {
    // This helps visualize the playable area during development
    // Comment out or remove for final build
    add(
      RectangleComponent(
        position: Vector2(playableBounds.left, playableBounds.top),
        size: Vector2(playableBounds.width, playableBounds.height),
        paint: Paint()
          ..color = Colors.green.withValues(alpha: 0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ),
    );
  }
}
