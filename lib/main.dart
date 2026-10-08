import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const ColorFillApp());

class ColorFillApp extends StatelessWidget {
  const ColorFillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Color Fill',
      tagline: 'Flood the board from the corner — beat par, grab the stars',
      emoji: '🎨',
      slug: 'colorfill',
      howToPlay:
          '• Pick a color and the whole top-left region floods with it.\n• Swallow neighboring colors one flood at a time.\n• Fill the ENTIRE board within par moves for 3 stars ⭐⭐⭐.\n• 20 levels. Undo freely — no shame in it.',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) =>
          ColorFillScreen(players: players, callbacks: cb),
    );
  }
}
