# Design Documentation

**Last Updated**: 2025-12-23

This directory contains design system documentation for Memory Lane.

## Contents

| Document | Description |
|----------|-------------|
| [color-system.md](./color-system.md) | Color palette and semantic tokens |
| [ui-patterns.md](./ui-patterns.md) | UI component patterns and guidelines |

## Design Philosophy

Memory Lane should feel **warm, nostalgic, and personal** - like flipping through a cherished photo album. The design should:

1. **Fade into the background** - Let the photos be the star
2. **Feel handmade** - Polaroid frames, soft edges, warm tones
3. **Be intuitive** - No learning curve needed
4. **Support emotion** - Design choices should enhance sentimentality

## Visual Style

### Aesthetic Direction

- **Warm and cozy** - Like a family home at Christmas
- **Nostalgic** - Polaroid/vintage photo feel
- **Playful** - Baby-appropriate, soft colors
- **Clean** - Minimal UI, focus on content

### Key Visual Elements

| Element | Style |
|---------|-------|
| Baby Avatar | Cute, simple, recognizable |
| House | Top-down, warm colors, homey feel |
| Memory Items | Glowing/pulsing to attract attention |
| Polaroid Overlay | Classic white-bordered photo frame |
| Joystick | Semi-transparent, unobtrusive |

## Typography

### Recommended Fonts

- **Headers**: A warm, friendly font (e.g., `Nunito`, `Quicksand`)
- **Captions**: Handwritten-style for memories (e.g., `Caveat`, `Indie Flower`)
- **Body**: Clean sans-serif (e.g., `Open Sans`, `Roboto`)

### Usage

| Context | Font | Size |
|---------|------|------|
| Memory Date | Handwritten | 14sp |
| Memory Caption | Handwritten | 18sp |
| UI Buttons | Sans-serif | 16sp |

## Accessibility

- Touch targets minimum 48x48dp
- Contrast ratio 4.5:1 for text
- No color-only information
- Single-hand operation supported

## Related Documentation

- [Color System](./color-system.md)
- [UI Patterns](./ui-patterns.md)
- [Technical Implementation](../technical/README.md)
