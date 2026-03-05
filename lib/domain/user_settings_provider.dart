import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:squares/squares.dart';
import 'package:luma_chess/presentation/utils/custom_themes.dart';

/// Holds the user's visual preferences for the chessboard.
class UserSettings {
  final BoardTheme theme;
  final PieceSet pieceSet;

  const UserSettings({required this.theme, required this.pieceSet});

  UserSettings copyWith({BoardTheme? theme, PieceSet? pieceSet}) {
    return UserSettings(
      theme: theme ?? this.theme,
      pieceSet: pieceSet ?? this.pieceSet,
    );
  }
}

class UserSettingsNotifier extends Notifier<UserSettings> {
  static const _themeKey = 'user_theme';
  static const _pieceSetKey = 'user_piece_set';

  @override
  UserSettings build() {
    _loadSettings();
    // Default settings returned immediately while loading
    return UserSettings(
      theme: BoardTheme.blueGrey,
      pieceSet: PieceSet.merida(),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeName = prefs.getString(_themeKey);
    BoardTheme theme = BoardTheme.blueGrey;
    if (themeName == 'brown') {
      theme = BoardTheme.brown;
    } else if (themeName == 'hackerGreen') {
      theme = CustomThemes.hackerGreen;
    }

    // Load Piece Set
    final pieceSetName = prefs.getString(_pieceSetKey);
    PieceSet pieceSet = PieceSet.merida();
    if (pieceSetName == 'blitz') {
      pieceSet = CustomPieceSets.blitz;
    } else if (pieceSetName == 'luma') {
      pieceSet = CustomPieceSets.luma;
    }

    state = state.copyWith(theme: theme, pieceSet: pieceSet);
  }

  void updateTheme(BoardTheme theme, String themeName) async {
    state = state.copyWith(theme: theme);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }

  void updatePieceSet(PieceSet pieceSet, String pieceSetName) async {
    state = state.copyWith(pieceSet: pieceSet);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pieceSetKey, pieceSetName);
  }
}

final userSettingsProvider =
    NotifierProvider<UserSettingsNotifier, UserSettings>(() {
      return UserSettingsNotifier();
    });
