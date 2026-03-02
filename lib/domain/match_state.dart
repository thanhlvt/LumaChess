/// Immutable state representing the current chess match.
/// Used as the Riverpod provider state instead of a raw FEN string.
class MatchState {
  final String fen;
  final bool isWhiteTurn;
  final bool isCheck;
  final bool isCheckmate;
  final bool isDraw;
  final bool isGameOver;

  /// The side the local player is playing as: 'white' or 'black'.
  /// Used by the UI to orient the board and determine whose turn it is.
  final String playerSide;

  /// True if the last move made was a capture. Used for sound effects.
  final bool lastMoveWasCapture;

  /// True if there is at least one move to undo.
  final bool canUndo;

  const MatchState({
    required this.fen,
    this.isWhiteTurn = true,
    this.isCheck = false,
    this.isCheckmate = false,
    this.isDraw = false,
    this.isGameOver = false,
    this.playerSide = 'white',
    this.lastMoveWasCapture = false,
    this.canUndo = false,
  });

  MatchState copyWith({
    String? fen,
    bool? isWhiteTurn,
    bool? isCheck,
    bool? isCheckmate,
    bool? isDraw,
    bool? isGameOver,
    String? playerSide,
    bool? lastMoveWasCapture,
    bool? canUndo,
  }) {
    return MatchState(
      fen: fen ?? this.fen,
      isWhiteTurn: isWhiteTurn ?? this.isWhiteTurn,
      isCheck: isCheck ?? this.isCheck,
      isCheckmate: isCheckmate ?? this.isCheckmate,
      isDraw: isDraw ?? this.isDraw,
      isGameOver: isGameOver ?? this.isGameOver,
      playerSide: playerSide ?? this.playerSide,
      lastMoveWasCapture: lastMoveWasCapture ?? this.lastMoveWasCapture,
      canUndo: canUndo ?? this.canUndo,
    );
  }
}
