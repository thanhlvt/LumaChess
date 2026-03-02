/// Difficulty levels supported by the chess engine.
enum DifficultyLevel { easy, medium, hard, expert, champion }

/// Configuration for the chess engine calculation parameters.
/// Passed through DI so it can be changed without touching UI code.
class EngineConfig {
  /// Time in milliseconds the engine is allowed to think per move.
  final int moveTimeMs;

  /// Search depth limit (0 = unlimited, let movetime control).
  final int depth;

  /// Stockfish skill level (0-20). Higher is stronger.
  final int skillLevel;

  /// The difficulty level this config represents (for display purposes).
  final DifficultyLevel difficulty;

  const EngineConfig({
    this.moveTimeMs = 1500,
    this.depth = 0,
    this.skillLevel = 20,
    this.difficulty = DifficultyLevel.champion,
  });

  /// Creates an [EngineConfig] tuned for a specific [DifficultyLevel].
  ///
  /// | Level    | Skill (0-20) | Time (ms) |
  /// |----------|-------------|-----------|
  /// | easy     | 1           | 500       |
  /// | medium   | 5           | 1000      |
  /// | hard     | 10          | 1500      |
  /// | expert   | 16          | 2000      |
  /// | champion | 20          | 3000      |
  factory EngineConfig.fromDifficulty(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return const EngineConfig(
          skillLevel: 1,
          moveTimeMs: 500,
          difficulty: DifficultyLevel.easy,
        );
      case DifficultyLevel.medium:
        return const EngineConfig(
          skillLevel: 5,
          moveTimeMs: 1000,
          difficulty: DifficultyLevel.medium,
        );
      case DifficultyLevel.hard:
        return const EngineConfig(
          skillLevel: 10,
          moveTimeMs: 1500,
          difficulty: DifficultyLevel.hard,
        );
      case DifficultyLevel.expert:
        return const EngineConfig(
          skillLevel: 16,
          moveTimeMs: 2000,
          difficulty: DifficultyLevel.expert,
        );
      case DifficultyLevel.champion:
        return const EngineConfig(
          skillLevel: 20,
          moveTimeMs: 3000,
          difficulty: DifficultyLevel.champion,
        );
    }
  }

  /// Human-readable label for the difficulty level.
  static String labelFor(DifficultyLevel level) {
    switch (level) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.expert:
        return 'Expert';
      case DifficultyLevel.champion:
        return 'Champion';
    }
  }
}
