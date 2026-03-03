import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squares/squares.dart';
import 'package:enterprise_chess/domain/match_provider.dart';
import 'package:enterprise_chess/domain/user_settings_provider.dart';
import 'package:enterprise_chess/presentation/utils/chess_coordinate_utils.dart';
import 'package:enterprise_chess/presentation/utils/chess_board_builder.dart';
import 'services/sound_service.dart';
import 'settings_screen.dart';

/// Two-player local game screen.
/// Both sides are user-controlled. The board flips after each move so the
/// player whose turn it is always sees the board from their perspective.
class PvPScreen extends ConsumerStatefulWidget {
  const PvPScreen({super.key});

  @override
  ConsumerState<PvPScreen> createState() => _PvPScreenState();
}

class _PvPScreenState extends ConsumerState<PvPScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start a fresh PvP game (no engine moves)
      ref.read(matchProvider.notifier).startGame(
            playerSide: 'white',
            isPve: false,
          );
    });
  }

  void _onMove(Move move) {
    final controller = ref.read(matchProvider.notifier);
    final from = ChessCoordinateUtils.squareToAlgebraic(move.from);
    final to = ChessCoordinateUtils.squareToAlgebraic(move.to);
    final promo = move.promo ?? 'q';

    final valid = controller.makeUserMove(from, to, promotion: promo);
    if (!valid) return;

    final state = ref.read(matchProvider);
    final soundController = ref.read(soundServiceProvider);
    
    if (state.lastMoveWasCapture) {
      soundController.playCapture();
    } else {
      soundController.playMove();
    }

    if (state.isCheck && !state.isCheckmate) {
      soundController.playCheck();
    }

    if (state.isGameOver) {
      soundController.playWin();
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    final state = ref.read(matchProvider);
    final isCheckmate = state.isCheckmate;
    final loserIsWhite = state.isWhiteTurn; // the side that got mated

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _GameOverDialog(
          title: isCheckmate
              ? (loserIsWhite ? 'Black Wins! 🎉' : 'White Wins! 🎉')
              : 'Draw 🤝',
          subtitle: state.isDraw ? 'Well played, both sides!' : 'Excellent game!',
          onRestart: () {
            Navigator.of(context).pop(); // close dialog
            ref.read(matchProvider.notifier).startGame(
                  playerSide: 'white',
                  isPve: false,
                );
          },
          onMenu: () {
            Navigator.of(context).pop(); // close dialog
            Navigator.of(context).pop(); // back to main menu
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchProvider);
    final userSettings = ref.watch(userSettingsProvider);
    final domainMoves = ref.read(matchProvider.notifier).legalMoves;
    final legalMoves = ChessCoordinateUtils.getLegalMoves(domainMoves);
    // Board flips to always show current player's perspective
    final orientWhite = matchState.isWhiteTurn;
    final orientation = orientWhite ? Squares.white : Squares.black;
    final boardState = ChessBoardBuilder.buildBoardState(
      matchState.fen, 
      orientation: orientation,
      lastMove: matchState.lastMove,
    );

    final playState = matchState.isGameOver ? PlayState.finished : PlayState.ourTurn;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Menu',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          matchState.isWhiteTurn ? "White's Turn" : "Black's Turn",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // ── Undo ──────────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: matchState.canUndo
                ? () => ref.read(matchProvider.notifier).undoMove()
                : null,
          ),
          // ── Restart ───────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart',
            onPressed: () {
              ref.read(matchProvider.notifier).startGame(
                    playerSide: 'white',
                    isPve: false,
                  );
            },
          ),
          // ── Settings ──────────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
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
