import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_history.dart';

class GameHistoryNotifier extends Notifier<List<GameHistory>> {
  static const _historyKey = 'user_game_history';

  @override
  List<GameHistory> build() {
    _loadHistory();
    return [];
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_historyKey);
    if (jsonList != null) {
      final history = jsonList
          .map((jsonStr) => GameHistory.fromJson(jsonStr))
          .toList();
      // Sort newest to oldest
      history.sort((a, b) => b.date.compareTo(a.date));
      state = history;
    }
  }

  Future<void> saveGame(GameHistory game) async {
    final updatedList = [game, ...state];
    state = updatedList;

    final prefs = await SharedPreferences.getInstance();
    final jsonList = updatedList.map((g) => g.toJson()).toList();
    await prefs.setStringList(_historyKey, jsonList);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}

final gameHistoryProvider =
    NotifierProvider<GameHistoryNotifier, List<GameHistory>>(() {
      return GameHistoryNotifier();
    });
