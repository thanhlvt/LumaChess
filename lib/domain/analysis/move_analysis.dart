enum MoveCategory {
  best('⭐', 'Tuyệt hảo'),
  excellent('👍', 'Rất tốt'),
  good('✅', 'Tốt'),
  inaccuracy('🤔', 'Không chính xác'),
  mistake('⚠️', 'Lỗi'),
  blunder('❌', 'Nước đi tệ');

  final String icon;
  final String displayName;

  const MoveCategory(this.icon, this.displayName);
}

class MoveAnalysis {
  final int moveNumber;
  final bool isWhite;
  final String playedMove;
  final String bestMove;
  final List<String> alternatives;
  final int evaluation; // Centipawns; if mate, can use large values like 100000 + mate_in
  final int cpl; // Centipawn loss
  final MoveCategory category;
  final String commentary;

  const MoveAnalysis({
    this.moveNumber = 0,
    this.isWhite = true,
    required this.playedMove,
    required this.bestMove,
    this.alternatives = const [],
    required this.evaluation,
    required this.cpl,
    required this.category,
    required this.commentary,
  });

  static MoveCategory calculateCategory(int cpl) {
    if (cpl <= 0) return MoveCategory.best;
    if (cpl > 0 && cpl <= 15) return MoveCategory.excellent;
    if (cpl > 15 && cpl <= 30) return MoveCategory.good;
    if (cpl > 30 && cpl <= 50) return MoveCategory.inaccuracy;
    if (cpl > 50 && cpl <= 100) return MoveCategory.mistake;
    return MoveCategory.blunder;
  }
}
