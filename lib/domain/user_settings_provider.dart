import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:squares/squares.dart';

/// Holds the user's visual preferences for the chessboard.
class UserSettings {
  final BoardTheme theme;
  final PieceSet pieceSet;

  const UserSettings({
    required this.theme,
    required this.pieceSet,
  });

  UserSettings copyWith({
    BoardTheme? theme,
    PieceSet? pieceSet,
  }) {
    return UserSettings(
      theme: theme ?? this.theme,
      pieceSet: pieceSet ?? this.pieceSet,
    );
  }
}

class UserSettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    // Default settings
    return UserSettings(
      theme: BoardTheme.blueGrey,
      pieceSet: PieceSet.merida(),
    );
  }

  void updateTheme(BoardTheme theme) {
    state = state.copyWith(theme: theme);
  }

  void updatePieceSet(PieceSet pieceSet) {
    state = state.copyWith(pieceSet: pieceSet);
  }
}

final userSettingsProvider = NotifierProvider<UserSettingsNotifier, UserSettings>(() {
  return UserSettingsNotifier();
});
