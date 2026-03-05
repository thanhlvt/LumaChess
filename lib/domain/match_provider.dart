import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luma_chess/domain/i_chess_engine.dart';
import 'package:luma_chess/domain/engine_config.dart';
import 'match_controller.dart';
import 'match_state.dart';

/// Provider for the chess engine instance.
/// It will be overridden in main.dart after setupDependencyInjection.
final chessEngineProvider = Provider<IChessEngine>((ref) {
  throw UnimplementedError('chessEngineProvider must be overridden');
});

class EngineConfigNotifier extends Notifier<EngineConfig> {
  @override
  EngineConfig build() => EngineConfig.fromDifficulty(DifficultyLevel.medium);

  void updateConfig(EngineConfig config) {
    state = config;
  }
}

/// Provider for the current engine configuration.
final engineConfigProvider =
    NotifierProvider<EngineConfigNotifier, EngineConfig>(() {
      return EngineConfigNotifier();
    });

final matchProvider = NotifierProvider<MatchController, MatchState>(() {
  return MatchController();
});
