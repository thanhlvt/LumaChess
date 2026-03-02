import 'package:get_it/get_it.dart';
import 'package:enterprise_chess/domain/i_chess_engine.dart';
import 'package:enterprise_chess/infrastructure/stockfish_engine_impl.dart';

final getIt = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Register and initialize the Stockfish engine
  final engine = StockfishEngineImpl();
  await engine.initEngine();
  getIt.registerSingleton<IChessEngine>(engine);
}
