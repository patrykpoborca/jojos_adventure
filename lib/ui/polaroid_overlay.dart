import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/memory_lane_game.dart';

/// Polaroid-style overlay for displaying photo memories
class PolaroidOverlay extends StatelessWidget {
  final MemoryLaneGame game;

  const PolaroidOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final memory = game.currentMemory;

    return Material(
      color: Colors.black54,
      child: Center(
        child: Transform.rotate(
          angle: 0.05, // Slight tilt for Polaroid feel
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF7), // Off-white
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
                // Photo area
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
                          memory.photoPath,
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
                    memory.date,
                    style: GoogleFonts.caveat(
                      fontSize: 16,
                      color: const Color(0xFF6B5B4F),
                    ),
                  ),
                const SizedBox(height: 4),

                // Caption
                if (memory != null)
                  Text(
                    memory.caption,
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      color: const Color(0xFF3C3C3C),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    'A precious memory...',
                    style: GoogleFonts.caveat(
                      fontSize: 22,
                      color: const Color(0xFF3C3C3C),
                    ),
                  ),
                const SizedBox(height: 20),

                // Continue button
                ElevatedButton(
                  onPressed: () => game.resumeGame(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A574),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
