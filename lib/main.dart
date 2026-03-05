import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:luma_chess/domain/i_chess_engine.dart';
import 'package:luma_chess/domain/match_provider.dart';
import 'package:luma_chess/infrastructure/injection.dart';
import 'package:luma_chess/presentation/main_menu_screen.dart';
import 'package:luma_chess/presentation/settings_screen.dart';

// ignore: unused_element
AppLifecycleListener? _lifecycleListener;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencyInjection();

  _lifecycleListener = AppLifecycleListener(
    onExitRequested: () async {
      try {
        GetIt.I<IChessEngine>().dispose();
      } catch (_) {}
      return AppExitResponse.exit;
    },
    onDetach: () {
      try {
        GetIt.I<IChessEngine>().dispose();
      } catch (_) {}
    },
  );

  runApp(
    ProviderScope(
      overrides: [
        chessEngineProvider.overrideWithValue(GetIt.I<IChessEngine>()),
      ],
      child: const ChessApp(),
    ),
  );
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumaChess',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainMenuScreen(),
      routes: {'/settings': (context) => const SettingsScreen()},
      debugShowCheckedModeBanner: false,
    );
  }
}
