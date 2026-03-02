abstract class IChessEngine {
  Future<void> initEngine();
  Future<String> getBestMove(String fen, int timeMs);
  void dispose();

  /// Whether the engine is ready and available on the current platform.
  bool get isAvailable;
}
