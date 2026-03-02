import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_chess/domain/game_config.dart';
import 'package:enterprise_chess/domain/engine_config.dart';
import 'pve_screen.dart';

/// Setup screen shown after the user taps "Play vs Computer".
/// Allows selection of piece color and difficulty level.
class GameSetupScreen extends ConsumerStatefulWidget {
  const GameSetupScreen({super.key});

  @override
  ConsumerState<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends ConsumerState<GameSetupScreen> {
  String _selectedSide = 'white';
  DifficultyLevel _selectedDifficulty = DifficultyLevel.medium;

  static const _sideOptions = [
    {'value': 'white', 'label': 'White', 'icon': '♔'},
    {'value': 'random', 'label': 'Random', 'icon': '🎲'},
    {'value': 'black', 'label': 'Black', 'icon': '♚'},
  ];

  static const _difficulties = DifficultyLevel.values;

  static const _difficultyColors = {
    DifficultyLevel.easy: Color(0xFF4CAF50),
    DifficultyLevel.medium: Color(0xFF2196F3),
    DifficultyLevel.hard: Color(0xFFFF9800),
    DifficultyLevel.expert: Color(0xFFE91E63),
    DifficultyLevel.champion: Color(0xFF9C27B0),
  };

  static const _difficultyIcons = {
    DifficultyLevel.easy: Icons.sentiment_very_satisfied,
    DifficultyLevel.medium: Icons.sentiment_satisfied,
    DifficultyLevel.hard: Icons.whatshot,
    DifficultyLevel.expert: Icons.psychology,
    DifficultyLevel.champion: Icons.emoji_events,
  };

  void _startGame() {
    // Resolve 'random' here so both domain and UI use the same resolved value
    final resolvedSide =
        _selectedSide == 'random'
            ? (Random().nextBool() ? 'white' : 'black')
            : _selectedSide;

    final config = GameConfig(
      mode: GameMode.pve,
      playerSide: resolvedSide,
      difficulty: _selectedDifficulty,
    );

    ref.read(gameConfigProvider.notifier).update(config);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PvEScreen(
          playerSide: resolvedSide,
          engineConfig: EngineConfig.fromDifficulty(_selectedDifficulty),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── App Bar Row ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Game Setup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Color Picker ──────────────────────────────
                        const Text(
                          'Choose your color',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: _sideOptions
                              .map((opt) => _SideCard(
                                    value: opt['value']!,
                                    label: opt['label']!,
                                    icon: opt['icon']!,
                                    isSelected: _selectedSide == opt['value'],
                                    onTap: () => setState(
                                        () => _selectedSide = opt['value']!),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 36),

                        // ── Difficulty Picker ─────────────────────────
                        const Text(
                          'Difficulty',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: _difficulties
                              .map((level) => _DifficultyTile(
                                    level: level,
                                    color: _difficultyColors[level]!,
                                    icon: _difficultyIcons[level]!,
                                    isSelected: _selectedDifficulty == level,
                                    onTap: () => setState(
                                        () => _selectedDifficulty = level),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 40),

                        // ── Play Button ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _startGame,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text(
                              'Play',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 8,
                            ),
                          ),
                        ),
                      ],
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
}

// ── Side selection card ────────────────────────────────────────────────────────

class _SideCard extends StatelessWidget {
  final String value;
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white24,
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.amber : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Difficulty tile ────────────────────────────────────────────────────────────

class _DifficultyTile extends StatelessWidget {
  final DifficultyLevel level;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.level,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final config = EngineConfig.fromDifficulty(level);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  EngineConfig.labelFor(level),
                  style: TextStyle(
                    color: isSelected ? color : Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Skill ${config.skillLevel} · ${config.moveTimeMs}ms think time',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 22),
          ],
        ),
      ),
    );
  }
}
