import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:enterprise_chess/domain/game_history_provider.dart';
import 'game_review_screen.dart';

/// Screen to view past games.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyStats = ref.watch(gameHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Game History'),
        actions: [
          if (historyStats.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Clear History',
              onPressed: () => _confirmClearHistory(context, ref),
            ),
        ],
      ),
      body: historyStats.isEmpty
          ? const Center(
              child: Text(
                'No games found.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: historyStats.length,
              itemBuilder: (context, index) {
                final game = historyStats[index];
                return _HistoryCard(game: game);
              },
            ),
    );
  }

  void _confirmClearHistory(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text(
          'Clear History?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will permanently delete all your game history.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(gameHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final dynamic game;

  const _HistoryCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy • h:mm a');
    final dateStr = dateFormatter.format(game.date);

    // Determine icon based on mode
    IconData modeIcon = Icons.sports_esports;
    if (game.mode == 'PvP') {
      modeIcon = Icons.people;
    } else if (game.mode == 'CPUvsCPU') {
      modeIcon = Icons.computer;
    }

    return Card(
      color: const Color(0xFF1E1E2E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameReviewScreen(gameHistory: game),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Mode + Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(modeIcon, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        game.mode,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Players
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      game.player1,
                      textAlign: TextAlign.right,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'vs',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      game.player2,
                      textAlign: TextAlign.left,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 3: Result
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getResultColor(game.result).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getResultColor(game.result),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    game.result,
                    style: TextStyle(
                      color: _getResultColor(game.result),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getResultColor(String result) {
    if (result.contains('Draw')) return Colors.blueGrey;
    if (result.contains('White')) return Colors.white;
    if (result.contains('Black')) return Colors.grey;
    return Colors.amber;
  }
}
