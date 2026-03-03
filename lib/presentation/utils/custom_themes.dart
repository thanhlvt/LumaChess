import 'package:flutter/material.dart';
import 'package:squares/squares.dart';

class CustomThemes {
  static const neonNight = BoardTheme(
    lightSquare: Color(0xFF2C2C2C), // Dark grey
    darkSquare: Color(0xFF121212),  // Deep black
    check: Color(0xFFFF0055),       // Neon pink
    checkmate: Color(0xFFFF0000),   // Bright red
    previous: Color(0x8000FFCC),    // Neon cyan transparent overlay
    selected: Color(0x80CCFF00),    // Neon yellow transparent overlay
    premove: Color(0x809D00FF),     // Neon purple transparent overlay
  );

  static const hackerGreen = BoardTheme(
    lightSquare: Color(0xFF003B00), // Dark green
    darkSquare: Color(0xFF000000),  // Pitch black
    check: Color(0xFF00FF00),       // Bright green
    checkmate: Color(0xFFFFFFFF),   // White
    previous: Color(0x8000FF00),    // Transparent green
    selected: Color(0x8000AA00),    // Mid green
    premove: Color(0x80005500),     // Dark text green
  );
}

class CustomPieceSets {
  static final animals = PieceSet.text(
    strings: {
      'P': '🐕', 'N': '🐎', 'B': '🦅', 'R': '🐘', 'Q': '🐯', 'K': '🦁', // White
      'p': '🐕', 'n': '🐎', 'b': '🦅', 'r': '🐘', 'q': '🐯', 'k': '🦁', // Black (same for text in this theme, though normally different style, but let's add visual change maybe? Or just keep it as emojis. Emojis don't have color easily)
    },
    style: const TextStyle(fontSize: 40),
  );

  static final royal = PieceSet.text(
    strings: {
      'P': '🛡️', 'N': '🦄', 'B': '✝️', 'R': '🏰', 'Q': '💎', 'K': '👑', // White
      'p': '🛡️', 'n': '🦄', 'b': '✝️', 'r': '🏰', 'q': '💎', 'k': '👑', // Black
    },
    style: const TextStyle(fontSize: 40),
  );

  static final blitz = PieceSet.fromImageAssets(
    folder: 'assets/images/pieces/blitz/',
    symbols: PieceSet.defaultSymbols, // ['P', 'N', 'B', 'R', 'Q', 'K']
    format: 'png',
  );

  static final luma = PieceSet.fromImageAssets(
    folder: 'assets/images/pieces/luma/',
    symbols: PieceSet.defaultSymbols, // ['P', 'N', 'B', 'R', 'Q', 'K']
    format: 'png',
  );
}
