import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/audio/audio_manager.dart';
import '../game/memory_lane_game.dart';
import 'responsive_sizing.dart';

/// Start screen overlay shown when game first loads
/// Requires user interaction to start, which unlocks audio on web
class StartScreen extends StatefulWidget {
  final MemoryLaneGame game;

  const StartScreen({super.key, required this.game});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final AnimationController _pulseController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _buttonPulse;

  @override
  void initState() {
    super.initState();

    // Fade-in controller - runs once
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();

    // Button pulse controller - repeats forever
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _buttonPulse = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onStartGame() async {
    // Unlock audio (required for web)
    AudioManager().unlockAudio();

    // Hide this overlay and start the game (loads level on web)
    await widget.game.hideStartScreen();
  }

  @override
  Widget build(BuildContext context) {
    final titleSize = ResponsiveSizing.fontSize(context, 48);
    final subtitleSize = ResponsiveSizing.fontSize(context, 18);
    final buttonFontSize = ResponsiveSizing.fontSize(context, 24);
    final buttonPadding = ResponsiveSizing.spacing(context, 24);

    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _fadeController,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeIn.value,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/photos/start_game_screen.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Main content - positioned 10% to the right
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.1,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveSizing.spacing(context, 40),
                          vertical: ResponsiveSizing.spacing(context, 32),
                        ),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.4),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.6, 1.0],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Game title
                            Text(
                              "JoJo's Adventure",
                              style: GoogleFonts.caveat(
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD4A574),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 12,
                                    offset: const Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: ResponsiveSizing.spacing(context, 8)),

                            // Subtitle
                            Text(
                              'A journey through memories',
                              style: GoogleFonts.caveat(
                                fontSize: subtitleSize,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: ResponsiveSizing.spacing(context, 60)),

                            // Start button with pulse animation
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _buttonPulse.value,
                                  child: child,
                                );
                              },
                              child: ElevatedButton(
                                onPressed: _onStartGame,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4A574),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: buttonPadding * 2,
                                    vertical: buttonPadding,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveSizing.spacing(context, 16),
                                    ),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(0xFFD4A574).withValues(alpha: 0.5),
                                ),
                                child: Text(
                                  'Start Game',
                                  style: GoogleFonts.caveat(
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: ResponsiveSizing.spacing(context, 40)),

                            // Web hint
                            if (kIsWeb)
                              Text(
                                'Tap or click to enable sound',
                                style: TextStyle(
                                  fontSize: ResponsiveSizing.fontSize(context, 12),
                                  color: Colors.white70,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.8),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Version/credit at bottom right
                  Positioned(
                    bottom: ResponsiveSizing.spacing(context, 16),
                    left: MediaQuery.of(context).size.width * 0.1,
                    right: 0,
                    child: Text(
                      'A gift with love',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.caveat(
                        fontSize: ResponsiveSizing.fontSize(context, 14),
                        color: Colors.white60,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.8),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
