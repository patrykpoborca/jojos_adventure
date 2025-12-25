import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/memory_lane_game.dart';
import 'ui/collected_memories_hud.dart';
import 'ui/debug_obstacle_overlay.dart';
import 'ui/ending_video_overlay.dart';
import 'ui/polaroid_overlay.dart';
import 'ui/responsive_sizing.dart';
import 'ui/settings_menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system UI for immersive experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const MemoryLaneApp());
}

class MemoryLaneApp extends StatelessWidget {
  const MemoryLaneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Lane',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4A574), // Warm amber
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final MemoryLaneGame _game;
  final FocusNode _focusNode = FocusNode();
  bool _showDebugPanel = MemoryLaneGame.showDebugPanel;
  bool _isCinematicMode = false;

  @override
  void initState() {
    super.initState();
    _game = MemoryLaneGame();

    // Listen for debug panel toggle
    _game.onDebugPanelToggled = (visible) {
      debugPrint('Callback received: visible=$visible, mounted=$mounted');
      if (mounted) {
        setState(() {
          _showDebugPanel = visible;
          debugPrint('setState called, _showDebugPanel=$_showDebugPanel');
        });
      }
    };

    // Listen for cinematic mode (ending video)
    _game.onCinematicModeChanged = (cinematic) {
      if (mounted) {
        setState(() {
          _isCinematicMode = cinematic;
        });
      }
    };
  }

  @override
  void dispose() {
    _game.onDebugPanelToggled = null;
    _game.onCinematicModeChanged = null;
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      // D key always works to toggle debug panel
      if (event.logicalKey == LogicalKeyboardKey.keyD) {
        _game.toggleDebugPanel();
        return KeyEventResult.handled;
      }

      // Other keys only work when debug panel is visible
      if (!_showDebugPanel) {
        return KeyEventResult.ignored;
      }

      if (event.logicalKey == LogicalKeyboardKey.space) {
        _game.handleObstaclePlacement();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
        _game.cancelObstaclePlacement();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
        _game.printAllObstacles();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
        _game.togglePlacementMode();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _game.toggleLevel();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyG) {
        _game.togglePhase();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyU) {
        _game.togglePlayerCollision();
        return KeyEventResult.handled;
      } else if (event.logicalKey == LogicalKeyboardKey.keyB) {
        _game.debugCollectAllMemories();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: GestureDetector(
          // Tap anywhere to regain focus (after text field interaction)
          onTap: () => _focusNode.requestFocus(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Game widget
              GameWidget(
                game: _game,
                overlayBuilderMap: {
                  'polaroid': (context, game) => PolaroidOverlay(
                        game: game as MemoryLaneGame,
                      ),
                  'settings': (context, game) => SettingsMenu(
                        game: game as MemoryLaneGame,
                      ),
                  'endingVideo': (context, game) => EndingVideoOverlay(
                        game: game as MemoryLaneGame,
                      ),
                },
                loadingBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFFD4A574),
                      ),
                      SizedBox(height: ResponsiveSizing.spacing(context, 16)),
                      Text(
                        'Loading memories...',
                        style: TextStyle(
                          fontSize: ResponsiveSizing.fontSize(context, 18),
                          color: const Color(0xFF6B5B4F),
                        ),
                      ),
                    ],
                  ),
                ),
                errorBuilder: (context, error) => Center(
                  child: Text(
                    'Error loading game:\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

              // Collected memories HUD (top left) - hidden in cinematic mode
              if (!_isCinematicMode)
                CollectedMemoriesHud(game: _game),

              // Settings button (top right) - hidden in cinematic mode
              if (!_isCinematicMode)
                Builder(
                  builder: (context) {
                    final buttonSize = ResponsiveSizing.dimension(context, 48);
                    return Positioned(
                      top: ResponsiveSizing.spacing(context, 12),
                      right: ResponsiveSizing.spacing(context, 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _game.showSettings(),
                          borderRadius: BorderRadius.circular(buttonSize / 2),
                          child: Container(
                            width: buttonSize,
                            height: buttonSize,
                            decoration: BoxDecoration(
                              color: const Color(0xAAD4A574),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: ResponsiveSizing.spacing(context, 8),
                                  offset: Offset(0, ResponsiveSizing.spacing(context, 2)),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: ResponsiveSizing.iconSize(context, 24),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // Debug overlay (toggle with D key) - hidden in cinematic mode
              if (_showDebugPanel && !_isCinematicMode)
                DebugObstacleOverlay(game: _game),
            ],
          ),
        ),
      ),
    );
  }
}
