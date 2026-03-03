import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enterprise_chess/domain/game_config.dart';
import 'package:enterprise_chess/domain/engine_config.dart';
import 'cpu_vs_cpu_screen.dart';

class CpuSetupScreen extends ConsumerStatefulWidget {
  const CpuSetupScreen({super.key});

  @override
  ConsumerState<CpuSetupScreen> createState() => _CpuSetupScreenState();
}

class _CpuSetupScreenState extends ConsumerState<CpuSetupScreen> {
  late DifficultyLevel _whiteDifficulty;
  late DifficultyLevel _blackDifficulty;

  static const _whiteDiffKey = 'cpu_white_difficulty';
  static const _blackDiffKey = 'cpu_black_difficulty';

  @override
  void initState() {
    super.initState();
    _whiteDifficulty = DifficultyLevel.medium;
    _blackDifficulty = DifficultyLevel.medium;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final wDiff = prefs.getString(_whiteDiffKey);
    if (wDiff != null) {
      try {
        _whiteDifficulty = DifficultyLevel.values.firstWhere(
          (e) => e.name == wDiff,
        );
      } catch (_) {}
    }

    final bDiff = prefs.getString(_blackDiffKey);
    if (bDiff != null) {
      try {
        _blackDifficulty = DifficultyLevel.values.firstWhere(
          (e) => e.name == bDiff,
        );
      } catch (_) {}
    }

    if (mounted) setState(() {});
  }

  Future<void> _savePreference(String key, DifficultyLevel diff) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, diff.name);
  }

  static const _difficulties = DifficultyLevel.values;
  static const _difficultyColors = {
    DifficultyLevel.easy: Color(0xFF4CAF50),
    DifficultyLevel.medium: Color(0xFF2196F3),
    DifficultyLevel.hard: Color(0xFFFF9800),
    DifficultyLevel.expert: Color(0xFFE91E63),
    DifficultyLevel.champion: Color(0xFF9C27B0),
  };

  void _startGame() {
    final config = const GameConfig(mode: GameMode.cpu, playerSide: 'none');
    ref.read(gameConfigProvider.notifier).update(config);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CpuVsCpuScreen(
          whiteConfig: EngineConfig.fromDifficulty(_whiteDifficulty),
          blackConfig: EngineConfig.fromDifficulty(_blackDifficulty),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'CPU vs CPU Setup',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // White CPU
                      _buildSectionTitle(
                        'White CPU Difficulty',
                        Icons.computer,
                        Colors.white,
                      ),
                      const SizedBox(height: 12),
                      _buildDifficultySelector(
                        selectedValue: _whiteDifficulty,
                        onChanged: (val) {
                          setState(() => _whiteDifficulty = val);
                          _savePreference(_whiteDiffKey, val);
                        },
                      ),

                      const SizedBox(height: 36),

                      // Black CPU
                      _buildSectionTitle(
                        'Black CPU Difficulty',
                        Icons.computer,
                        Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      _buildDifficultySelector(
                        selectedValue: _blackDifficulty,
                        onChanged: (val) {
                          setState(() => _blackDifficulty = val);
                          _savePreference(_blackDiffKey, val);
                        },
                      ),

                      const SizedBox(height: 40),

                      // Start button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _startGame,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text(
                            'Start Match',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySelector({
    required DifficultyLevel selectedValue,
    required ValueChanged<DifficultyLevel> onChanged,
  }) {
    return Column(
      children: _difficulties.map((level) {
        final color = _difficultyColors[level]!;
        final isSelected = selectedValue == level;

        return GestureDetector(
          onTap: () => onChanged(level),
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
                Text(
                  EngineConfig.labelFor(level),
                  style: TextStyle(
                    color: isSelected ? color : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 22),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
