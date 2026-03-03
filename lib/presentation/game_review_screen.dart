import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squares/squares.dart';
import 'package:chess/chess.dart' as chess_lib;
import 'package:enterprise_chess/domain/game_history.dart';
import 'package:enterprise_chess/domain/user_settings_provider.dart';
import 'package:enterprise_chess/presentation/utils/chess_board_builder.dart';
import 'package:enterprise_chess/presentation/utils/chess_coordinate_utils.dart';

class GameReviewScreen extends ConsumerStatefulWidget {
  final GameHistory gameHistory;

  const GameReviewScreen({super.key, required this.gameHistory});

  @override
  ConsumerState<GameReviewScreen> createState() => _GameReviewScreenState();
}

class _GameReviewScreenState extends ConsumerState<GameReviewScreen> {
  final List<String> _fenHistory = [];
  final List<Move> _moveHistory = [];
  int _currentMoveIndex = 0;

  @override
  void initState() {
    super.initState();
    _parsePgn();
  }

  void _parsePgn() {
    final chess = chess_lib.Chess();

    // Attempt to load PGN
    final ok = chess.load_pgn(widget.gameHistory.pgn);
    if (!ok && widget.gameHistory.pgn.isNotEmpty) {
      // If load_pgn fails, sometimes it's because of strict headers.
      // But the package 'chess' handles most standard PGNs.
      debugPrint("Failed to load PGN: ${widget.gameHistory.pgn}");
    }

    final moves = chess.history;

    // Now we replay the moves from a clean board to capture FENs at each step.
    final replayChess = chess_lib.Chess();
    _fenHistory.add(replayChess.fen); // Initial board

    for (var entry in moves) {
      final move = entry.move;
      // Convert to algebraic squares for squares package
      final from = move.fromAlgebraic;
      final to = move.toAlgebraic;
      int fromSquare = ChessCoordinateUtils.algebraicToSquareIndex(from);
      int toSquare = ChessCoordinateUtils.algebraicToSquareIndex(to);

      _moveHistory.add(Move(from: fromSquare, to: toSquare));

      replayChess.move({
        'from': from,
        'to': to,
        'promotion': move.promotion?.name ?? 'q',
      });
      _fenHistory.add(replayChess.fen);
    }
  }

  void _nextMove() {
    if (_currentMoveIndex < _fenHistory.length - 1) {
      setState(() {
        _currentMoveIndex++;
      });
    }
  }

  void _previousMove() {
    if (_currentMoveIndex > 0) {
      setState(() {
        _currentMoveIndex--;
      });
    }
  }

  void _goToStart() {
    setState(() {
      _currentMoveIndex = 0;
    });
  }

  void _goToEnd() {
    setState(() {
      _currentMoveIndex = _fenHistory.length - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSettings = ref.watch(userSettingsProvider);

    Map<String, dynamic>? lastMoveObj;
    if (_currentMoveIndex > 0 && _currentMoveIndex <= _moveHistory.length) {
      final lastMove = _moveHistory[_currentMoveIndex - 1];
      lastMoveObj = {
        'from': ChessCoordinateUtils.squareToAlgebraic(lastMove.from),
        'to': ChessCoordinateUtils.squareToAlgebraic(lastMove.to),
      };
    }

    final String currentFen = _fenHistory.isEmpty
        ? chess_lib.Chess().fen
        : _fenHistory[_currentMoveIndex];

    final boardState = ChessBoardBuilder.buildBoardState(
      currentFen,
      orientation: Squares.white,
      lastMove: lastMoveObj,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Game Review'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Players and Result Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: const Color(0xFF1A237E).withValues(alpha: 0.3),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.gameHistory.player1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'vs',
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        widget.gameHistory.player2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.gameHistory.result,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Chess Board
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AbsorbPointer(
                    // Disable board interaction
                    child: BoardController(
                      state: boardState,
                      playState: PlayState.observing,
                      pieceSet: userSettings.pieceSet,
                      theme: userSettings.theme,
                    ),
                  ),
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.2),
                border: const Border(top: BorderSide(color: Colors.white24)),
              ),
              child: Column(
                children: [
                  Text(
                    'Move $_currentMoveIndex of ${_fenHistory.isNotEmpty ? _fenHistory.length - 1 : 0}',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ControlButton(
                        icon: Icons.first_page,
                        onPressed: _currentMoveIndex > 0 ? _goToStart : null,
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        icon: Icons.navigate_before,
                        onPressed: _currentMoveIndex > 0 ? _previousMove : null,
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        icon: Icons.navigate_next,
                        onPressed: _currentMoveIndex < _fenHistory.length - 1
                            ? _nextMove
                            : null,
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        icon: Icons.last_page,
                        onPressed: _currentMoveIndex < _fenHistory.length - 1
                            ? _goToEnd
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _ControlButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed == null ? Colors.white12 : const Color(0xFF283593),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        iconSize: 32,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
