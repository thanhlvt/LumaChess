import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'engine_config.dart';

/// Identifies the game mode selected from the main menu.
enum GameMode { pve, pvp }

/// Holds all configuration choices the player made in the setup screen
/// before starting a game.
class GameConfig {
  /// Whether the local player is playing against the computer or another human.
  final GameMode mode;

  /// The side the local player (or player 1 in PvP) is playing as.
  /// 'white' | 'black' | 'random' (resolved before use in the game screen).
  final String playerSide;

  /// The difficulty level for PvE games. Ignored in PvP mode.
  final DifficultyLevel difficulty;

  const GameConfig({
    this.mode = GameMode.pve,
    this.playerSide = 'white',
    this.difficulty = DifficultyLevel.medium,
  });

  GameConfig copyWith({
    GameMode? mode,
    String? playerSide,
    DifficultyLevel? difficulty,
  }) {
    return GameConfig(
      mode: mode ?? this.mode,
      playerSide: playerSide ?? this.playerSide,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  /// Resolves 'random' into an actual side by using the current time.
  String get resolvedSide {
    if (playerSide == 'random') {
      return DateTime.now().millisecond.isEven ? 'white' : 'black';
    }
    return playerSide;
  }
}

/// Notifier for [GameConfig] — Riverpod v3 compatible (no legacy StateProvider).
class GameConfigNotifier extends Notifier<GameConfig> {
  @override
  GameConfig build() => const GameConfig();

  void update(GameConfig config) => state = config;
}

/// Global provider for the current game configuration.
final gameConfigProvider = NotifierProvider<GameConfigNotifier, GameConfig>(
  GameConfigNotifier.new,
);
