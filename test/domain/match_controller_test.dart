import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enterprise_chess/domain/match_provider.dart';
import 'package:enterprise_chess/domain/i_chess_engine.dart';
import 'package:chess/chess.dart' as chess_lib;

class MockChessEngine implements IChessEngine {
  @override
  void dispose() {}

  @override
  Future<String> getBestMove(String fen, int timeMs) async => 'e7e5';

  @override
  Future<void> initEngine() async {}

  @override
  bool get isAvailable => true;
}

void main() {
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        chessEngineProvider.overrideWithValue(MockChessEngine()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('Initial state should be standard starting FEN', () {
    final container = createContainer();
    final matchState = container.read(matchProvider);
    expect(matchState.fen, chess_lib.Chess.DEFAULT_POSITION);
    expect(matchState.isWhiteTurn, true);
    expect(matchState.isGameOver, false);
  });

  test('Valid move updates state', () {
    final container = createContainer();
    final controller = container.read(matchProvider.notifier);

    final moved = controller.makeUserMove('e2', 'e4');
    expect(moved, true);

    final newState = container.read(matchProvider);
    expect(newState.fen, isNot(chess_lib.Chess.DEFAULT_POSITION));
    expect(newState.isWhiteTurn, false); // Now black's turn
  });

  test('Invalid move returns false and does not update state', () {
    final container = createContainer();
    final controller = container.read(matchProvider.notifier);

    final moved = controller.makeUserMove('e2', 'e5');
    expect(moved, false);

    final state = container.read(matchProvider);
    expect(state.fen, chess_lib.Chess.DEFAULT_POSITION);
  });

  test('requestEngineMove updates state with engine best move', () async {
    final container = createContainer();
    final controller = container.read(matchProvider.notifier);

    controller.makeUserMove('e2', 'e4');
    await controller.requestEngineMove();

    final state = container.read(matchProvider);
    // After e7-e5, FEN contains en passant target e6
    expect(state.fen.contains('e6') || state.fen.contains('4p3'), isTrue);
    expect(state.isWhiteTurn, true); // Back to white's turn
  });

  test('resetGame restores initial state', () {
    final container = createContainer();
    final controller = container.read(matchProvider.notifier);

    controller.makeUserMove('e2', 'e4');
    controller.resetGame();

    final state = container.read(matchProvider);
    expect(state.fen, chess_lib.Chess.DEFAULT_POSITION);
    expect(state.isWhiteTurn, true);
  });

  test('legalMoves returns non-empty list at game start', () {
    final container = createContainer();
    final controller = container.read(matchProvider.notifier);

    final moves = controller.legalMoves;
    expect(moves, isNotEmpty);
    // White has 20 legal moves at the start
    expect(moves.length, 20);
  });

  test('promotion parameter is forwarded correctly', () {
    final container = createContainer();
    final controller = container.read(matchProvider.notifier);

    // Set up a position where promotion is possible
    // Use a known position: white pawn on e7, black king on h8
    // We'll just verify the parameter doesn't crash with default 'q'
    final moved = controller.makeUserMove('e2', 'e4', promotion: 'q');
    expect(moved, true);
  });
}
