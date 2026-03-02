import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_chess/domain/analysis/move_analysis.dart';
import 'package:enterprise_chess/domain/analysis/i_analysis_service.dart';
import 'package:enterprise_chess/domain/match_provider.dart';

/// Post-game analysis screen.
///
/// Accepts [fenHistory] and [moveHistory] from the completed game,
/// runs [analyzeGame] in a background Isolate and presents each move's
/// analysis in a scrollable list.
class AnalysisScreen extends ConsumerStatefulWidget {
  final List<String> fenHistory;
  final List<String> moveHistory;

  const AnalysisScreen({
    super.key,
    required this.fenHistory,
    required this.moveHistory,
  });

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  List<MoveAnalysis>? _results;
  bool _isAnalyzing = true;
  double _progress = 0.0;
  String? _errorMessage;
  int? _selectedMoveIndex;
  AnalysisTask? _analysisTask;
  late ChessBoardController _boardController;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _boardController = ChessBoardController();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _runAnalysis();
  }

  @override
  void dispose() {
    _analysisTask?.cancel();
    _shimmerController.dispose();
    _boardController.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    try {
      final analyzer = ref.read(analysisServiceProvider);
      _analysisTask = analyzer.analyzeGame(
        fenHistory: widget.fenHistory,
        moveHistory: widget.moveHistory,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      
      final results = await _analysisTask!.result;
      if (mounted) {
        setState(() {
          _results = results;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Phân tích thất bại: $e';
          _isAnalyzing = false;
        });
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _categoryColor(MoveCategory cat) {
    switch (cat) {
      case MoveCategory.best:
        return const Color(0xFF00C853);
      case MoveCategory.excellent:
        return const Color(0xFF00B0FF);
      case MoveCategory.good:
        return const Color(0xFF69F0AE);
      case MoveCategory.inaccuracy:
        return const Color(0xFFFFD740);
      case MoveCategory.mistake:
        return const Color(0xFFFF6D00);
      case MoveCategory.blunder:
        return const Color(0xFFFF1744);
    }
  }

  Widget _buildStatsBanner(List<MoveAnalysis> results) {
    final counts = {for (final c in MoveCategory.values) c: 0};
    for (final r in results) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    final avgCpl = results.isEmpty
        ? 0.0
        : results.map((r) => r.cpl).reduce((a, b) => a + b) / results.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF283593)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tổng quan ván đấu — ${results.length} nước đi',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: MoveCategory.values.map((cat) {
              final n = counts[cat] ?? 0;
              return _StatChip(
                icon: cat.icon,
                label: cat.displayName,
                count: n,
                color: _categoryColor(cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trending_down, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(
                'Trung bình CPL: ${avgCpl.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoveCard(MoveAnalysis analysis, int index) {
    final cat = analysis.category;
    final color = _categoryColor(cat);
    final isWhitePly = index % 2 == 0;
    final moveNum = (index ~/ 2) + 1;
    final moveLabel = isWhitePly ? '$moveNum. ♙' : '$moveNum. … ♟';
    final isSelected = _selectedMoveIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMoveIndex = index;
          if (index + 1 < widget.fenHistory.length) {
            _boardController.loadFen(widget.fenHistory[index + 1]);
          } else if (widget.fenHistory.isNotEmpty) {
             _boardController.loadFen(widget.fenHistory.last);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A2A3E) : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.8) : color.withValues(alpha: 0.3), 
            width: isSelected ? 2 : 1
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Move number + side
                  Text(
                    moveLabel,
                    style: TextStyle(
                      color: isWhitePly ? Colors.white : Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Played move chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withValues(alpha: 0.5)),
                    ),
                    child: Text(
                      analysis.playedMove,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          cat.displayName,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Commentary
              Text(
                analysis.commentary,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              // CPL + alternatives
              if (analysis.cpl > 0 || analysis.bestMove.isNotEmpty) ...[
                const SizedBox(height: 8),
                DefaultTextStyle(
                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                  child: Wrap(
                    spacing: 12,
                    children: [
                      if (analysis.cpl > 0)
                        Text('CPL: ${analysis.cpl.toStringAsFixed(0)}'),
                      if (analysis.bestMove.isNotEmpty &&
                          analysis.bestMove != analysis.playedMove)
                        Text(
                          'Tốt nhất: ${analysis.bestMove}',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                        ),
                      if (analysis.alternatives.isNotEmpty)
                        Text('Phương án: ${analysis.alternatives.join(', ')}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text(
          '🔍 Phân tích ván đấu',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isAnalyzing
          ? _buildLoadingView()
          : _errorMessage != null
              ? _buildErrorView()
              : _buildResultsView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🤖 Stockfish đang phân tích...',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) => Text(
              'Đang xử lý ${(_progress * 100).toInt()}% nước đi',
              style: TextStyle(
                color: Colors.white54.withValues(alpha: 0.5 + 0.5 * _shimmerController.value),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white12,
                color: Colors.amber,
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Đã xảy ra lỗi.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Quay lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final results = _results ?? [];
    if (results.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu phân tích.\n(Engine có thể không khả dụng trên nền tảng này.)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 14),
        ),
      );
    }

    return Column(
      children: [
        // The mini chessboard view at the top
        Container(
          color: const Color(0xFF1E1E2E),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
               height: MediaQuery.of(context).size.width * 0.7,
               width: MediaQuery.of(context).size.width * 0.7,
               child: ChessBoard(
                controller: _boardController,
                boardColor: BoardColor.brown,
                boardOrientation: PlayerColor.white,
                enableUserMoves: false,
              ),
            ),
          ),
        ),
        // The analysis list below
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: results.length + 1, // +1 for stats banner
            itemBuilder: (context, idx) {
              if (idx == 0) return _buildStatsBanner(results);
              return _buildMoveCard(results[idx - 1], idx - 1);
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
