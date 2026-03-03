import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squares/squares.dart';
import 'package:enterprise_chess/domain/engine_config.dart';
import 'package:enterprise_chess/domain/match_provider.dart';
import 'package:enterprise_chess/domain/user_settings_provider.dart';
import 'package:enterprise_chess/domain/game_history_provider.dart';
import 'package:enterprise_chess/domain/game_history.dart';
import 'package:enterprise_chess/presentation/utils/chess_board_builder.dart';
import 'services/sound_service.dart';
import 'game_review_screen.dart';

class CpuVsCpuScreen extends ConsumerStatefulWidget {
  final EngineConfig whiteConfig;
  final EngineConfig blackConfig;

  const CpuVsCpuScreen({
    super.key,
    required this.whiteConfig,
    required this.blackConfig,
  });

  @override
  ConsumerState<CpuVsCpuScreen> createState() => _CpuVsCpuScreenState();
}

class _CpuVsCpuScreenState extends ConsumerState<CpuVsCpuScreen> {
  bool _isEngineThinking = false;
  bool _gameOverDialogShown = false;
  late GameHistory? _savedHistory;

  @override
  void initState() {
    super.initState();
    _savedHistory = null;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _startLoop();
    });
  }

  void _startLoop() async {
    final controller = ref.read(matchProvider.notifier);

    // Start game
    controller.startGame(
      playerSide: 'none',
      config: widget.whiteConfig,
      isPve: true,
    );

    _playNextMove();
  }

  void _playNextMove() async {
    if (!mounted) return;

    final matchState = ref.read(matchProvider);
    if (matchState.isGameOver) {
      _showGameOverDialog();
      return;
    }

    setState(() => _isEngineThinking = true);

    // Set config for current turn
    final currentConfig = matchState.isWhiteTurn
        ? widget.whiteConfig
        : widget.blackConfig;
    ref.read(engineConfigProvider.notifier).updateConfig(currentConfig);

    final controller = ref.read(matchProvider.notifier);
    final oldMoveHistoryLength = controller.moveHistory.length;

    // Wait for move
    try {
      await controller.requestEngineMove();
    } catch (_) {}

    if (!mounted) return;

    setState(() => _isEngineThinking = false);

    final newState = ref.read(matchProvider);
    final newMoveHistoryLength = controller.moveHistory.length;
    final soundService = ref.read(soundServiceProvider);

    // Play sounds
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

    if (newState.isGameOver) {
      _showGameOverDialog();
    } else {
      // Loop
      Future.delayed(const Duration(milliseconds: 100), () {
        _playNextMove();
      });
    }
  }

  void _showGameOverDialog() async {
    if (_gameOverDialogShown) return;
    _gameOverDialogShown = true;

    final state = ref.read(matchProvider);
    final controller = ref.read(matchProvider.notifier);
    final isCheckmate = state.isCheckmate;
    final loserIsWhite = state.isWhiteTurn;

    final soundService = ref.read(soundServiceProvider);
    soundService.playWin(); // both win in a way, just play win sound

    // Save history
    String resultStr = 'Draw';
    if (isCheckmate) {
      resultStr = loserIsWhite ? 'Black Wins' : 'White Wins';
    }

    final whiteName =
        'CPU (${EngineConfig.labelFor(widget.whiteConfig.difficulty)})';
    final blackName =
        'CPU (${EngineConfig.labelFor(widget.blackConfig.difficulty)})';

    final history = GameHistory.create(
      mode: 'CPUvsCPU',
      player1: whiteName,
      player2: blackName,
      result: resultStr,
      pgn: controller.pgn,
    );

    await ref.read(gameHistoryProvider.notifier).saveGame(history);
    _savedHistory = history;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _CpuGameOverDialog(
          title: isCheckmate
              ? (loserIsWhite ? 'Black CPU Wins! 🎉' : 'White CPU Wins! 🎉')
              : 'Draw 🤝',
          subtitle: state.isDraw
              ? 'A balanced game!'
              : 'Excellent engine battle!',
          onRestart: () {
            Navigator.of(context).pop();
            _gameOverDialogShown = false;
            _startLoop();
          },
          onReview: () {
            Navigator.of(context).pop(); // dialog
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => GameReviewScreen(gameHistory: _savedHistory!),
              ),
            );
          },
          onMenu: () {
            Navigator.of(context).pop(); // dialog
            Navigator.of(context).pop(); // diff setup
            Navigator.of(context).pop(); // menu
          },
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchState = ref.watch(matchProvider);
    final userSettings = ref.watch(userSettingsProvider);

    final boardState = ChessBoardBuilder.buildBoardState(
      matchState.fen,
      orientation: Squares.white,
      lastMove: matchState.lastMove,
    );

    final whiteName =
        'W: ${EngineConfig.labelFor(widget.whiteConfig.difficulty)}';
    final blackName =
        'B: ${EngineConfig.labelFor(widget.blackConfig.difficulty)}';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context)
              ..pop()
              ..pop();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CPU vs CPU',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              '$whiteName vs $blackName',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AbsorbPointer(
                child: BoardController(
                  state: boardState,
                  playState: PlayState.observing,
                  pieceSet: userSettings.pieceSet,
                  theme: userSettings.theme,
                  moves: const [],
                ),
              ),
            ),
          ),

          if (_isEngineThinking)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        matchState.isWhiteTurn
                            ? 'White is thinking...'
                            : 'Black is thinking...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CpuGameOverDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onRestart;
  final VoidCallback onReview;
  final VoidCallback onMenu;

  const _CpuGameOverDialog({
    required this.title,
    required this.subtitle,
    required this.onRestart,
    required this.onReview,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.bottomCenter, // Do not obscure the board
      insetPadding: const EdgeInsets.all(16).copyWith(bottom: 32),
      backgroundColor: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onMenu,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Menu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Review'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRestart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Again'),
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
