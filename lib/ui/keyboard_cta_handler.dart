import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A widget that wraps content and triggers a callback when Enter or Space is pressed.
/// Used to provide keyboard support for CTA buttons in overlays and dialogs.
///
/// Usage:
/// ```dart
/// KeyboardCtaHandler(
///   onCtaPressed: () => _onStartGame(),
///   child: YourOverlayContent(),
/// )
/// ```
class KeyboardCtaHandler extends StatefulWidget {
  /// The callback to invoke when Enter or Space is pressed
  final VoidCallback onCtaPressed;

  /// The child widget to wrap
  final Widget child;

  /// Whether this handler should request focus automatically
  final bool autofocus;

  /// Optional secondary action (e.g., for Escape key)
  final VoidCallback? onSecondaryAction;

  const KeyboardCtaHandler({
    super.key,
    required this.onCtaPressed,
    required this.child,
    this.autofocus = true,
    this.onSecondaryAction,
  });

  @override
  State<KeyboardCtaHandler> createState() => _KeyboardCtaHandlerState();
}

class _KeyboardCtaHandlerState extends State<KeyboardCtaHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.autofocus) {
      // Request focus after the widget is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Enter or Space triggers the primary CTA
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onCtaPressed();
      return KeyEventResult.handled;
    }

    // Escape triggers secondary action if provided
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        widget.onSecondaryAction != null) {
      widget.onSecondaryAction!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
