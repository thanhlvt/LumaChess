import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final soundServiceProvider = Provider<SoundService>((ref) => SoundService());

/// Handles all chess game sound effects.
///
/// Uses the [audioplayers] package to play bundled sound assets.
class SoundService {
  final _players = <String, AudioPlayer>{};


  /// Play the move sound (piece placed without capture).
  Future<void> playMove() => _play('move.mp3');

  /// Play the capture sound (an enemy piece was taken).
  Future<void> playCapture() => _play('capture.mp3');

  /// Play the check sound (king is in check).
  Future<void> playCheck() => _play('check.mp3');

  /// Play a win jingle.
  Future<void> playWin() => _play('win.mp3');

  /// Play a consolation tune when the player loses.
  Future<void> playLose() => _play('lose.mp3');

  Future<void> _play(String asset) async {
    try {
      // Reuse an existing idle player or create one.
      AudioPlayer? player = _players[asset];
      if (player == null) {
        player = AudioPlayer();
        _players[asset] = player;
      }
      await player.stop();
      await player.play(AssetSource('sounds/$asset'));
    } catch (e) {
      // Sound is non-critical — never crash on audio errors.
      debugPrint('[SoundService] Failed to play $asset: $e');
    }
  }

  /// Release all audio resources. Call when the app is destroyed.
  Future<void> dispose() async {
    for (final p in _players.values) {
      await p.dispose();
    }
    _players.clear();
  }
}
