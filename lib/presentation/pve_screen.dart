import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squares/squares.dart';
import 'package:enterprise_chess/domain/engine_config.dart';
import 'package:enterprise_chess/domain/match_provider.dart';
import 'package:enterprise_chess/domain/user_settings_provider.dart';
import 'package:enterprise_chess/presentation/utils/chess_coordinate_utils.dart';
import 'package:enterprise_chess/presentation/utils/chess_board_builder.dart';
import 'services/sound_service.dart';

/// Player-vs-Engine game screen.
///
/// Accepts [playerSide] ('white' | 'black') and [engineConfig] from the
/// setup screen. If [playerSide] is 'black', the engine plays the first move
/// automatically so the user sees the board from Black's perspective.
class PvEScreen extends ConsumerStatefulWidget {
  final String playerSide;
  final EngineConfig engineConfig;

  const PvEScreen({
    super.key,
    required this.playerSide,
    required this.engineConfig,
  });

  @override
  ConsumerState<PvEScreen> createState() => _PvEScreenState();
}

class _PvEScreenState extends ConsumerState<PvEScreen> {
  bool _isEngineThinking = false;
  bool _gameOverDialogShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = ref.read(matchProvider.notifier);
      controller.startGame(
        playerSide: widget.playerSide,
        config: widget.engineConfig,
        isPve: true,
      );

      // If user chose Black, engine plays White's first move.
      if (widget.playerSide == 'black') {
        setState(() => _isEngineThinking = true);
        await controller.requestEngineMove();
        if (mounted) setState(() => _isEngineThinking = false);
      }
    });
  }

  // ── Move Handler ──────────────────────────────────────────────────────────

  void _onMove(Move move) async {
    if (_isEngineThinking) return;

    final controller = ref.read(matchProvider.notifier);
    final from = ChessCoordinateUtils.squareToAlgebraic(move.from);
    final to = ChessCoordinateUtils.squareToAlgebraic(move.to);
    final promo = move.promo ?? 'q';

    final valid = controller.makeUserMove(from, to, promotion: promo);
    if (!valid) return;

    final state = ref.read(matchProvider);
    final soundService = ref.read(soundServiceProvider);

    // User move sounds
    if (state.lastMoveWasCapture) {
      soundService.playCapture();
    } else {
      soundService.playMove();
    }
    if (state.isCheck && !state.isCheckmate) {
      soundService.playCheck();
    }

    if (state.isGameOver) {
      // User made a winning move (unlikely but possible via stalemate)
      _onGameOver(state.isCheckmate, isPlayerWin: true, isDraw: state.isDraw);
      return;
    }

    if (!mounted) return;

    // Engine's turn
    setState(() => _isEngineThinking = true);
    final oldMoveHistoryLength = controller.moveHistory.length;

    try {
      await controller.requestEngineMove();
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isEngineThinking = false);

    final newState = ref.read(matchProvider);
    final newMoveHistoryLength = controller.moveHistory.length;

    // Engine move sounds
    if (newState.isGameOver || newMoveHistoryLength > oldMoveHistoryLength) {
      if (newState.lastMoveWasCapture) {
        soundService.playCapture();
      } else {
        soundService.playMove();
      }
      if (newState.isCheck && !newState.isCheckmate) {
        soundService.playCheck();
      }
    }

    if (newState.isGameOver && !_gameOverDialogShown) {
      _onGameOver(
        newState.isCheckmate,
        // If it's now the user's turn and game is over → user was mated
        isPlayerWin: false,
        isDraw: newState.isDraw,
      );
    }
  }

  void _onGameOver(bool isCheckmate, {required bool isPlayerWin, required bool isDraw}) {
    _gameOverDialogShown = true;
    final soundService = ref.read(soundServiceProvider);
    
    if (isDraw) {
      soundService.playWin();
    } else if (isPlayerWin) {
      soundService.playWin();
    } else {
      soundService.playLose();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _GameOverDialog(
          title: isDraw
              ? 'Draw 🤝'
              : isPlayerWin
                  ? '🎉 Chúc mừng!\nBạn đã thắng!'
                  : '💪 Cố lên!\nLần sau sẽ tốt hơn!',
          subtitle: isDraw
              ? 'A balanced game!'
              : isPlayerWin
                  ? 'You outplayed the engine!'
                  : 'The engine got you this time.',
          onRestart: () {
            Navigator.of(context).pop(); // close dialog
            _restartGame();
          },
          onMenu: () {
            Navigator.of(context).pop(); // close dialog
            Navigator.of(context).pop(); // back through setup
            Navigator.of(context).pop(); // back to main menu
          },
        ),
      );
    });
  }

  void _restartGame() async {
    _gameOverDialogShown = false;
    final controller = ref.read(matchProvider.notifier);
    controller.startGame(
      playerSide: widget.playerSide,
      config: widget.engineConfig,
      isPve: true,
    );
    if (widget.playerSide == 'black') {
      setState(() => _isEngineThinking = true);
      await controller.requestEngineMove();
      if (mounted) setState(() => _isEngineThinking = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchProvider);
    final userSettings = ref.watch(userSettingsProvider);
    final domainMoves = ref.read(matchProvider.notifier).legalMoves;
    final legalMoves = ChessCoordinateUtils.getLegalMoves(domainMoves);
    final orientation = widget.playerSide == 'black' ? Squares.black : Squares.white;
    final boardState = ChessBoardBuilder.buildBoardState(
      matchState.fen, 
      orientation: orientation,
      lastMove: matchState.lastMove,
    );

    final isUserTurn = widget.playerSide == 'white'
        ? matchState.isWhiteTurn
        : !matchState.isWhiteTurn;

    final playState = matchState.isGameOver
        ? PlayState.finished
        : _isEngineThinking || !isUserTurn
            ? PlayState.theirTurn
            : PlayState.ourTurn;

    final diffLabel = EngineConfig.labelFor(widget.engineConfig.difficulty);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Menu',
          onPressed: () {
            Navigator.of(context)
              ..pop() // setup screen
              ..pop(); // main menu
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('vs Computer',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            Text(diffLabel,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          // ── Undo ─────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: matchState.canUndo && !_isEngineThinking
                ? () {
                    ref.read(matchProvider.notifier).undoMove();
                    setState(() => _gameOverDialogShown = false);
                  }
                : null,
          ),
          // ── Restart ───────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart',
            onPressed: _isEngineThinking ? null : _restartGame,
          ),
          // ── Settings ──────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Board ─────────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: BoardController(
                state: boardState,
                playState: playState,
                pieceSet: userSettings.pieceSet,
                theme: userSettings.theme,
                markerTheme: MarkerTheme.basic.copyWith(
                  piece: (context, size, colour) => Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                moves: legalMoves,
                onMove: _onMove,
                promotionBehaviour: PromotionBehaviour.autoPremove,
              ),
            ),
          ),

          // ── AI thinking overlay ────────────────────────────────────────
          if (_isEngineThinking)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.amber),
                    SizedBox(height: 16),
                    Text(
                      'AI is thinking...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Game Over Dialog ──────────────────────────────────────────────────────────

class _GameOverDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRestart;
  final VoidCallback onMenu;

  const _GameOverDialog({
    required this.title,
    required this.subtitle,
    required this.onRestart,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMenu,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Main Menu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRestart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Play Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
