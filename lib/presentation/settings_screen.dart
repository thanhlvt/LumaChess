import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squares/squares.dart';
import 'package:luma_chess/domain/user_settings_provider.dart';
import 'package:luma_chess/presentation/utils/chess_board_builder.dart';
import 'package:luma_chess/presentation/utils/custom_themes.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final notifier = ref.read(userSettingsProvider.notifier);

    // Some preset themes to choose from
    final themes = [
      {'label': 'Blue Grey', 'value': BoardTheme.blueGrey, 'name': 'blueGrey'},
      {'label': 'Brown', 'value': BoardTheme.brown, 'name': 'brown'},
      {
        'label': 'Hacker Green',
        'value': CustomThemes.hackerGreen,
        'name': 'hackerGreen',
      },
    ];

    // Some preset piece sets to choose from
    final pieceSets = [
      {'label': 'Merida', 'value': PieceSet.merida(), 'name': 'merida'},
      {'label': 'Blitz', 'value': CustomPieceSets.blitz, 'name': 'blitz'},
      {'label': 'Luma', 'value': CustomPieceSets.luma, 'name': 'luma'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Board Theme',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: themes.map((themeMap) {
              final label = themeMap['label'] as String;
              final val = themeMap['value'] as BoardTheme;
              final internalName = themeMap['name'] as String;
              final isSelected = settings.theme == val;

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => notifier.updateTheme(val, internalName),
                backgroundColor: Colors.white12,
                selectedColor: Colors.amber,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),

          const Text(
            'Pieces Style',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: pieceSets.map((pieceMap) {
              final label = pieceMap['label'] as String;
              final val = pieceMap['value'] as PieceSet;
              final internalName = pieceMap['name'] as String;
              // Compare by checking a property uniquely, or just rely on exact instance if constant.
              // For simplicity, we compare pieceSet names indirectly or use exact reference if possible.
              // Since 'val' is created fresh, equality fails. We can check the source/prefix.
              // Hack: Convert the widget representations to strings to compare if they are the same set.
              // Alternatively, compare by their generated internal name if available, but for now we'll compare their king widget strings roughly.
              // Or better, we define equality by checking their internal piece widgets.
              // The safest non-intrusive way is to just assume they have different default sizes or look at the class name.
              // A simpler way: we'll match by name logic if we had stored the name in the provider, but since we didn't, let's just compare the runtime Type of the piece objects.
              // Actually, PieceSet doesn't expose its name easily so we'll just check if their black king widget toString matches.
              final isSelected =
                  settings.pieceSet.piece(context, 'k').toString() ==
                  val.piece(context, 'k').toString();

              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => notifier.updatePieceSet(val, internalName),
                backgroundColor: Colors.white12,
                selectedColor: Colors.amber,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 48),

          // A mini preview board to see the changes instantly
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: IgnorePointer(
                child: Board(
                  theme: settings.theme,
                  pieceSet: settings.pieceSet,
                  state: ChessBoardBuilder.buildBoardState(
                    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1',
                    orientation: Squares.white,
                  ),
                  playState: PlayState.observing,
                  size: const BoardSize(8, 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
