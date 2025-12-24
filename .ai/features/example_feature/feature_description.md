# Feature: Memory Item Glow Effect

**Status**: Complete (Example)
**Priority**: P2 (Medium)
**Created**: 2025-12-23

## Overview

Add a pulsing glow effect to Memory Items to attract player attention and indicate they are interactive collectibles.

## User Stories

### As a player
- I want to easily identify which items I can interact with
- So that I don't miss any memories while exploring

### As the developer
- I want a clear visual indicator for Memory Items
- So that the gameplay is intuitive without explicit tutorials

## Acceptance Criteria

- [x] Memory Items have a visible glow effect
- [x] Glow pulses at a comfortable rhythm (1-2 second cycle)
- [x] Glow color matches design system (warm gold)
- [x] Glow disappears after item is collected
- [x] Effect performs well on target devices
- [x] Effect does not obscure the item itself

## Business Rules

1. Glow must be visible against all house background colors
2. Only available (not collected) items should glow
3. Glow intensity should not cause eye strain

## Constraints

- Must work with Flame's rendering system
- Should not significantly impact frame rate
- Color must use semantic token from design system

## Out of Scope

- Sound effects for the glow
- Different glow colors per item type
- User-configurable glow settings

## Dependencies

- Memory Item base implementation
- Color system tokens defined
- Game rendering pipeline established

## Technical Notes

Consider using:
- Flame's `Decorator` system for effects
- Custom `Paint` with blur effect
- Sprite overlay with animated opacity

## Related Documents

- [Design: Color System](../../design/color-system.md)
- [Technical: Flame Patterns](../../technical/flame-patterns.md)
