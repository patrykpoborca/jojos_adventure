import 'dart:math';

import 'package:flutter/material.dart';

import '../game/memory_lane_game.dart';

/// Overlay shown during character interaction focus mode
/// Shows continuous hearts, blur vignette, and handles tap-to-exit
class CharacterInteractionOverlay extends StatefulWidget {
  final MemoryLaneGame game;

  const CharacterInteractionOverlay({super.key, required this.game});

  @override
  State<CharacterInteractionOverlay> createState() =>
      _CharacterInteractionOverlayState();
}

class _CharacterInteractionOverlayState
    extends State<CharacterInteractionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  // Continuous hearts particles
  final List<_FloatingHeart> _hearts = [];
  final Random _random = Random();
  double _heartSpawnTimer = 0;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();

    // Start with a burst of hearts
    _spawnInitialHearts();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _spawnInitialHearts() {
    // Spawn initial burst of hearts
    for (var i = 0; i < 8; i++) {
      _hearts.add(_FloatingHeart(
        random: _random,
        delay: i * 0.1,
      ));
    }
  }

  void _update(double dt) {
    // Spawn new hearts periodically
    _heartSpawnTimer += dt;
    if (_heartSpawnTimer >= 0.3) {
      _heartSpawnTimer = 0;
      _hearts.add(_FloatingHeart(random: _random));
    }

    // Update existing hearts
    for (final heart in _hearts) {
      heart.update(dt);
    }

    // Remove dead hearts
    _hearts.removeWhere((h) => h.isDone);
  }

  void _exitInteraction() {
    _animController.reverse().then((_) {
      widget.game.endCharacterInteraction();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: _exitInteraction,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Blur layer with vignette gradient
            _buildBlurVignette(context),
            // Hearts animation layer
            _HeartsAnimationWidget(
              hearts: _hearts,
              onUpdate: _update,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurVignette(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final fadeRadius = size.longestSide * 0.7;

    return CustomPaint(
      size: size,
      painter: _VignettePainter(
        center: center,
        fadeRadius: fadeRadius,
      ),
    );
  }
}

/// Paints a radial vignette effect - clear in center, dark at edges
class _VignettePainter extends CustomPainter {
  final Offset center;
  final double fadeRadius;

  _VignettePainter({
    required this.center,
    required this.fadeRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Create radial gradient from clear center to dark edges
    final gradient = RadialGradient(
      center: Alignment(
        (center.dx / size.width) * 2 - 1,
        (center.dy / size.height) * 2 - 1,
      ),
      radius: fadeRadius / size.shortestSide,
      colors: [
        Colors.transparent,
        Colors.transparent,
        Colors.black.withValues(alpha: 0.4),
        Colors.black.withValues(alpha: 0.75),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_VignettePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.fadeRadius != fadeRadius;
  }
}

/// Widget that drives the hearts animation
class _HeartsAnimationWidget extends StatefulWidget {
  final List<_FloatingHeart> hearts;
  final void Function(double dt) onUpdate;

  const _HeartsAnimationWidget({
    required this.hearts,
    required this.onUpdate,
  });

  @override
  State<_HeartsAnimationWidget> createState() => _HeartsAnimationWidgetState();
}

class _HeartsAnimationWidgetState extends State<_HeartsAnimationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickController;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _tickController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();

    _tickController.addListener(_onTick);
  }

  @override
  void dispose() {
    _tickController.removeListener(_onTick);
    _tickController.dispose();
    super.dispose();
  }

  void _onTick() {
    final now = DateTime.now();
    if (_lastUpdate != null) {
      final dt = (now.difference(_lastUpdate!).inMicroseconds) / 1000000.0;
      widget.onUpdate(dt);
      setState(() {});
    }
    _lastUpdate = now;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Render hearts
        ...widget.hearts.where((h) => !h.isDone && h.delay <= 0).map((heart) {
          return Positioned(
            left: heart.screenX * screenSize.width,
            bottom: heart.screenY * screenSize.height,
            child: Opacity(
              opacity: heart.alpha.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: heart.scale,
                child: Text(
                  heart.symbol,
                  style: TextStyle(
                    fontSize: 32 + heart.sizeVariation,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        // Tap hint at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Tap anywhere to continue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A floating heart particle
class _FloatingHeart {
  // Screen position (0-1 range)
  double screenX;
  double screenY;
  double alpha = 0.0;
  double scale = 0.0;
  double lifetime = 0;
  double delay;
  final String symbol;
  final double sizeVariation;
  final double driftX;
  final double speed;

  static const double maxLifetime = 3.0;

  _FloatingHeart({
    required Random random,
    this.delay = 0,
  })  : screenX = 0.2 + random.nextDouble() * 0.6, // Center 60% of screen
        screenY = -0.1, // Start below screen
        symbol = ['❤', '💕', '✨', '💗', '💖', '🩷'][random.nextInt(6)],
        sizeVariation = random.nextDouble() * 16 - 8, // -8 to +8
        driftX = (random.nextDouble() - 0.5) * 0.1, // Slight horizontal drift
        speed = 0.15 + random.nextDouble() * 0.1; // Vertical speed variation

  void update(double dt) {
    if (delay > 0) {
      delay -= dt;
      return;
    }

    lifetime += dt;
    final progress = lifetime / maxLifetime;

    // Float upward
    screenY += speed * dt;

    // Slight horizontal wobble
    screenX += driftX * dt * sin(lifetime * 3);

    // Fade in quickly, then fade out
    if (progress < 0.15) {
      alpha = progress / 0.15;
      scale = 0.5 + (progress / 0.15) * 0.5;
    } else if (progress > 0.7) {
      alpha = 1.0 - ((progress - 0.7) / 0.3);
      scale = 1.0;
    } else {
      alpha = 1.0;
      scale = 1.0;
    }
  }

  bool get isDone => lifetime >= maxLifetime;
}
