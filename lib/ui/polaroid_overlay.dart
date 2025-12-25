import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/audio/audio_manager.dart';
import '../game/memory_lane_game.dart';
import 'responsive_sizing.dart';

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

  /// Showing coupon unlock dialog
  couponUnlock,
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
        } else if (widget.game.currentMemory?.isCouponReward == true) {
          _viewState = MemoryViewState.couponUnlock;
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
      case OverlayType.couponUnlock:
        _viewState = MemoryViewState.couponUnlock;
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
      case MemoryViewState.couponUnlock:
        return _buildCouponDialog();
    }
  }

  Widget _buildPolaroidStack() {
    final screenHeight = ResponsiveSizing.screenHeight(context);
    final scale = ResponsiveSizing.scaleFactor(context);
    final photoSize = (screenHeight * 0.35).clamp(180.0, 280.0) * scale;
    final photos = allPhotos;
    final totalPhotos = photos.length;

    return SizedBox(
      width: photoSize + ResponsiveSizing.spacing(context, 80),
      height: photoSize + ResponsiveSizing.spacing(context, 180),
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
                padding: ResponsiveSizing.paddingSymmetric(
                  context,
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: ResponsiveSizing.borderRadius(context, 12),
                ),
                child: Text(
                  '${_currentPhotoIndex + 1} / $totalPhotos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveSizing.fontSize(context, 12),
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
    final padding = ResponsiveSizing.spacing(context, 16);
    final borderPadding = ResponsiveSizing.spacing(context, 40);

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Transform.rotate(
        angle: rotation,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: photoSize + borderPadding,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7),
              borderRadius: ResponsiveSizing.borderRadius(context, 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isBackground ? 0.15 : 0.3),
                  blurRadius: ResponsiveSizing.spacing(context, isBackground ? 10 : 20),
                  offset: Offset(0, ResponsiveSizing.spacing(context, isBackground ? 5 : 10)),
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
                      return Center(
                        child: Icon(
                          Icons.photo,
                          size: ResponsiveSizing.iconSize(context, 64),
                          color: const Color(0xFF9E9E9E),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: ResponsiveSizing.spacing(context, 12)),

                // Only show text on current polaroid
                if (!isBackground && memory != null) ...[
                  // Only show date if it's not a placeholder
                  if (memory!.date != 'Date') ...[
                    Text(
                      memory!.date,
                      style: GoogleFonts.caveat(
                        fontSize: ResponsiveSizing.fontSize(context, 14),
                        color: const Color(0xFF6B5B4F),
                      ),
                    ),
                    SizedBox(height: ResponsiveSizing.spacing(context, 2)),
                  ],
                  Text(
                    memory!.caption,
                    style: GoogleFonts.caveat(
                      fontSize: ResponsiveSizing.fontSize(context, 18),
                      color: const Color(0xFF3C3C3C),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveSizing.spacing(context, 8)),
                  Text(
                    isLastPhoto ? 'Tap to continue' : 'Tap for next photo',
                    style: TextStyle(
                      fontSize: ResponsiveSizing.fontSize(context, 11),
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
    final dialogHeight = ResponsiveSizing.dialogHeight(context);
    final dialogWidth = ResponsiveSizing.dialogWidth(context);
    final pos = ResponsiveSizing.positionOffset(context, 12);
    final captionPadding = ResponsiveSizing.spacing(context, 16);
    final captionBottom = ResponsiveSizing.spacing(context, 20);

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: ResponsiveSizing.borderRadius(context, 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: ResponsiveSizing.spacing(context, 24),
            offset: Offset(0, ResponsiveSizing.spacing(context, 12)),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed hero image
          if (memory != null)
            Image.asset(
              memory!.stylizedPhotoPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFD4A574),
                  child: Center(
                    child: Icon(
                      Icons.photo,
                      size: ResponsiveSizing.iconSize(context, 64),
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),

          // Gradient overlay at bottom for caption readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: dialogHeight * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // Caption at bottom
          Positioned(
            left: captionPadding,
            right: captionPadding,
            bottom: captionBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  memory?.caption ?? 'A special memory awaits...',
                  style: GoogleFonts.caveat(
                    fontSize: ResponsiveSizing.fontSize(context, 28),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: ResponsiveSizing.spacing(context, 8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Close button (X) - top left
          Positioned(
            top: pos,
            left: pos,
            child: _buildCornerButton(
              icon: Icons.close,
              onTap: _onLevelDecline,
              isAccent: false,
            ),
          ),

          // Go forward button (arrow) - top right
          Positioned(
            top: pos,
            right: pos,
            child: _buildCornerButton(
              icon: Icons.arrow_forward,
              onTap: _onLevelAccept,
              isAccent: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isAccent,
    Color? accentColor,
  }) {
    final buttonColor = isAccent
        ? (accentColor ?? const Color(0xFFD4A574))
        : Colors.black.withValues(alpha: 0.4);

    final buttonSize = ResponsiveSizing.cornerButtonSize(context);
    final iconSz = ResponsiveSizing.cornerButtonIconSize(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: buttonColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: ResponsiveSizing.spacing(context, 8),
              offset: Offset(0, ResponsiveSizing.spacing(context, 2)),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: iconSz,
        ),
      ),
    );
  }

  Widget _buildPhaseCompleteDialog() {
    final dialogHeight = ResponsiveSizing.dialogHeight(context);
    final dialogWidth = ResponsiveSizing.dialogWidth(context);
    final pos = ResponsiveSizing.positionOffset(context, 12);
    final captionPadding = ResponsiveSizing.spacing(context, 16);
    final captionBottom = ResponsiveSizing.spacing(context, 20);

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: ResponsiveSizing.borderRadius(context, 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: ResponsiveSizing.spacing(context, 24),
            offset: Offset(0, ResponsiveSizing.spacing(context, 12)),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed gradient background
          Container(
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
          ),

          // Large watermark icon
          Center(
            child: Icon(
              Icons.child_care,
              size: ResponsiveSizing.iconSize(context, 160),
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),

          // Gradient overlay at bottom for caption readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: dialogHeight * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF5D9936).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),

          // Caption at bottom
          Positioned(
            left: captionPadding,
            right: captionPadding,
            bottom: captionBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Growing Up!',
                  style: GoogleFonts.caveat(
                    fontSize: ResponsiveSizing.fontSize(context, 36),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: ResponsiveSizing.spacing(context, 8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveSizing.spacing(context, 4)),
                Text(
                  'Time to take your first steps...',
                  style: GoogleFonts.caveat(
                    fontSize: ResponsiveSizing.fontSize(context, 22),
                    color: Colors.white.withValues(alpha: 0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: ResponsiveSizing.spacing(context, 8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Go forward button (arrow) - top right (only action for this dialog)
          Positioned(
            top: pos,
            right: pos,
            child: _buildCornerButton(
              icon: Icons.arrow_forward,
              onTap: _onPhaseTransition,
              isAccent: true,
              accentColor: Colors.white,
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
    final dialogHeight = ResponsiveSizing.dialogHeight(context);
    final dialogWidth = ResponsiveSizing.dialogWidth(context);
    final pos = ResponsiveSizing.positionOffset(context, 12);
    final captionPadding = ResponsiveSizing.spacing(context, 16);
    final captionBottom = ResponsiveSizing.spacing(context, 20);

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: ResponsiveSizing.borderRadius(context, 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: ResponsiveSizing.spacing(context, 24),
            offset: Offset(0, ResponsiveSizing.spacing(context, 12)),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed hero image - always use exit hero image
          Image.asset(
            'assets/photos/exit_hero_image.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF4CAF50),
                child: Center(
                  child: Icon(
                    Icons.directions_car,
                    size: ResponsiveSizing.iconSize(context, 64),
                    color: Colors.white54,
                  ),
                ),
              );
            },
          ),

          // Gradient overlay at bottom for caption readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: dialogHeight * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Caption at bottom
          Positioned(
            left: captionPadding,
            right: captionPadding,
            bottom: captionBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ready for Adventure!',
                  style: GoogleFonts.caveat(
                    fontSize: ResponsiveSizing.fontSize(context, 32),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: ResponsiveSizing.spacing(context, 8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveSizing.spacing(context, 4)),
                Text(
                  '🎄 Merry Christmas! 🎄',
                  style: GoogleFonts.caveat(
                    fontSize: ResponsiveSizing.fontSize(context, 22),
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: ResponsiveSizing.spacing(context, 8),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button (X) - top left
          Positioned(
            top: pos,
            left: pos,
            child: _buildCornerButton(
              icon: Icons.close,
              onTap: _closeOverlay,
              isAccent: false,
            ),
          ),

          // Go forward button (arrow) - top right
          Positioned(
            top: pos,
            right: pos,
            child: _buildCornerButton(
              icon: Icons.arrow_forward,
              onTap: _onStartRoadTrip,
              isAccent: true,
              accentColor: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndgameNotReadyDialog() {
    final dialogHeight = ResponsiveSizing.dialogHeight(context);
    final dialogWidth = ResponsiveSizing.dialogWidth(context);
    final pos = ResponsiveSizing.positionOffset(context, 12);
    final captionPadding = ResponsiveSizing.spacing(context, 16);
    final captionBottom = ResponsiveSizing.spacing(context, 20);
    final collected = widget.game.memoriesCollected;
    final total = widget.game.totalMemories;

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: ResponsiveSizing.borderRadius(context, 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: ResponsiveSizing.spacing(context, 24),
            offset: Offset(0, ResponsiveSizing.spacing(context, 12)),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed hero image with desaturation
          if (memory != null)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.grey.withValues(alpha: 0.6),
                BlendMode.saturation,
              ),
              child: Image.asset(
                memory!.stylizedPhotoPath,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade600,
                    child: Center(
                      child: Icon(
                        Icons.directions_car,
                        size: ResponsiveSizing.iconSize(context, 64),
                        color: Colors.white30,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Dark overlay for locked effect
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

          // Gradient overlay at bottom for caption readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: dialogHeight * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),

          // Lock icon in center
          Center(
            child: Container(
              width: ResponsiveSizing.dimension(context, 64),
              height: ResponsiveSizing.dimension(context, 64),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                color: Colors.white70,
                size: ResponsiveSizing.iconSize(context, 32),
              ),
            ),
          ),

          // Caption and progress at bottom
          Positioned(
            left: captionPadding,
            right: captionPadding,
            bottom: captionBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Not Quite Ready Yet...',
                  style: GoogleFonts.caveat(
                    fontSize: ResponsiveSizing.fontSize(context, 28),
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: ResponsiveSizing.spacing(context, 8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveSizing.spacing(context, 8)),
                // Progress indicator
                Container(
                  padding: ResponsiveSizing.paddingSymmetric(
                    context,
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: ResponsiveSizing.borderRadius(context, 20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library,
                        color: const Color(0xFFD4A574),
                        size: ResponsiveSizing.iconSize(context, 18),
                      ),
                      SizedBox(width: ResponsiveSizing.spacing(context, 8)),
                      Text(
                        '$collected / $total memories',
                        style: GoogleFonts.caveat(
                          fontSize: ResponsiveSizing.fontSize(context, 18),
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button (X) - top left (only button for this dialog)
          Positioned(
            top: pos,
            left: pos,
            child: _buildCornerButton(
              icon: Icons.close,
              onTap: _closeOverlay,
              isAccent: false,
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

  Widget _buildCouponDialog() {
    final dialogHeight = ResponsiveSizing.dialogHeight(context);
    final dialogWidth = ResponsiveSizing.dialogWidth(context);
    final pos = ResponsiveSizing.positionOffset(context, 12);
    final captionPadding = ResponsiveSizing.spacing(context, 16);
    final captionBottom = ResponsiveSizing.spacing(context, 20);

    // Get coupon text from memory or use default
    final couponText = memory?.couponText ?? 'One Free Purse Shopping Trip!';

    return Container(
      width: dialogWidth,
      height: dialogHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: ResponsiveSizing.borderRadius(context, 20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: ResponsiveSizing.spacing(context, 24),
            offset: Offset(0, ResponsiveSizing.spacing(context, 12)),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-bleed hero image
          if (memory != null)
            Image.asset(
              memory!.stylizedPhotoPath,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFE91E63),
                  child: Center(
                    child: Icon(
                      Icons.card_giftcard,
                      size: ResponsiveSizing.iconSize(context, 64),
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),

          // Gradient overlay at bottom for caption readability
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: dialogHeight * 0.55,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          // Caption at bottom with coupon styling
          Positioned(
            left: captionPadding,
            right: captionPadding,
            bottom: captionBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Gift icon
                Container(
                  width: ResponsiveSizing.dimension(context, 56),
                  height: ResponsiveSizing.dimension(context, 56),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE91E63),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.4),
                        blurRadius: ResponsiveSizing.spacing(context, 12),
                        spreadRadius: ResponsiveSizing.spacing(context, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.white,
                    size: ResponsiveSizing.iconSize(context, 28),
                  ),
                ),
                SizedBox(height: ResponsiveSizing.spacing(context, 12)),

                // Coupon unlocked text
                Text(
                  'Coupon Unlocked!',
                  style: GoogleFonts.caveat(
                    fontSize: ResponsiveSizing.fontSize(context, 32),
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: ResponsiveSizing.spacing(context, 8),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveSizing.spacing(context, 8)),

                // Coupon details in a ticket-style container
                Container(
                  padding: ResponsiveSizing.paddingSymmetric(
                    context,
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: ResponsiveSizing.borderRadius(context, 12),
                    border: Border.all(
                      color: const Color(0xFFE91E63),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: ResponsiveSizing.spacing(context, 8),
                        offset: Offset(0, ResponsiveSizing.spacing(context, 2)),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        couponText,
                        style: GoogleFonts.caveat(
                          fontSize: ResponsiveSizing.fontSize(context, 22),
                          color: const Color(0xFFE91E63),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: ResponsiveSizing.spacing(context, 4)),
                      Text(
                        'Valid: Anytime Mom wants!',
                        style: TextStyle(
                          fontSize: ResponsiveSizing.fontSize(context, 12),
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close button (X) - top right
          Positioned(
            top: pos,
            right: pos,
            child: _buildCornerButton(
              icon: Icons.close,
              onTap: _closeOverlay,
              isAccent: false,
            ),
          ),
        ],
      ),
    );
  }
}
