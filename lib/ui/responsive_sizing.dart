import 'package:flutter/material.dart';

/// Utility class for responsive sizing across different device sizes.
///
/// Designed to support phones (landscape ~800-1080px width) and
/// tablets (landscape ~1024-1366px+ width) without breaking the phone experience.
class ResponsiveSizing {
  /// Base reference width for phone in landscape mode
  static const double _baseWidth = 800.0;

  /// Threshold width above which we consider it a tablet
  static const double _tabletThreshold = 1024.0;

  /// Maximum scale factor to prevent things from getting too large
  static const double _maxScaleFactor = 1.5;

  /// Get the current screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get the current screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if the device is a tablet (based on width in landscape)
  static bool isTablet(BuildContext context) {
    return screenWidth(context) >= _tabletThreshold;
  }

  /// Get a scale factor based on screen width.
  /// Returns 1.0 for phones, scales up gradually for tablets.
  static double scaleFactor(BuildContext context) {
    final width = screenWidth(context);
    if (width <= _baseWidth) return 1.0;

    // Gradual scale from 1.0 to max based on width increase
    final scale = 1.0 + ((width - _baseWidth) / _baseWidth) * 0.5;
    return scale.clamp(1.0, _maxScaleFactor);
  }

  /// Scale a font size responsively.
  /// Uses a gentler scaling curve to prevent fonts from becoming too large.
  static double fontSize(BuildContext context, double baseSize) {
    final scale = scaleFactor(context);
    // Use square root for gentler font scaling
    final fontScale = 1.0 + (scale - 1.0) * 0.7;
    return baseSize * fontScale;
  }

  /// Scale spacing/padding values responsively.
  static double spacing(BuildContext context, double baseValue) {
    return baseValue * scaleFactor(context);
  }

  /// Scale icon sizes responsively.
  static double iconSize(BuildContext context, double baseSize) {
    return baseSize * scaleFactor(context);
  }

  /// Scale a dimension (width/height) responsively.
  static double dimension(BuildContext context, double baseValue) {
    return baseValue * scaleFactor(context);
  }

  /// Get responsive EdgeInsets with uniform padding.
  static EdgeInsets paddingAll(BuildContext context, double basePadding) {
    final scaled = spacing(context, basePadding);
    return EdgeInsets.all(scaled);
  }

  /// Get responsive EdgeInsets with symmetric padding.
  static EdgeInsets paddingSymmetric(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: spacing(context, horizontal),
      vertical: spacing(context, vertical),
    );
  }

  /// Get responsive EdgeInsets with custom values for each side.
  static EdgeInsets paddingOnly(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: spacing(context, left),
      top: spacing(context, top),
      right: spacing(context, right),
      bottom: spacing(context, bottom),
    );
  }

  /// Get responsive border radius.
  static BorderRadius borderRadius(BuildContext context, double baseRadius) {
    return BorderRadius.circular(spacing(context, baseRadius));
  }

  /// Get a responsive dialog width that works on both phone and tablet.
  /// On phone: uses most of screen width
  /// On tablet: caps at a reasonable maximum to prevent overly wide dialogs
  static double dialogWidth(BuildContext context, {
    double phoneWidthPercent = 0.85,
    double minWidth = 320,
    double maxWidth = 520,
  }) {
    final width = screenWidth(context);
    final calculated = width * phoneWidthPercent;

    // On tablets, we want dialogs to not be too wide
    if (isTablet(context)) {
      return calculated.clamp(minWidth * scaleFactor(context), maxWidth * scaleFactor(context));
    }

    return calculated.clamp(minWidth, maxWidth);
  }

  /// Get a responsive dialog height.
  static double dialogHeight(BuildContext context, {
    double heightPercent = 0.75,
    double minHeight = 300,
    double maxHeight = 550,
  }) {
    final height = screenHeight(context);
    final calculated = height * heightPercent;

    if (isTablet(context)) {
      return calculated.clamp(minHeight * scaleFactor(context), maxHeight * scaleFactor(context));
    }

    return calculated.clamp(minHeight, maxHeight);
  }

  /// Get responsive corner button size (for X and arrow buttons on dialogs).
  static double cornerButtonSize(BuildContext context) {
    return dimension(context, 44);
  }

  /// Get responsive corner button icon size.
  static double cornerButtonIconSize(BuildContext context) {
    return iconSize(context, 22);
  }

  /// Get responsive positioned offset (for top/left/right/bottom positioning).
  static double positionOffset(BuildContext context, double baseOffset) {
    return spacing(context, baseOffset);
  }
}
