import 'package:squares/squares.dart';

class ChessBoardBuilder {
  /// Builds a [BoardState] from a FEN string.
  /// Needs to provide the [orientation] because it can differ in PvE vs PvP.
  static BoardState buildBoardState(String fen, {required int orientation}) {
    if (fen.isEmpty) return BoardState.empty();
    
    final fenParts = fen.split(' ');
    final placement = fenParts[0];
    
    final board = <String>[];
    for (final char in placement.runes) {
      final s = String.fromCharCode(char);
      if (s == '/') continue;
      final n = int.tryParse(s);
      if (n != null) {
        board.addAll(List.filled(n, ''));
      } else {
        board.add(s);
      }
    }
    
    final turn = (fenParts.length > 1 && fenParts[1] == 'b') 
        ? Squares.black 
        : Squares.white;
        
    return BoardState(board: board, turn: turn, orientation: orientation);
  }
}
