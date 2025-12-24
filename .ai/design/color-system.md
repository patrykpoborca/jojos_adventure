# Color System

**Last Updated**: 2025-12-23

## Design Intent

Colors should evoke **warmth, nostalgia, and comfort** - like a cozy home during the holidays.

## Semantic Colors

### Primary Palette

| Token | Value | Usage |
|-------|-------|-------|
| `primary` | Warm amber/gold | Accents, highlights, Memory Item glow |
| `primaryLight` | Light gold | Hover states, soft highlights |
| `primaryDark` | Deep amber | Pressed states, emphasis |

### Background Colors

| Token | Value | Usage |
|-------|-------|-------|
| `backgroundHouse` | Warm beige/cream | Main game background |
| `backgroundRoom` | Varied by room | Individual room floors |
| `backgroundOverlay` | Semi-transparent dark | Behind Polaroid overlay |

### Text Colors

| Token | Value | Usage |
|-------|-------|-------|
| `textPrimary` | Dark brown/charcoal | Main text, captions |
| `textSecondary` | Medium brown | Dates, secondary info |
| `textOnPrimary` | White/cream | Text on primary color |

### UI Colors

| Token | Value | Usage |
|-------|-------|-------|
| `surface` | Off-white | Polaroid frame, cards |
| `surfaceVariant` | Light cream | Joystick background |
| `border` | Soft brown | Subtle borders |

### Status Colors

| Token | Value | Usage |
|-------|-------|-------|
| `memoryGlow` | Soft gold with bloom | Memory Item highlighting |
| `collected` | Muted/grayed | Already-viewed items |
| `goal` | Festive red/green | Christmas tree area |

## Color Values (Suggested)

```dart
// Primary
static const primary = Color(0xFFD4A574);        // Warm amber
static const primaryLight = Color(0xFFE8C9A0);   // Light gold
static const primaryDark = Color(0xFFB8956A);    // Deep amber

// Backgrounds
static const backgroundHouse = Color(0xFFF5EBE0); // Warm cream
static const backgroundOverlay = Color(0xCC000000); // 80% black

// Text
static const textPrimary = Color(0xFF3C3C3C);    // Charcoal
static const textSecondary = Color(0xFF6B5B4F);  // Warm brown

// Surface
static const surface = Color(0xFFFFFBF7);        // Off-white
static const border = Color(0xFFD4C5B5);         // Soft brown

// Special
static const memoryGlow = Color(0xFFFFD700);     // Gold
static const christmasRed = Color(0xFFC41E3A);   // Festive red
static const christmasGreen = Color(0xFF228B22); // Forest green
```

## Platform Implementation

### Flutter/Dart

```dart
class AppColors {
  static const primary = Color(0xFFD4A574);
  // ... other colors
}

// Usage
Container(
  color: AppColors.primary,
)
```

### Theme Integration

```dart
ThemeData(
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.backgroundHouse,
  // ...
)
```

## WCAG Compliance

- All text on `surface` backgrounds meets 4.5:1 contrast (AA)
- Interactive elements meet 3:1 contrast
- Memory Item glow is decorative, not informational

## Development Phase Colors

During development with placeholder shapes:

| Element | Placeholder Color |
|---------|------------------|
| Baby Avatar | Red circle |
| House Background | Green rectangle |
| Memory Item | Yellow box |
| Obstacle/Wall | Gray box |

These should be replaced with actual assets before release.

## Related Documentation

- [UI Patterns](./ui-patterns.md)
- [Design README](./README.md)
