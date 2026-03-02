import 'move_analysis.dart';

/// Represents a running analysis task that can be cancelled.
class AnalysisTask {
  final Future<List<MoveAnalysis>> result;
  final void Function() cancel;

  AnalysisTask({required this.result, required this.cancel});
}

/// Abstract interface for post-game analysis to decouple the presentation 
/// layer from the infrastructure layer (Stockfish).
abstract class IAnalysisService {
  /// Runs a full post-game analysis on a list of FEN positions.
  /// Returns an [AnalysisTask] which contains the future result and a cancellation token.
  AnalysisTask analyzeGame({
    required List<String> fenHistory,
    required List<String> moveHistory,
    void Function(double progress)? onProgress,
  });
}
