# Changelog: Memory Item Glow Effect

All notable changes to this feature.

---

## [2025-12-23] - Feature Complete

### Added
- Final polish on glow appearance
- Documentation complete

### Fixed
- Glow now properly removes on collection

---

## [2025-12-22] - Testing Complete

### Added
- Unit tests for GlowEffect component
- Unit tests for state transitions

### Fixed
- Animation not resetting on component reuse

---

## [2025-12-21] - Core Implementation

### Added
- GlowEffect component with pulse animation
- memoryGlow color token in AppColors
- Integration with MemoryItem component

### Changed
- MemoryItem now uses composition for effects

### Notes
- Settled on 1.5s cycle duration after testing
- Blur radius of 8px provides best visibility

---

## [2025-12-20] - Initial Setup

### Added
- Feature branch created
- Feature description document
- Implementation todo list

### Notes
- Explored three approaches for glow effect:
  1. Custom Paint with blur (selected)
  2. Overlay sprite animation
  3. Shader-based effect
- Chose option 1 for simplicity and performance

---

## Template Usage Notes

This changelog demonstrates:
- Reverse chronological order (newest first)
- Date headers for each work session
- Categorized changes (Added, Changed, Fixed, etc.)
- Notes section for decisions and context
- Clear, concise descriptions

When maintaining your own changelogs:
1. Update with every commit
2. Group related changes
3. Include decision rationale in Notes
4. Link to relevant docs/issues if applicable
