import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:luma_chess/domain/game_config.dart';
import 'game_setup_screen.dart';
import 'pvp_screen.dart';
import 'settings_screen.dart';
import 'cpu_setup_screen.dart';
import 'history_screen.dart';

/// The first screen the user sees.
/// Lets them choose between playing vs the computer or a two-player local game.
class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A237E), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo / Title ─────────────────────────────────────────
                const Icon(Icons.sports_esports, size: 72, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  '♟ LumaChess',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your battle',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 64),

                // ── Play vs Computer ─────────────────────────────────────
                _MenuButton(
                  icon: Icons.computer,
                  label: 'Play vs Computer',
                  onPressed: () async {
                    // Load preferences before showing setup screen
                    final prefs = await SharedPreferences.getInstance();
                    final savedSide = prefs.getString('user_preferred_side');
                    final savedDiff = prefs.getString(
                      'user_preferred_difficulty',
                    );

                    if (!context.mounted) return;

                    // Reset config to defaults before showing setup
                    ref
                        .read(gameConfigProvider.notifier)
                        .update(const GameConfig(mode: GameMode.pve));

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GameSetupScreen(
                          initialSide: savedSide,
                          initialDifficulty: savedDiff,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── 2 Players ────────────────────────────────────────────
                _MenuButton(
                  icon: Icons.people,
                  label: '2 Players local',
                  onPressed: () {
                    ref
                        .read(gameConfigProvider.notifier)
                        .update(const GameConfig(mode: GameMode.pvp));
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PvPScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── CPU vs CPU ───────────────────────────────────────────
                _MenuButton(
                  icon: Icons.smart_toy,
                  label: 'CPU vs CPU',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CpuSetupScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── History ──────────────────────────────────────────────
                _MenuButton(
                  icon: Icons.history,
                  label: 'Game History',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        backgroundColor: const Color(0xFF283593),
        foregroundColor: Colors.white,
        child: const Icon(Icons.settings),
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 280,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon),
            label: Text(
              widget.label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF283593),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colors.amber, width: 1.5),
              ),
              elevation: 6,
            ),
          ),
        ),
      ),
    );
  }
}
