import 'package:chess/chess.dart' as chess_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'match_provider.dart';
import 'i_chess_engine.dart';
import 'match_state.dart';
import 'engine_config.dart';

/// Core game controller. Manages chess rules via the pure-Dart [chess_lib.Chess]
/// package and delegates engine calculation to [IChessEngine] resolved via DI.
///
/// Exposes [MatchState] through Riverpod so the UI layer can reactively rebuild.
class MatchController extends Notifier<MatchState> {
  late chess_lib.Chess _chess;

  /// 'white' or 'black' — identifies which side the local player controls.
  /// In PvP, 'white' is always the local turn indicator (board flips each move).
  String _playerSide = 'white';

  /// Whether PvE mode is active (false = PvP).
  bool _isPve = true;

  /// Ordered list of FEN strings captured BEFORE each half-move.
  /// Passed to [PostGameAnalyzer] at the end of the game for deep analysis.
  final List<String> _fenHistory = [];

  List<String> get fenHistory => List.unmodifiable(_fenHistory);

  List<Map<String, String>>? _legalMovesCache;
  List<String>? _moveHistoryCache;

  // ---------------------------------------------------------------------------
  // Riverpod lifecycle
  // ---------------------------------------------------------------------------

  @override
  MatchState build() {
    _chess = chess_lib.Chess();
    return _buildState();
  }

  // ---------------------------------------------------------------------------
  // Game Setup
  // ---------------------------------------------------------------------------

  /// Starts (or restarts) a game with the given configuration.
  ///
  /// [playerSide] should be 'white' or 'black' (already resolved from 'random'
  /// before calling this method).
  /// [config] is the engine difficulty; if null, keeps the existing config.
  /// [isPve] — false for PvP (engine moves are never requested).
  void startGame({
    String playerSide = 'white',
    EngineConfig? config,
    bool isPve = true,
  }) {
    _chess = chess_lib.Chess();
    _fenHistory.clear();
    _playerSide = playerSide;
    _isPve = isPve;
    if (config != null) {
      ref.read(engineConfigProvider.notifier).state = config;
    }
    state = _buildState();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Attempts a user move. Returns `true` if the move was legal.
  /// [promotion] defaults to `'q'` but can be any valid piece character.
  bool makeUserMove(String from, String to, {String promotion = 'q'}) {
    if (_chess.game_over) return false;

    // Capture FEN BEFORE the move so PostGameAnalyzer can evaluate it.
    final fenBefore = _chess.fen;
    final moved = _chess.move({'from': from, 'to': to, 'promotion': promotion});
    if (moved) {
      _fenHistory.add(fenBefore);
      debugPrint('[MatchController] User move $from$to | FEN#${_fenHistory.length}: $fenBefore');
      state = _buildState();
      return true;
    }
    return false;
  }

  /// Asks the injected engine for the best move and applies it.
  Future<void> requestEngineMove() async {
    if (_chess.game_over) return;
    if (!_isPve) return;

    try {
      final fenBefore = _chess.fen;
      final engine = ref.read(chessEngineProvider);
      final engineConfig = ref.read(engineConfigProvider);
      final bestMove = await engine.getBestMove(
        state.fen,
        engineConfig.moveTimeMs,
      );

      if (bestMove.isEmpty || bestMove.length < 4) return;

      final from = bestMove.substring(0, 2);
      final to = bestMove.substring(2, 4);
      final promotion = bestMove.length == 5 ? bestMove[4] : 'q';

      final moved = _chess.move({
        'from': from,
        'to': to,
        'promotion': promotion,
      });
      if (moved) {
        _fenHistory.add(fenBefore);
        debugPrint('[MatchController] Engine move $from$to | FEN#${_fenHistory.length}: $fenBefore');
        state = _buildState();
      }
    } catch (e) {
      debugPrint('requestEngineMove error: $e');
    }
  }

  /// Resets the board to the initial position without changing configuration.
  void resetGame() {
    _chess = chess_lib.Chess();
    _fenHistory.clear();
    state = _buildState();
  }

  /// Undoes the last move(s).
  ///
  /// In PvE: undoes the last engine half-move AND the last user half-move
  /// so the user is back in the same situation.
  /// In PvP: undoes exactly one half-move.
  void undoMove() {
    if (_chess.history.isEmpty) return;

    if (_isPve) {
      // Undo engine half-move first (if present)
      if (_chess.history.length >= 2) {
        _chess.undo_move();
        _chess.undo_move();
        if (_fenHistory.length >= 2) {
          _fenHistory.removeLast();
          _fenHistory.removeLast();
        }
      } else if (_chess.history.length == 1) {
        _chess.undo_move();
        if (_fenHistory.isNotEmpty) _fenHistory.removeLast();
      }
    } else {
      _chess.undo_move();
      if (_fenHistory.isNotEmpty) _fenHistory.removeLast();
    }

    state = _buildState();
  }

  /// Returns all legal moves as a list of `{from, to}` algebraic notation maps.
  /// The UI layer can use this to show move hints and validate drag targets.
  List<Map<String, String>> get legalMoves {
    if (_legalMovesCache != null) return _legalMovesCache!;
    _legalMovesCache = _chess
        .generate_moves()
        .map((m) => {
              'from': m.fromAlgebraic,
              'to': m.toAlgebraic,
            })
        .toList();
    return _legalMovesCache!;
  }

  /// Returns the move history in basic algebraic notation.
  List<String> get moveHistory {
    if (_moveHistoryCache != null) return _moveHistoryCache!;
    _moveHistoryCache = _chess.history.map((entry) {
      final m = entry.move;
      return m.fromAlgebraic + m.toAlgebraic + (m.promotion?.name ?? '');
    }).toList();
    return _moveHistoryCache!;
  }

  /// Lazy computation of the PGN string.
  String get pgn => _chess.pgn();

  /// True if the injected engine is available on this platform.
  bool get engineAvailable => ref.read(chessEngineProvider).isAvailable;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  MatchState _buildState() {
    _legalMovesCache = null;
    _moveHistoryCache = null;

    // Detect capture: the last history entry has a 'captured' piece if any.
    bool lastMoveWasCapture = false;
    if (_chess.history.isNotEmpty) {
      final lastMove = _chess.history.last.move;
      lastMoveWasCapture = lastMove.captured != null;
    }

    // canUndo: PvE needs ≥2 half-moves (engine+user pair); PvP needs ≥1.
    final canUndo = _isPve
        ? _chess.history.length >= 2
        : _chess.history.isNotEmpty;

    return MatchState(
      fen: _chess.fen,
      isWhiteTurn: _chess.turn == chess_lib.Color.WHITE,
      isCheck: _chess.in_check,
      isCheckmate: _chess.in_checkmate,
      isDraw: _chess.in_draw,
      isGameOver: _chess.game_over,
      playerSide: _playerSide,
      lastMoveWasCapture: lastMoveWasCapture,
      canUndo: canUndo,
    );
  }
}
