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
        // Skip polaroid for memories that trigger dialogs - go straight to dialog
        if (widget.game.currentMemory?.triggersLevel == true) {
          _viewState = MemoryViewState.levelDialog;
        } else {
          _viewState = MemoryViewState.polaroidStack;
          // Play memory music if available (only for regular memories)
          _playMemoryMusic();
        }
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
    final heroHeight = (screenHeight * 0.35).clamp(180.0, 280.0);

    return Container(
      width: 420,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero banner image from the memory
            if (memory != null)
              Stack(
                children: [
                  // Memory image - taller to show more
                  SizedBox(
                    width: double.infinity,
                    height: heroHeight,
                    child: Image.asset(
                      memory!.stylizedPhotoPath,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFD4A574).withValues(alpha: 0.2),
                          child: const Center(
                            child: Icon(
                              Icons.photo,
                              size: 64,
                              color: Color(0xFFD4A574),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay at bottom for smooth transition
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xFFFFFBF7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Icon badge overlapping bottom of image
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A574).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.stairs,
                            size: 26,
                            color: Color(0xFFD4A574),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Content padding
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  // Title
                  const SizedBox(height: 8),

                  // Description with surface background
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          memory?.caption ?? 'A special memory awaits...',
                          style: GoogleFonts.caveat(
                            fontSize: 20,
                            color: const Color(0xFFD4A574),
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Would you like to leave this area?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onLevelDecline,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Not Now'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onLevelAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A574),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Let\'s Go!',
                            style: GoogleFonts.caveat(
                              fontSize: 18,
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
      ),
    );
  }

  Widget _buildPhaseCompleteDialog() {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.25).clamp(140.0, 200.0);

    return Container(
      width: 420,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero section with gradient background
            Stack(
              children: [
                // Gradient hero background
                Container(
                  width: double.infinity,
                  height: heroHeight,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFAED581), // Light green
                        Color(0xFF8BC34A), // Green
                        Color(0xFF7CB342), // Darker green
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.child_care,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                // Gradient overlay at bottom for smooth transition
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 60,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0xFFFFFBF7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Icon badge overlapping bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF7),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8BC34A).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_walk,
                          size: 26,
                          color: Color(0xFF8BC34A),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Growing Up!',
                    style: GoogleFonts.caveat(
                      fontSize: 28,
                      color: const Color(0xFF3C3C3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description with surface background
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'You\'ve collected all the crawling memories!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time to take your first steps...',
                          style: GoogleFonts.caveat(
                            fontSize: 20,
                            color: const Color(0xFF8BC34A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onPhaseTransition,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8BC34A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Start Walking!',
                        style: GoogleFonts.caveat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    final heroHeight = (screenHeight * 0.35).clamp(180.0, 280.0);

    return Container(
      width: 420,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero image with icon overlay
            if (memory != null)
              Stack(
                children: [
                  // Main hero image - taller to show more
                  SizedBox(
                    width: double.infinity,
                    height: heroHeight,
                    child: Image.asset(
                      memory!.stylizedPhotoPath,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFD4A574).withValues(alpha: 0.2),
                          child: const Center(
                            child: Icon(
                              Icons.directions_car,
                              size: 64,
                              color: Color(0xFFD4A574),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay at bottom for smooth transition
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xFFFFFBF7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Icon badge overlapping bottom of image
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_car,
                            size: 26,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Ready for Adventure!',
                    style: GoogleFonts.caveat(
                      fontSize: 28,
                      color: const Color(0xFF3C3C3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description with surface background
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'You\'ve collected all the precious memories.\nTime for a family road trip!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '🎄 Merry Christmas! 🎄',
                          style: GoogleFonts.caveat(
                            fontSize: 20,
                            color: const Color(0xFFD4A574),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _closeOverlay,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            side: BorderSide(color: Colors.grey.shade400),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Stay a bit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onStartRoadTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Let\'s Go!',
                            style: GoogleFonts.caveat(
                              fontSize: 18,
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
      ),
    );
  }

  Widget _buildEndgameNotReadyDialog() {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = (screenHeight * 0.35).clamp(180.0, 280.0);
    final collected = widget.game.memoriesCollected;
    final total = widget.game.totalMemories;

    return Container(
      width: 420,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9,
      ),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hero image with greyed overlay (locked feel)
            if (memory != null)
              Stack(
                children: [
                  // Main hero image
                  SizedBox(
                    width: double.infinity,
                    height: heroHeight,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.grey.withValues(alpha: 0.5),
                        BlendMode.saturation,
                      ),
                      child: Image.asset(
                        memory!.stylizedPhotoPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: Center(
                              child: Icon(
                                Icons.directions_car,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Dark overlay for locked effect
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ),
                  // Gradient overlay at bottom for smooth transition
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0xFFFFFBF7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Locked icon badge overlapping bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBF7),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.directions_car,
                                size: 22,
                                color: Colors.grey.shade400,
                              ),
                              Positioned(
                                right: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock,
                                    size: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'Not Quite Ready Yet...',
                    style: GoogleFonts.caveat(
                      fontSize: 28,
                      color: const Color(0xFF3C3C3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description with surface background and progress
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'There are still more memories to collect\nbefore our road trip!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Progress indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library,
                              color: Color(0xFFD4A574),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$collected / $total memories',
                              style: GoogleFonts.caveat(
                                fontSize: 18,
                                color: const Color(0xFFD4A574),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

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
            ),
          ],
        ),
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
