import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/memory_lane_game.dart';

/// View state for the memory overlay
enum MemoryViewState {
  /// Showing the stylized polaroid cover
  polaroid,

  /// Showing the photo slideshow
  slideshow,

  /// Showing the level trigger dialog
  levelDialog,
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
  MemoryViewState _viewState = MemoryViewState.polaroid;
  int _currentPhotoIndex = 0;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Memory? get memory => widget.game.currentMemory;

  void _onPolaroidTap() {
    if (memory == null) return;

    if (memory!.hasSlideshow) {
      setState(() {
        _viewState = MemoryViewState.slideshow;
        _currentPhotoIndex = 0;
      });
    } else if (memory!.triggersLevel) {
      setState(() {
        _viewState = MemoryViewState.levelDialog;
      });
    } else {
      _closeOverlay();
    }
  }

  void _nextPhoto() {
    if (memory == null) return;

    if (_currentPhotoIndex < memory!.photos.length - 1) {
      setState(() {
        _currentPhotoIndex++;
      });
    } else {
      // End of slideshow
      if (memory!.triggersLevel) {
        setState(() {
          _viewState = MemoryViewState.levelDialog;
        });
      } else {
        _closeOverlay();
      }
    }
  }

  void _previousPhoto() {
    if (_currentPhotoIndex > 0) {
      setState(() {
        _currentPhotoIndex--;
      });
    } else {
      // Go back to polaroid view
      setState(() {
        _viewState = MemoryViewState.polaroid;
      });
    }
  }

  void _closeOverlay() {
    _animController.reverse().then((_) {
      widget.game.resumeGame();
    });
  }

  void _onLevelAccept() {
    // TODO: Implement level transition
    final levelId = memory?.levelTrigger;
    debugPrint('Level trigger accepted: $levelId');
    _closeOverlay();
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
          onTap: () {
            // Tap outside to close (only in polaroid mode)
            if (_viewState == MemoryViewState.polaroid) {
              _onPolaroidTap();
            }
          },
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
      case MemoryViewState.polaroid:
        return _buildPolaroidView();
      case MemoryViewState.slideshow:
        return _buildSlideshowView();
      case MemoryViewState.levelDialog:
        return _buildLevelDialog();
    }
  }

  Widget _buildPolaroidView() {
    return GestureDetector(
      onTap: _onPolaroidTap,
      child: Transform.rotate(
        angle: 0.05,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(4),
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
              // Stylized photo area
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  border: Border.all(
                    color: const Color(0xFFD0D0D0),
                    width: 1,
                  ),
                ),
                child: memory != null
                    ? Image.asset(
                        memory!.stylizedPhotoPath,
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
                      )
                    : const Center(
                        child: Icon(
                          Icons.photo,
                          size: 64,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Date
              if (memory != null)
                Text(
                  memory!.date,
                  style: GoogleFonts.caveat(
                    fontSize: 16,
                    color: const Color(0xFF6B5B4F),
                  ),
                ),
              const SizedBox(height: 4),

              // Caption
              if (memory != null)
                Text(
                  memory!.caption,
                  style: GoogleFonts.caveat(
                    fontSize: 22,
                    color: const Color(0xFF3C3C3C),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),

              // Hint text
              Text(
                memory?.hasSlideshow == true
                    ? 'Tap to see more photos'
                    : 'Tap to continue',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlideshowView() {
    if (memory == null || memory!.photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentPhoto = memory!.photos[_currentPhotoIndex];
    final isLastPhoto = _currentPhotoIndex == memory!.photos.length - 1;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with close button and counter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                IconButton(
                  onPressed: _previousPhoto,
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                // Photo counter
                Text(
                  '${_currentPhotoIndex + 1} / ${memory!.photos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // Close button
                IconButton(
                  onPressed: _closeOverlay,
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),

          // Photo area
          Expanded(
            child: GestureDetector(
              onTap: _nextPhoto,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  _nextPhoto();
                } else if (details.primaryVelocity! > 0) {
                  _previousPhoto();
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Image.asset(
                  currentPhoto,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Caption and navigation
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  memory!.caption,
                  style: GoogleFonts.caveat(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentPhotoIndex > 0)
                      TextButton.icon(
                        onPressed: _previousPhoto,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Previous'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                        ),
                      ),
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: _nextPhoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4A574),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text(isLastPhoto ? 'Done' : 'Next'),
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

  Widget _buildLevelDialog() {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(24),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFD4A574).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore,
              size: 40,
              color: Color(0xFFD4A574),
            ),
          ),
          const SizedBox(height: 20),

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
    );
  }
}
