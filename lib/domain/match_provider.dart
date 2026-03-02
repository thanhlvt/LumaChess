import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_chess/domain/i_chess_engine.dart';
import 'package:enterprise_chess/domain/engine_config.dart';
import 'match_controller.dart';
import 'match_state.dart';
import 'analysis/i_analysis_service.dart';
import '../infrastructure/analysis/post_game_analyzer.dart';

/// Provider for the chess engine instance.
/// It will be overridden in main.dart after setupDependencyInjection.
final chessEngineProvider = Provider<IChessEngine>((ref) {
  throw UnimplementedError('chessEngineProvider must be overridden');
});

class EngineConfigNotifier extends Notifier<EngineConfig> {
  @override
  EngineConfig build() => EngineConfig.fromDifficulty(DifficultyLevel.medium);
}

/// Provider for the current engine configuration.
final engineConfigProvider = NotifierProvider<EngineConfigNotifier, EngineConfig>(() {
  return EngineConfigNotifier();
});

/// Provider for the post-game analysis service.
final analysisServiceProvider = Provider<IAnalysisService>((ref) {
  return PostGameAnalyzer();
});

final matchProvider = NotifierProvider<MatchController, MatchState>(() {
  return MatchController();
});
