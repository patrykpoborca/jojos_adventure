import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/audio/audio_manager.dart';
import '../game/memory_lane_game.dart';

/// View state for the memory overlay
enum MemoryViewState {
  /// Showing polaroid stack
  polaroidStack,

  /// Showing the level trigger dialog
  levelDialog,

  /// Showing phase complete dialog (crawling -> walking)
  phaseComplete,

  /// Showing game complete dialog (ready for road trip)
  gameComplete,

  /// Showing "come back later" dialog (not all memories collected)
  endgameNotReady,
}

/// Polaroid-style overlay for displaying photo memories
class PolaroidOverlay extends StatefulWidget {
  final MemoryLaneGame game;

  const PolaroidOverlay({super.key, required this.game});

  @override
  State<PolaroidOverlay> createState() => _PolaroidOverlayState();
}

class _PolaroidOverlayState extends State<PolaroidOverlay>
    with SingleTickerProviderStateMixin {
  late MemoryViewState _viewState;
  int _currentPhotoIndex = 0;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Set initial view state based on game's overlay type
    switch (widget.game.overlayType) {
      case OverlayType.memory:
        _viewState = MemoryViewState.polaroidStack;
        // Play memory music if available
        _playMemoryMusic();
        break;
      case OverlayType.phaseComplete:
        _viewState = MemoryViewState.phaseComplete;
        break;
      case OverlayType.gameComplete:
        _viewState = MemoryViewState.gameComplete;
        break;
      case OverlayType.endgameNotReady:
        _viewState = MemoryViewState.endgameNotReady;
        break;
    }

    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  void _playMemoryMusic() {
    final musicFile = widget.game.currentMemory?.musicFile;
    if (musicFile != null) {
      AudioManager().playMemoryMusic(musicFile);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Memory? get memory => widget.game.currentMemory;

  /// Get all photos including the stylized cover
  List<String> get allPhotos {
    if (memory == null) return [];
    return [memory!.stylizedPhotoPath, ...memory!.photos];
  }

  bool get isLastPhoto => _currentPhotoIndex >= allPhotos.length - 1;

  void _onPolaroidTap() {
    if (memory == null) return;

    if (!isLastPhoto) {
      // Show next photo
      setState(() {
        _currentPhotoIndex++;
      });
    } else {
      // End of photos
      if (memory!.triggersLevel) {
        setState(() {
          _viewState = MemoryViewState.levelDialog;
        });
      } else {
        _closeOverlay();
      }
    }
  }

  void _closeOverlay() {
    _animController.reverse().then((_) {
      widget.game.resumeGame();
    });
  }

  void _onLevelAccept() {
    final levelId = memory?.levelTrigger;
    if (levelId != null) {
      debugPrint('Level trigger accepted: $levelId');
      // Close overlay first, then switch level
      _animController.reverse().then((_) {
        widget.game.resumeGame();
        widget.game.switchToLevelByName(levelId);
      });
    } else {
      _closeOverlay();
    }
  }

  void _onLevelDecline() {
    _closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black54,
        child: GestureDetector(
          onTap: _onPolaroidTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_viewState) {
      case MemoryViewState.polaroidStack:
        return _buildPolaroidStack();
      case MemoryViewState.levelDialog:
        return _buildLevelDialog();
      case MemoryViewState.phaseComplete:
        return _buildPhaseCompleteDialog();
      case MemoryViewState.gameComplete:
        return _buildGameCompleteDialog();
      case MemoryViewState.endgameNotReady:
        return _buildEndgameNotReadyDialog();
    }
  }

  Widget _buildPolaroidStack() {
    final screenHeight = MediaQuery.of(context).size.height;
    final photoSize = (screenHeight * 0.35).clamp(180.0, 280.0);
    final photos = allPhotos;
    final totalPhotos = photos.length;

    return SizedBox(
      width: photoSize + 80,
      height: photoSize + 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background polaroids (upcoming ones)
          for (int i = totalPhotos - 1; i > _currentPhotoIndex; i--)
            _buildStackedPolaroid(
              photoPath: photos[i],
              photoSize: photoSize,
              stackIndex: i - _currentPhotoIndex,
              isBackground: true,
            ),

          // Current polaroid on top
          _buildStackedPolaroid(
            photoPath: photos[_currentPhotoIndex],
            photoSize: photoSize,
            stackIndex: 0,
            isBackground: false,
          ),

          // Photo counter
          if (totalPhotos > 1)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentPhotoIndex + 1} / $totalPhotos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStackedPolaroid({
    required String photoPath,
    required double photoSize,
    required int stackIndex,
    required bool isBackground,
  }) {
    // Random but consistent rotation for each stack position
    final random = math.Random(stackIndex * 42);
    final rotation = isBackground
        ? (random.nextDouble() - 0.5) * 0.15
        : 0.03;
    final offsetX = isBackground ? (random.nextDouble() - 0.5) * 20 : 0.0;
    final offsetY = isBackground ? -stackIndex * 4.0 : 0.0;
    final scale = isBackground ? 1.0 - (stackIndex * 0.02) : 1.0;

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: photoSize + 40,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isBackground ? 0.15 : 0.3),
                  blurRadius: isBackground ? 10 : 20,
                  offset: Offset(0, isBackground ? 5 : 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo area
                Container(
                  width: photoSize,
                  height: photoSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    border: Border.all(
                      color: const Color(0xFFD0D0D0),
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    photoPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.photo,
                          size: 64,
                          color: Color(0xFF9E9E9E),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Only show text on current polaroid
                if (!isBackground && memory != null) ...[
                  // Only show date if it's not a placeholder
                  if (memory!.date != 'Date') ...[
                    Text(
                      memory!.date,
                      style: GoogleFonts.caveat(
                        fontSize: 14,
                        color: const Color(0xFF6B5B4F),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    memory!.caption,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      color: const Color(0xFF3C3C3C),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLastPhoto ? 'Tap to continue' : 'Tap for next photo',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
                if (isBackground)
                  SizedBox(height: photoSize * 0.15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelDialog() {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.25).clamp(120.0, 200.0);

    return Container(
      width: 350,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero banner image from the memory
          if (memory != null)
            Stack(
              children: [
                // Memory image
                SizedBox(
                  width: double.infinity,
                  height: heroHeight,
                  child: Image.asset(
                    memory!.stylizedPhotoPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFD4A574).withValues(alpha: 0.2),
                        child: const Center(
                          child: Icon(
                            Icons.photo,
                            size: 48,
                            color: Color(0xFFD4A574),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Gradient overlay for text readability
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: heroHeight * 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
                // Memory caption overlay
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Text(
                    memory!.caption,
                    style: GoogleFonts.caveat(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          // Content padding
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Title
                Text(
                  'New Memory Unlocked!',
                  style: GoogleFonts.caveat(
                    fontSize: 28,
                    color: const Color(0xFF3C3C3C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Would you like to explore this special memory?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _onLevelDecline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Not Now'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onLevelAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4A574),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Let\'s Go!'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCompleteDialog() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF8BC34A).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care,
              size: 50,
              color: Color(0xFF8BC34A),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Growing Up!',
            style: GoogleFonts.caveat(
              fontSize: 32,
              color: const Color(0xFF3C3C3C),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'You\'ve collected all the crawling memories!\nTime to take your first steps...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _onPhaseTransition,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8BC34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Walking!',
                style: GoogleFonts.caveat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPhaseTransition() {
    _animController.reverse().then((_) {
      widget.game.resumeGame();
      widget.game.transitionToPhase(GamePhase.walking);
    });
  }

  Widget _buildGameCompleteDialog() {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.25).clamp(120.0, 200.0);

    return Container(
      width: 400,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hero image - road trip photo
          if (memory != null)
            SizedBox(
              width: double.infinity,
              height: heroHeight,
              child: Image.asset(
                memory!.stylizedPhotoPath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFD4A574).withValues(alpha: 0.2),
                    child: const Center(
                      child: Icon(
                        Icons.directions_car,
                        size: 48,
                        color: Color(0xFFD4A574),
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    size: 40,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Ready for Adventure!',
                  style: GoogleFonts.caveat(
                    fontSize: 32,
                    color: const Color(0xFF3C3C3C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'You\'ve collected all the precious memories.\nTime for a family road trip!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '🎄 Merry Christmas! 🎄',
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    color: const Color(0xFFD4A574),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _closeOverlay,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade400),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Stay a bit longer'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onStartRoadTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Let\'s Go!',
                          style: GoogleFonts.caveat(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndgameNotReadyDialog() {
    final collected = widget.game.memoriesCollected;
    final total = widget.game.totalMemories;

    return Container(
      width: 380,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon - locked car
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.directions_car,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Not Quite Ready Yet...',
            style: GoogleFonts.caveat(
              fontSize: 28,
              color: const Color(0xFF3C3C3C),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'There are still more memories to collect\nbefore our road trip!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_library,
                  color: Color(0xFFD4A574),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '$collected / $total memories',
                  style: GoogleFonts.caveat(
                    fontSize: 20,
                    color: const Color(0xFFD4A574),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _closeOverlay,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A574),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Keep Exploring',
                style: GoogleFonts.caveat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onStartRoadTrip() {
    _animController.reverse().then((_) {
      widget.game.resumeGame();
      // TODO: Start the road trip ending sequence (video or montage)
      widget.game.startMontage();
    });
  }
}
