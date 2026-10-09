import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan.dart';
import '../theme/fill_themes.dart';

/// How to Play — the 13-section rules, readable in-app.
class RulesScreen extends StatelessWidget {
  final FillAudio audio;
  final FillSettings settings;
  final FillThemeDef theme;
  const RulesScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.theme,
  });

  static const _sections = [
    (
      '1 · Objective',
      'Flood the entire board with ONE color. Your region starts in the top-left corner and grows every time you pick a color.'
    ),
    (
      '2 · Setup',
      'Each board is a grid of colored tiles (8×8 with 5 colors on Easy, 10×10 with 6 on Medium, 12×12 with 7 on Hard). Every board is solvable and always contains every color.'
    ),
    (
      '3 · Turn order',
      'There are no turns — it is just you versus the board. Pick any color, watch the flood spread, then pick again.'
    ),
    (
      '4 · Legal moves',
      'Tap any paint pot whose color differs from your current region color. Your whole connected region changes to that color and swallows every touching tile of the new color.'
    ),
    (
      '5 · Illegal moves',
      'Tapping the color your region already is does nothing (and plays a gentle "nope" sound). You cannot pick while the flood wave is still spreading.'
    ),
    (
      '6 · Captures',
      'There are no captures — only growth. Every tile your region touches that matches your picked color joins the flood.'
    ),
    (
      '7 · Special rules',
      '• Undo takes back your last pick (up to 30 steps).\n• Hints highlight the color that grows your region most — 3 per board.\n• You have a move limit of par + 8. Run out and the board beats you.'
    ),
    (
      '8 · Scoring',
      'Finish in par moves or fewer for 3 stars ⭐⭐⭐, within par + 3 for 2 stars, otherwise 1 star. Stars unlock later campaign levels and feed your total.'
    ),
    (
      '9 · Winning conditions',
      'Every tile on the board is the same color. Campaign: clear all 20 levels. Daily: flood the seeded board to grow your streak.'
    ),
    (
      '10 · Draw conditions',
      'There are no draws. Every board ends in a win or an out-of-moves retry.'
    ),
    (
      '11 · AI strategy',
      'The hint system plays greedily: it always picks the color that adds the most tiles to your region right now. Par is set from a full greedy solve of your exact board.'
    ),
    (
      '12 · Edge cases',
      '• Boards are generated until the greedy solver needs at least 5/7/9 moves (Easy/Medium/Hard), so no freebies.\n• Restarting a board re-deals the identical tiles — same seed, fair retry.\n• The flood wave always finishes; the engine watchdog guarantees no stuck animation.'
    ),
    (
      '13 · Test cases',
      '• Picking the current color is rejected.\n• Undo restores the exact previous board and move count.\n• Solving uses ≤ move limit moves on a win.\n• Campaign level 20 completion fires the grand celebration.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
        title: Text('How to Play',
            style: Artisan.heading(20, theme: theme)),
      ),
      extendBodyBehindAppBar: true,
      body: TableBackdrop(
        theme: theme,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              for (final (title, body) in _sections) ...[
                Text(title,
                    style: Artisan.heading(15, theme: theme)),
                const SizedBox(height: 4),
                Text(body,
                    style: Artisan.body(13.5, theme: theme)),
                const SizedBox(height: 16),
              ],
              Center(
                child: FillButton(
                  label: 'Got it — let\'s flood!',
                  emoji: '🎨',
                  onTap: () {
                    audio.click();
                    Navigator.pop(context);
                  },
                  theme: theme,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
