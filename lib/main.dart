import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/memory_lane_game.dart';
import 'ui/polaroid_overlay.dart';

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

  @override
  void initState() {
    super.initState();
    _game = MemoryLaneGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'polaroid': (context, game) => PolaroidOverlay(
                game: game as MemoryLaneGame,
              ),
        },
        loadingBuilder: (context) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFD4A574),
              ),
              SizedBox(height: 16),
              Text(
                'Loading memories...',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF6B5B4F),
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
    );
  }
}
