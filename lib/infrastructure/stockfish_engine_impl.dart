import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:stockfish/stockfish.dart';
import '../domain/i_chess_engine.dart';

/// Implements [IChessEngine] using the Stockfish C++ engine via FFI/isolates.
///
/// PLATFORM SUPPORT: The `stockfish` package only works on Android, iOS,
/// macOS, and Linux. On Windows desktop, the native engine will fail to start
/// ([StockfishState.error]); in that case this implementation gracefully
/// degrades — [getBestMove] returns an empty string and the UI should handle
/// a "no move" response without crashing.
class StockfishEngineImpl implements IChessEngine {
  Stockfish? _stockfish;
  StreamSubscription<String>? _stdoutSubscription;
  Completer<String>? _bestMoveCompleter;
  bool _isDisposed = false;

  /// True when the native engine successfully reached [StockfishState.ready].
  bool _engineAvailable = false;

  @override
  bool get isAvailable => _engineAvailable;

  @override
  Future<void> initEngine() async {
    if (_isDisposed) return;
    if (_stockfish != null) return;

    _stockfish = Stockfish();

    // Wait for engine to become ready OR fail — using a state listener
    final stateCompleter = Completer<StockfishState>();

    void onStateChange() {
      final s = _stockfish!.state.value;
      if ((s == StockfishState.ready || s == StockfishState.error) &&
          !stateCompleter.isCompleted) {
        stateCompleter.complete(s);
      }
    }

    _stockfish!.state.addListener(onStateChange);

    // Check in case it's already settled (unlikely but safe)
    final currentState = _stockfish!.state.value;
    if (currentState == StockfishState.ready ||
        currentState == StockfishState.error) {
      if (!stateCompleter.isCompleted) stateCompleter.complete(currentState);
    }

    final StockfishState finalState;
    try {
      finalState = await stateCompleter.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => StockfishState.error,
      );
    } finally {
      _stockfish?.state.removeListener(onStateChange);
    }

    if (finalState != StockfishState.ready) {
      // Engine unavailable (e.g. Windows desktop, or FFI init failure).
      // Log and degrade gracefully — DO NOT throw.
      debugPrint(
        '[StockfishEngineImpl] Engine unavailable ($finalState). '
        'Note: the stockfish package only supports Android / iOS / macOS / Linux.',
      );
      _engineAvailable = false;
      return;
    }

    _engineAvailable = true;
    if (_isDisposed) return;

    // Set up stdout listener for bestmove responses
    _stdoutSubscription = _stockfish!.stdout.listen(
      (line) {
        if (kDebugMode) {
          debugPrint('Stockfish: $line');
        }
        if (line.startsWith('bestmove')) {
          final parts = line.split(' ');
          if (parts.length >= 2 &&
              _bestMoveCompleter != null &&
              !_bestMoveCompleter!.isCompleted) {
            _bestMoveCompleter!.complete(parts[1]);
          }
        }
      },
      onError: (error) {
        debugPrint('Stockfish stream error: $error');
        if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
          _bestMoveCompleter!.complete('');
        }
      },
    );

    // Send UCI handshake — engine is in ready state
    _stockfish!.stdin = 'uci';
    _stockfish!.stdin = 'isready';
  }

  @override
  Future<String> getBestMove(String fen, int timeMs) async {
    if (_isDisposed) return '';

    if (_stockfish == null) {
      await initEngine();
    }

    // Engine unavailable on this platform — return empty (UI will handle)
    if (!_engineAvailable) return '';

    try {
      if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
        debugPrint('[StockfishEngineImpl] Canceling previous move request...');
        _bestMoveCompleter!.complete('');
        try {
          if (_stockfish?.state.value == StockfishState.ready) {
            _stockfish!.stdin = 'stop';
          }
        } catch (_) {}
      }

      _bestMoveCompleter = Completer<String>();

      _stockfish!.stdin = 'position fen $fen';
      _stockfish!.stdin = 'go movetime $timeMs';

      return await _bestMoveCompleter!.future.timeout(
        Duration(milliseconds: timeMs + 5000),
        onTimeout: () {
          debugPrint('getBestMove timed out — sending stop');
          try {
            if (_stockfish?.state.value == StockfishState.ready) {
              _stockfish!.stdin = 'stop';
            }
          } catch (_) {}
          return '';
        },
      );
    } catch (e) {
      debugPrint('getBestMove error: $e');
      return '';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _stdoutSubscription?.cancel();
    _stdoutSubscription = null;

    if (_bestMoveCompleter != null && !_bestMoveCompleter!.isCompleted) {
      _bestMoveCompleter!.complete('');
    }
    _bestMoveCompleter = null;

    if (_engineAvailable && _stockfish?.state.value == StockfishState.ready) {
      try {
        _stockfish!.dispose();
      } catch (e) {
        debugPrint('Stockfish dispose error: $e');
      }
    }
    _stockfish = null;
    _engineAvailable = false;
  }
}
