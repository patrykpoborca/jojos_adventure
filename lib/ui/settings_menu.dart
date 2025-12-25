import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/audio/audio_manager.dart';
import '../game/memory_lane_game.dart';

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
                    width: 340,
                    margin: const EdgeInsets.all(24),
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
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            _buildAudioSection(),
                            _buildDivider(),
                            _buildFloorSection(),
                            _buildDivider(),
                            _buildPhaseSection(),
                            const SizedBox(height: 16),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFD4A574),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Settings',
            style: GoogleFonts.caveat(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _closeSettings,
            icon: const Icon(Icons.close, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.shade200,
      indent: 20,
      endIndent: 20,
    );
  }

  Widget _buildAudioSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Audio'),
          const SizedBox(height: 12),
          _buildVolumeSlider(
            label: 'Master',
            value: _masterVolume,
            onChanged: (value) {
              setState(() => _masterVolume = value);
              AudioManager().masterVolume = value;
            },
          ),
          const SizedBox(height: 8),
          _buildVolumeSlider(
            label: 'Music',
            value: _musicVolume,
            onChanged: (value) {
              setState(() => _musicVolume = value);
              AudioManager().musicVolume = value;
            },
          ),
          const SizedBox(height: 8),
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
        fontSize: 12,
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
          width: 55,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
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
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildFloorSection() {
    final currentLevel = widget.game.currentLevel;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Floor'),
          const SizedBox(height: 12),
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
              const SizedBox(width: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Phase'),
          const SizedBox(height: 12),
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
              const SizedBox(width: 12),
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

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4A574) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4A574) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
