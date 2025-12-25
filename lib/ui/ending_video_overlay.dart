import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../game/memory_lane_game.dart';

/// Full-screen video overlay for the ending scene
class EndingVideoOverlay extends StatefulWidget {
  final MemoryLaneGame game;

  const EndingVideoOverlay({super.key, required this.game});

  @override
  State<EndingVideoOverlay> createState() => _EndingVideoOverlayState();
}

class _EndingVideoOverlayState extends State<EndingVideoOverlay>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showEndCard = false;
  bool _hasError = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset('assets/video/ending_scene.mp4');

      await _controller.initialize();

      // Listen for video completion
      _controller.addListener(_onVideoUpdate);

      setState(() {
        _isInitialized = true;
      });

      // Start playing immediately
      await _controller.play();
    } catch (e) {
      debugPrint('Error initializing video: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  void _onVideoUpdate() {
    if (!_controller.value.isInitialized) return;

    // Check if video has finished
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    if (position >= duration && duration.inMilliseconds > 0) {
      if (!_showEndCard) {
        setState(() {
          _showEndCard = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoUpdate);
    _controller.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onSkip() {
    _controller.pause();
    setState(() {
      _showEndCard = true;
    });
  }

  void _onClose() {
    _fadeController.reverse().then((_) {
      widget.game.hideEndingVideo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player or loading/error state
            if (_hasError)
              _buildErrorState()
            else if (!_isInitialized)
              _buildLoadingState()
            else if (_showEndCard)
              _buildEndCard()
            else
              _buildVideoPlayer(),

            // Skip button (only during video playback)
            if (_isInitialized && !_showEndCard && !_hasError)
              Positioned(
                top: 40,
                right: 20,
                child: TextButton.icon(
                  onPressed: _onSkip,
                  icon: const Icon(Icons.skip_next, color: Colors.white70),
                  label: const Text(
                    'Skip',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFD4A574),
          ),
          SizedBox(height: 16),
          Text(
            'Loading...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Could not load video',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showEndCard = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A574),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _onSkip,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }

  Widget _buildEndCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            const Color(0xFF1a1a2e),
            const Color(0xFF16213e),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Christmas tree icon
              const Text(
                '🎄',
                style: TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'The End',
                style: GoogleFonts.caveat(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Memory Lane',
                style: GoogleFonts.caveat(
                  fontSize: 32,
                  color: const Color(0xFFD4A574),
                ),
              ),
              const SizedBox(height: 32),

              // Message
              Text(
                'Thank you for exploring our memories.\nWith love, from the Poborca family!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Christmas message
              Text(
                'Merry Christmas!',
                style: GoogleFonts.caveat(
                  fontSize: 28,
                  color: const Color(0xFFD4A574),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '2024 - 2025',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 40),

              // Hearts
              const Text(
                '❤️ 👶 ❤️',
                style: TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 40),

              // Close button
              ElevatedButton(
                onPressed: _onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4A574),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
