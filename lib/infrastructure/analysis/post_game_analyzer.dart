import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';
import '../../domain/analysis/move_analysis.dart';
import '../../domain/analysis/commentary_templates.dart';
import '../../domain/analysis/i_analysis_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

/// Runs a full post-game analysis on a list of FEN positions using Stockfish
/// with MultiPV 3, returning a [MoveAnalysis] for every half-move.
///
/// The heavy Stockfish work is performed inside a dedicated [Isolate] so the
/// main UI thread is never blocked. Pass [onProgress] to receive incremental
/// updates (0.0 – 1.0).
class PostGameAnalyzer implements IAnalysisService {
  @override
  AnalysisTask analyzeGame({
    required List<String> fenHistory,
    required List<String> moveHistory,
    void Function(double progress)? onProgress,
  }) {
    if (fenHistory.isEmpty) {
      return AnalysisTask(
        result: Future.value(const []),
        cancel: () {},
      );
    }

    final args = _AnalysisArgs(
      fenHistory: List<String>.from(fenHistory),
      moveHistory: List<String>.from(moveHistory),
    );

    final receivePort = ReceivePort();
    Isolate? isolate;
    final completer = Completer<List<MoveAnalysis>>();
    final results = <MoveAnalysis>[];

    Isolate.spawn(_analysisIsolateEntry, _IsolateMessage(
      sendPort: receivePort.sendPort,
      args: args,
    )).then((iso) {
      if (completer.isCompleted) {
        iso.kill(priority: Isolate.immediate);
        receivePort.close();
      } else {
        isolate = iso;
      }
    });

    receivePort.listen((msg) {
      if (completer.isCompleted) return;
      if (msg is _ProgressMessage) {
        onProgress?.call(msg.progress);
      } else if (msg is List<MoveAnalysis>) {
        results.addAll(msg);
        receivePort.close();
        if (!completer.isCompleted) completer.complete(results);
      } else if (msg == null) {
        receivePort.close();
        if (!completer.isCompleted) completer.complete(results);
      }
    });

    return AnalysisTask(
      result: completer.future,
      cancel: () {
        if (!completer.isCompleted) completer.complete(results);
        isolate?.kill(priority: Isolate.immediate);
        receivePort.close();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Transfer objects (must be sendable across isolate boundary)
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisArgs {
  final List<String> fenHistory;
  final List<String> moveHistory;
  const _AnalysisArgs({required this.fenHistory, required this.moveHistory});
}

class _IsolateMessage {
  final SendPort sendPort;
  final _AnalysisArgs args;
  const _IsolateMessage({required this.sendPort, required this.args});
}

class _ProgressMessage {
  final double progress;
  const _ProgressMessage(this.progress);
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolate entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Top-level function required by [Isolate.spawn].
Future<void> _analysisIsolateEntry(_IsolateMessage message) async {
  final sendPort = message.sendPort;
  final args = message.args;

  try {
    final analyzer = _StockfishAnalyzer();
    final ok = await analyzer.init();
    if (!ok) {
      sendPort.send(null); // signal failure
      return;
    }

    final results = <MoveAnalysis>[];
    final total = args.fenHistory.length;

    for (int i = 0; i < total; i++) {
      final fen = args.fenHistory[i];
      final playedMove = i < args.moveHistory.length ? args.moveHistory[i] : '?';

      final fenParts = fen.split(' ');
      final isWhiteTurn = fenParts.length > 1 && fenParts[1] == 'w';

      final pvLines = await analyzer.getMultiPV(fen, depth: 15);

      if (pvLines.isEmpty) {
        results.add(_buildStub(i, playedMove, isWhiteTurn));
      } else {
        results.add(_buildMoveAnalysis(
          halfMoveIndex: i,
          playedMove: playedMove,
          isWhiteTurn: isWhiteTurn,
          pvLines: pvLines,
        ));
      }

      sendPort.send(_ProgressMessage((i + 1) / total));
    }

    analyzer.dispose();
    sendPort.send(results);
  } catch (e, st) {
    debugPrint('[PostGameAnalyzer] Isolate error: $e\n$st');
    sendPort.send(null);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MultiPV line model
// ─────────────────────────────────────────────────────────────────────────────

class _PvLine {
  final int multiPvIndex; // 1, 2, 3
  final String bestMove;  // UCI move string "e2e4"
  final double score;     // centipawns (mate converted to ±9999)

  const _PvLine({
    required this.multiPvIndex,
    required this.bestMove,
    required this.score,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Stockfish wrapper (synchronous-style inside isolate)
// ─────────────────────────────────────────────────────────────────────────────

class _StockfishAnalyzer {
  Stockfish? _sf;
  StreamSubscription<String>? _sub;
  final _lines = <String>[];
  Completer<void>? _searchCompleter;

  Future<bool> init() async {
    _sf = Stockfish();

    // Wait until ready
    final stateCompleter = Completer<StockfishState>();
    void onState() {
      final s = _sf!.state.value;
      if ((s == StockfishState.ready || s == StockfishState.error) &&
          !stateCompleter.isCompleted) {
        stateCompleter.complete(s);
      }
    }

    _sf!.state.addListener(onState);
    final current = _sf!.state.value;
    if (current == StockfishState.ready || current == StockfishState.error) {
      if (!stateCompleter.isCompleted) stateCompleter.complete(current);
    }

    final StockfishState finalState;
    try {
      finalState = await stateCompleter.future
          .timeout(const Duration(seconds: 20), onTimeout: () => StockfishState.error);
    } finally {
      _sf?.state.removeListener(onState);
    }

    if (finalState != StockfishState.ready) return false;

    // Subscribe to stdout
    _sub = _sf!.stdout.listen((line) {
      _lines.add(line);
      if (line.startsWith('bestmove') && _searchCompleter != null && !_searchCompleter!.isCompleted) {
        _searchCompleter!.complete();
      }
    });

    // Configure UCI
    _sf!.stdin = 'uci';
    _sf!.stdin = 'setoption name MultiPV value 3';
    _sf!.stdin = 'isready';

    return true;
  }

  /// Sends a position+go command and collects all `info depth` lines
  /// until `bestmove` arrives. Returns the 3 PV lines for that position.
  Future<List<_PvLine>> getMultiPV(String fen, {int depth = 15}) async {
    _lines.clear();
    _searchCompleter = Completer<void>();

    _sf!.stdin = 'position fen $fen';
    _sf!.stdin = 'go depth $depth';

    try {
      await _searchCompleter!.future.timeout(const Duration(seconds: 30));
    } catch (_) {
      // Timeout — use whatever we have
    }

    return _parsePvLines(_lines);
  }

  void dispose() {
    _sub?.cancel();
    try {
      _sf?.stdin = 'quit';
      _sf?.dispose();
    } catch (_) {}
    _sf = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Line parsing
// ─────────────────────────────────────────────────────────────────────────────

/// From the collected stdout lines, extract the last-updated info for
/// MultiPV indices 1, 2, 3 at the maximum depth seen.
List<_PvLine> _parsePvLines(List<String> lines) {
  final infoLines = lines.where(
    (l) => l.startsWith('info') && l.contains('multipv') && l.contains(' pv '),
  ).toList();

  // Group by multipv index; last entry per index = deepest depth = best.
  final Map<int, _PvLine> best = {};
  for (final line in infoLines) {
    final pvIdx = _extractInt(line, 'multipv');
    if (pvIdx == null) continue;
    final move = _extractFirstPvMove(line);
    if (move == null) continue;
    final score = _extractScore(line);
    best[pvIdx] = _PvLine(multiPvIndex: pvIdx, bestMove: move, score: score);
  }

  return best.values.toList()..sort((a, b) => a.multiPvIndex.compareTo(b.multiPvIndex));
}

int? _extractInt(String line, String token) {
  final idx = line.indexOf(token);
  if (idx == -1) return null;
  final after = line.substring(idx + token.length).trimLeft();
  final end = after.indexOf(' ');
  final numStr = end == -1 ? after : after.substring(0, end);
  return int.tryParse(numStr);
}

String? _extractFirstPvMove(String line) {
  final pvIdx = line.indexOf(' pv ');
  if (pvIdx == -1) return null;
  final after = line.substring(pvIdx + 4).trimLeft();
  final end = after.indexOf(' ');
  if (after.isEmpty) return null;
  return end == -1 ? after : after.substring(0, end);
}

/// Returns the score in centipawns. Mate scores are converted to ±9999.
double _extractScore(String line) {
  if (line.contains('score mate')) {
    final mates = _extractInt(line, 'score mate');
    if (mates != null) return mates > 0 ? 9999.0 : -9999.0;
  }
  if (line.contains('score cp')) {
    final cp = _extractInt(line, 'score cp');
    if (cp != null) return cp.toDouble();
  }
  return 0.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// MoveAnalysis builder
// ─────────────────────────────────────────────────────────────────────────────

MoveAnalysis _buildMoveAnalysis({
  required int halfMoveIndex,
  required String playedMove,
  required bool isWhiteTurn,
  required List<_PvLine> pvLines,
}) {
  final pv1 = pvLines.isNotEmpty ? pvLines[0] : null;
  final pv2 = pvLines.length > 1 ? pvLines[1] : null;
  final pv3 = pvLines.length > 2 ? pvLines[2] : null;

  final bestMove = pv1?.bestMove ?? '';
  final altMove1 = pv2?.bestMove ?? '';
  final altMove2 = pv3?.bestMove ?? '';

  final bestScore = pv1?.score ?? 0.0;
  double playedScore = bestScore;
  for (final pv in pvLines) {
    if (pv.bestMove == playedMove) {
      playedScore = pv.score;
      break;
    }
  }

  final bool playedInTop3 = pvLines.any((pv) => pv.bestMove == playedMove);
  if (!playedInTop3 && pvLines.length >= 3) {
    final pv3Score = pv3?.score ?? bestScore;
    playedScore = pv3Score - 30;
  }

  double cpl = (bestScore - playedScore).abs();
  if (cpl > 500) cpl = 500;
  
  final intCpl = cpl.toInt();
  final intEval = bestScore.toInt();

  final category = MoveAnalysis.calculateCategory(intCpl);

  final commentary = CommentaryGenerator.generate(
    category,
    playedMove,
    bestMove,
    altMove1.isEmpty ? null : altMove1,
    altMove2.isEmpty ? null : altMove2,
  );

  return MoveAnalysis(
    moveNumber: (halfMoveIndex ~/ 2) + 1,
    isWhite: isWhiteTurn,
    playedMove: playedMove,
    bestMove: bestMove,
    alternatives: [altMove1, altMove2].where((m) => m.isNotEmpty).toList(),
    evaluation: intEval,
    cpl: intCpl,
    category: category,
    commentary: commentary,
  );
}

MoveAnalysis _buildStub(int halfMoveIndex, String playedMove, bool isWhiteTurn) {
  return MoveAnalysis(
    moveNumber: (halfMoveIndex ~/ 2) + 1,
    isWhite: isWhiteTurn,
    playedMove: playedMove,
    bestMove: '',
    alternatives: const [],
    evaluation: 0,
    cpl: 0,
    category: MoveCategory.good,
    commentary: 'Không thể phân tích nước đi $playedMove (engine không khả dụng trên nền tảng này).',
  );
}
