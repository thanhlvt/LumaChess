import 'package:squares/squares.dart';

class ChessCoordinateUtils {
  /// Converts a fast-chess square index (0-63) to algebraic notation (e.g., "e2").
  static String squareToAlgebraic(int idx) {
    final file = String.fromCharCode('a'.codeUnitAt(0) + (idx % 8));
    final rank = (8 - (idx ~/ 8)).toString();
    return '$file$rank';
  }

  /// Converts an algebraic notation string (e.g., "e2") to a fast-chess square index (0-63).
  static int algebraicToSquareIndex(String alg) {
    final file = alg.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(alg[1]);
    return (8 - rank) * 8 + file;
  }

  /// Transforms domain algebraic moves to package:squares `Move`s
  static List<Move> getLegalMoves(List<Map<String, String>> domainMoves) {
    final seen = <String>{};
    final result = <Move>[];
    for (final m in domainMoves) {
      final key = '${m['from']}${m['to']}';
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(Move(
        from: algebraicToSquareIndex(m['from']!),
        to: algebraicToSquareIndex(m['to']!),
        promo: null,
      ));
    }
    return result;
  }
}
