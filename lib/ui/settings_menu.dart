import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/audio/audio_manager.dart';
import '../game/memory_lane_game.dart';
import 'responsive_sizing.dart';

/// Settings menu overlay
class SettingsMenu extends StatefulWidget {
  final MemoryLaneGame game;

  const SettingsMenu({super.key, required this.game});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;

  // Local copies of volume values for slider updates
  late double _masterVolume;
  late double _musicVolume;
  late double _sfxVolume;

  @override
  void initState() {
    super.initState();

    // Initialize volume values from AudioManager
    _masterVolume = AudioManager().masterVolume;
    _musicVolume = AudioManager().musicVolume;
    _sfxVolume = AudioManager().sfxVolume;

    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _closeSettings() {
    _animController.reverse().then((_) {
      widget.game.hideSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black54,
        child: SafeArea(
          child: Stack(
            children: [
              // Tap outside to close
              GestureDetector(
                onTap: _closeSettings,
                behavior: HitTestBehavior.opaque,
              ),
              // Settings card
              Center(
                child: GestureDetector(
                  onTap: () {}, // Prevent tap-through
                  child: Container(
                    width: ResponsiveSizing.dimension(context, 340),
                    margin: ResponsiveSizing.paddingAll(context, 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF7),
                      borderRadius: ResponsiveSizing.borderRadius(context, 16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: ResponsiveSizing.spacing(context, 20),
                          offset: Offset(0, ResponsiveSizing.spacing(context, 10)),
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: ResponsiveSizing.screenHeight(context) * 0.8,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            _buildAudioSection(),
                            _buildDivider(),
                            _buildControlModeSection(),
                            _buildDivider(),
                            _buildFloorSection(),
                            _buildDivider(),
                            _buildPhaseSection(),
                            _buildDivider(),
                            _buildDebugSection(),
                            SizedBox(height: ResponsiveSizing.spacing(context, 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final radius = ResponsiveSizing.spacing(context, 16);
    return Container(
      padding: ResponsiveSizing.paddingSymmetric(
        context,
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A574),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Settings',
            style: GoogleFonts.caveat(
              fontSize: ResponsiveSizing.fontSize(context, 28),
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _closeSettings,
            icon: Icon(
              Icons.close,
              color: Colors.white,
              size: ResponsiveSizing.iconSize(context, 24),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final indent = ResponsiveSizing.spacing(context, 20);
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: indent,
      endIndent: indent,
    );
  }

  Widget _buildAudioSection() {
    return Padding(
      padding: ResponsiveSizing.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Audio'),
          SizedBox(height: ResponsiveSizing.spacing(context, 12)),
          _buildVolumeSlider(
            label: 'Master',
            value: _masterVolume,
            onChanged: (value) {
              setState(() => _masterVolume = value);
              AudioManager().masterVolume = value;
            },
          ),
          SizedBox(height: ResponsiveSizing.spacing(context, 8)),
          _buildVolumeSlider(
            label: 'Music',
            value: _musicVolume,
            onChanged: (value) {
              setState(() => _musicVolume = value);
              AudioManager().musicVolume = value;
            },
          ),
          SizedBox(height: ResponsiveSizing.spacing(context, 8)),
          _buildVolumeSlider(
            label: 'SFX',
            value: _sfxVolume,
            onChanged: (value) {
              setState(() => _sfxVolume = value);
              AudioManager().sfxVolume = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: ResponsiveSizing.fontSize(context, 12),
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: ResponsiveSizing.dimension(context, 55),
          child: Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSizing.fontSize(context, 14),
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFD4A574),
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: const Color(0xFFD4A574),
              overlayColor: const Color(0xFFD4A574).withValues(alpha: 0.2),
              trackHeight: ResponsiveSizing.spacing(context, 4),
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: ResponsiveSizing.spacing(context, 8),
              ),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: ResponsiveSizing.dimension(context, 36),
          child: Text(
            '${(value * 100).round()}',
            style: TextStyle(
              fontSize: ResponsiveSizing.fontSize(context, 12),
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildControlModeSection() {
    final currentMode = widget.game.controlMode;

    return Padding(
      padding: ResponsiveSizing.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Controls'),
          SizedBox(height: ResponsiveSizing.spacing(context, 12)),
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: 'Joystick',
                  isSelected: currentMode == MovementControlMode.joystick,
                  onTap: () {
                    widget.game.setControlMode(MovementControlMode.joystick);
                    setState(() {});
                  },
                ),
              ),
              SizedBox(width: ResponsiveSizing.spacing(context, 12)),
              Expanded(
                child: _buildToggleButton(
                  label: 'Touch',
                  isSelected: currentMode == MovementControlMode.positional,
                  onTap: () {
                    widget.game.setControlMode(MovementControlMode.positional);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveSizing.spacing(context, 8)),
          Text(
            currentMode == MovementControlMode.joystick
                ? 'Fixed joystick in corner'
                : 'Touch anywhere to move',
            style: TextStyle(
              fontSize: ResponsiveSizing.fontSize(context, 11),
              color: Colors.grey.shade500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorSection() {
    final currentLevel = widget.game.currentLevel;

    return Padding(
      padding: ResponsiveSizing.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Floor'),
          SizedBox(height: ResponsiveSizing.spacing(context, 12)),
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: 'Main Floor',
                  isSelected: currentLevel == LevelId.mainFloor,
                  onTap: () async {
                    if (currentLevel != LevelId.mainFloor) {
                      await widget.game.switchToLevel(LevelId.mainFloor);
                      setState(() {});
                    }
                  },
                ),
              ),
              SizedBox(width: ResponsiveSizing.spacing(context, 12)),
              Expanded(
                child: _buildToggleButton(
                  label: 'Upstairs',
                  isSelected: currentLevel == LevelId.upstairsNursery,
                  onTap: () async {
                    if (currentLevel != LevelId.upstairsNursery) {
                      await widget.game.switchToLevel(LevelId.upstairsNursery);
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseSection() {
    final currentPhase = widget.game.currentPhase;

    return Padding(
      padding: ResponsiveSizing.paddingSymmetric(context, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Phase'),
          SizedBox(height: ResponsiveSizing.spacing(context, 12)),
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: 'Crawling',
                  isSelected: currentPhase == GamePhase.crawling,
                  onTap: () async {
                    if (currentPhase != GamePhase.crawling) {
                      await widget.game.togglePhase();
                      setState(() {});
                    }
                  },
                ),
              ),
              SizedBox(width: ResponsiveSizing.spacing(context, 12)),
              Expanded(
                child: _buildToggleButton(
                  label: 'Walking',
                  isSelected: currentPhase == GamePhase.walking,
                  onTap: () async {
                    if (currentPhase != GamePhase.walking) {
                      await widget.game.togglePhase();
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    final isDebugEnabled = MemoryLaneGame.showDebugPanel;

    return Padding(
      padding: ResponsiveSizing.paddingSymmetric(context, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ResponsiveSizing.spacing(context, 12)),
          _buildSectionTitle('Developer'),
          SizedBox(height: ResponsiveSizing.spacing(context, 12)),
          Row(
            children: [
              Expanded(
                child: _buildToggleButton(
                  label: 'Debug Off',
                  isSelected: !isDebugEnabled,
                  onTap: () {
                    if (isDebugEnabled) {
                      widget.game.toggleDebugPanel();
                      setState(() {});
                    }
                  },
                ),
              ),
              SizedBox(width: ResponsiveSizing.spacing(context, 12)),
              Expanded(
                child: _buildToggleButton(
                  label: 'Debug On',
                  isSelected: isDebugEnabled,
                  onTap: () {
                    if (!isDebugEnabled) {
                      widget.game.toggleDebugPanel();
                      setState(() {});
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveSizing.paddingSymmetric(context, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A574) : Colors.grey.shade100,
          borderRadius: ResponsiveSizing.borderRadius(context, 10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A574) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: ResponsiveSizing.fontSize(context, 14),
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
