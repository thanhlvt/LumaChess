import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Represents a completed chess match.
class GameHistory {
  final String id;
  final DateTime date;

  /// E.g. 'PvE', 'PvP', 'CPUvsCPU'
  final String mode;
  final String player1;
  final String player2;

  /// E.g. 'White Wins', 'Black Wins', 'Draw'
  final String result;

  /// The Portable Game Notation string for the match.
  final String pgn;

  const GameHistory({
    required this.id,
    required this.date,
    required this.mode,
    required this.player1,
    required this.player2,
    required this.result,
    required this.pgn,
  });

  factory GameHistory.create({
    required String mode,
    required String player1,
    required String player2,
    required String result,
    required String pgn,
  }) {
    return GameHistory(
      id: const Uuid().v4(),
      date: DateTime.now(),
      mode: mode,
      player1: player1,
      player2: player2,
      result: result,
      pgn: pgn,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mode': mode,
      'player1': player1,
      'player2': player2,
      'result': result,
      'pgn': pgn,
    };
  }

  factory GameHistory.fromMap(Map<String, dynamic> map) {
    return GameHistory(
      id: map['id'] ?? '',
      date: DateTime.parse(map['date']),
      mode: map['mode'] ?? '',
      player1: map['player1'] ?? '',
      player2: map['player2'] ?? '',
      result: map['result'] ?? '',
      pgn: map['pgn'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory GameHistory.fromJson(String source) =>
      GameHistory.fromMap(json.decode(source));
}
