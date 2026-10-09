import 'dart:math';
import 'package:flutter/material.dart';
import '../engine/colorfill_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/share_kit.dart';
import '../theme/artisan.dart';
import '../theme/fill_themes.dart';
import 'rules_screen.dart';

/// Game screen: renders the engine. The engine owns all phases/timers;
/// this widget only paints, plays sounds via engine events, and persists.
class GameScreen extends StatefulWidget {
  final FillAudio audio;
  final FillSettings settings;
  final FillMode mode;
  final FillDifficulty difficulty;
  final int level; // campaign level (0 for daily/quick)
  final String title;
  final int? seed;

  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.mode,
    required this.difficulty,
    required this.level,
    required this.title,
    this.seed,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late ColorFillEngine _engine;
  late AnimationController _hintPulse;
  bool _resultShown = false;
  bool _menuPaused = false;
  bool _lifecyclePaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hintPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    final seed = widget.seed ??
        (widget.mode == FillMode.campaign
            ? widget.level * 7919 + 13
            : Random().nextInt(1 << 31));
    _engine = ColorFillEngine(
      mode: widget.mode,
      difficulty: widget.difficulty,
      level: widget.level,
      seed: seed,
    );
    _engine.onEvent = _onEngineEvent;
    _engine.addListener(_onEngineChanged);
    widget.audio.gameStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.removeListener(_onEngineChanged);
    _engine.dispose();
    _hintPulse.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lifecyclePaused = true;
      _engine.setPaused(true);
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _lifecyclePaused = false;
      widget.audio.onAppResumed();
      if (!_menuPaused) _engine.setPaused(false);
    }
  }

  Future<void> _onEngineEvent(FillEvent e) async {
    switch (e) {
      case FillEvent.fillStarted:
        widget.audio.fill();
        break;
      case FillEvent.invalidPick:
        widget.audio.invalid();
        break;
      case FillEvent.undoDone:
        widget.audio.undo();
        break;
      case FillEvent.hintShown:
        widget.audio.hint();
        break;
      case FillEvent.levelWon:
        widget.audio.levelWin();
        final due = await widget.settings.recordWin(
          level: widget.level,
          starsEarned: _engine.starsEarned,
          isDaily: widget.mode == FillMode.daily,
          dailyKey: FillSettings.dateKey(DateTime.now()),
        );
        if (due && mounted) {
          await widget.settings.reviewPrompted();
          ShareKit.maybeAskReview();
        }
        break;
      case FillEvent.allComplete:
        widget.audio.allWin();
        await widget.settings.recordWin(
          level: widget.level,
          starsEarned: _engine.starsEarned,
          isDaily: false,
          dailyKey: FillSettings.dateKey(DateTime.now()),
        );
        break;
      case FillEvent.levelFailed:
        widget.audio.lose();
        widget.settings.recordLoss();
        break;
    }
  }

  void _onEngineChanged() {
    if (_engine.phase == FillPhase.over && !_resultShown && mounted) {
      _resultShown = true;
      // Let the final frame render before the dialog pops.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _showResult();
      });
    }
  }

  FillThemeDef get _theme =>
      FillThemes.byId(widget.settings.themeId, custom: widget.settings.customTheme);

  List<Color> get _palette =>
      _theme.palette.take(_engine.colorCount).toList();

  // ------------------------------------------------------------------ build
  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    return ListenableBuilder(
      listenable: _engine,
      builder: (_, _) => Scaffold(
        body: TableBackdrop(
          theme: theme,
          child: SafeArea(
            child: Column(
              children: [
                _hud(theme),
                Expanded(child: _boardArea(theme)),
                _paletteRow(theme),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hud(FillThemeDef theme) {
    final e = _engine;
    final movesLeft = e.moveLimit - e.moves;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          FillIconButton(
            icon: Icons.pause,
            size: 42,
            onTap: _openPause,
            theme: theme,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: Artisan.heading(17, theme: theme)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _pill(
                      theme,
                      '${e.moves} / ${e.par} moves',
                      warn: e.moves > e.par,
                    ),
                    if (movesLeft <= 3 && e.phase != FillPhase.over) ...[
                      const SizedBox(width: 6),
                      _pill(theme, '⚠ $movesLeft left', warn: true),
                    ],
                  ],
                ),
              ],
            ),
          ),
          FillIconButton(
            icon: Icons.lightbulb_outline,
            size: 42,
            badge: '${e.hintsLeft}',
            onTap: e.hintsLeft > 0 && e.inputOpen ? e.showHint : null,
            theme: theme,
          ),
          const SizedBox(width: 8),
          FillIconButton(
            icon: Icons.undo,
            size: 42,
            onTap: e.inputOpen ? e.undo : null,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _pill(FillThemeDef theme, String text, {bool warn = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (warn ? const Color(0xFFE5484D) : theme.accent)
              .withValues(alpha: 0.7),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: warn ? const Color(0xFFFF8A8A) : theme.text,
        ),
      ),
    );
  }

  Widget _boardArea(FillThemeDef theme) {
    final e = _engine;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.trayLight, theme.trayDark],
              ),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.45),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  offset: const Offset(0, 10),
                  blurRadius: 22,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  offset: const Offset(0, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: e.phase == FillPhase.dealing || e.board.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: theme.accent),
                        const SizedBox(height: 10),
                        Text('Dealing the tiles…',
                            style: Artisan.body(13, theme: theme)),
                      ],
                    ),
                  )
                : CustomPaint(
                    painter: _BoardPainter(
                      engine: e,
                      palette: _palette,
                      style: widget.settings.tileStyle,
                    ),
                    child: const SizedBox.expand(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _paletteRow(FillThemeDef theme) {
    final e = _engine;
    final pal = _palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < pal.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _paintPot(theme, pal[i], i, e),
            ),
        ],
      ),
    );
  }

  Widget _paintPot(
      FillThemeDef theme, Color color, int index, ColorFillEngine e) {
    final isCurrent = e.board.isNotEmpty && e.regionColor == index;
    final isHint = e.hintColor == index;
    final open = e.inputOpen;
    Widget pot = GestureDetector(
      onTap: open ? () => e.pick(index) : null,
      child: Opacity(
        opacity: open ? 1.0 : 0.55,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.trayLight, theme.trayDark],
            ),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 4),
                blurRadius: 7,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.4),
                radius: 1.1,
                colors: [
                  Color.lerp(color, Colors.white, 0.28)!,
                  color,
                  Color.lerp(color, Colors.black, 0.25)!,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
            child: isCurrent
                ? Icon(Icons.check,
                    color: Colors.white.withValues(alpha: 0.9), size: 20)
                : null,
          ),
        ),
      ),
    );
    if (isHint) {
      pot = AnimatedBuilder(
        animation: _hintPulse,
        builder: (_, child) => Transform.scale(
          scale: 1.0 + 0.12 * _hintPulse.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: theme.accent, width: 3),
              boxShadow: [
                BoxShadow(
                  color: theme.accent.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: child,
          ),
        ),
        child: pot,
      );
    }
    return pot;
  }

  // ---------------------------------------------------------------- dialogs
  void _openPause() {
    final theme = _theme;
    widget.audio.click();
    _menuPaused = true;
    _engine.setPaused(true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FillDialog(
        title: 'Paused',
        emoji: '⏸️',
        theme: theme,
        children: [
          Text('Take a breather, ${widget.settings.playerName}.',
              style: Artisan.body(14, theme: theme),
              textAlign: TextAlign.center),
          const SizedBox(height: 18),
          FillButton(
            label: 'Resume',
            emoji: '▶️',
            onTap: () {
              widget.audio.click();
              Navigator.pop(ctx);
            },
            theme: theme,
          ),
          const SizedBox(height: 10),
          FillButton(
            label: 'Restart board',
            emoji: '🔄',
            primary: false,
            onTap: () {
              widget.audio.click();
              Navigator.pop(ctx);
              _resultShown = false;
              _engine.restart();
            },
            theme: theme,
          ),
          const SizedBox(height: 10),
          FillButton(
            label: 'How to Play',
            emoji: '❓',
            primary: false,
            onTap: () {
              widget.audio.click();
              Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (_) => RulesScreen(
                      audio: widget.audio,
                      settings: widget.settings,
                      theme: theme),
                ),
              );
            },
            theme: theme,
          ),
          const SizedBox(height: 10),
          FillButton(
            label: 'Quit to menu',
            emoji: '🏠',
            primary: false,
            onTap: () {
              widget.audio.click();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            theme: theme,
          ),
        ],
      ),
    ).then((_) {
      _menuPaused = false;
      if (!_lifecyclePaused && _engine.phase != FillPhase.over) {
        _engine.setPaused(false);
      }
      widget.audio.startGameMusic();
    });
  }

  void _showResult() {
    final theme = _theme;
    final e = _engine;
    final won = !e.failed;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FillDialog(
        title: won ? _winTitle() : 'Out of moves!',
        emoji: won ? '🎉' : '😅',
        theme: theme,
        children: [
          if (won) ...[
            _AnimatedStars(stars: e.starsEarned, theme: theme),
            const SizedBox(height: 10),
            Text(
              '${e.moves} moves · par ${e.par}',
              style: Artisan.body(14, theme: theme),
              textAlign: TextAlign.center,
            ),
            if (widget.mode == FillMode.daily)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Daily streak: ${widget.settings.dailyStreak} 🔥',
                  style: Artisan.heading(15, theme: theme),
                  textAlign: TextAlign.center,
                ),
              ),
          ] else
            Text(
              'The paint ran dry with ${e.moves} moves.\nGive it another go!',
              style: Artisan.body(14, theme: theme),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 18),
          if (won && _hasNext())
            FillButton(
              label: _nextLabel(),
              emoji: '➡️',
              onTap: () {
                widget.audio.click();
                Navigator.pop(ctx);
                _goNext();
              },
              theme: theme,
            ),
          if (won && _hasNext()) const SizedBox(height: 10),
          FillButton(
            label: won ? 'Play again' : 'Retry board',
            emoji: '🔄',
            primary: false,
            onTap: () {
              widget.audio.click();
              Navigator.pop(ctx);
              _resultShown = false;
              _engine.restart();
            },
            theme: theme,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FillButton(
                label: 'Share',
                emoji: '📣',
                small: true,
                primary: false,
                onTap: () {
                  widget.audio.click();
                  ShareKit.shareWin(
                    playerName: widget.settings.playerName,
                    stars: e.starsEarned,
                    level: widget.level,
                    modeName: widget.title,
                  );
                },
                theme: theme,
              ),
              const SizedBox(width: 10),
              FillButton(
                label: 'Menu',
                emoji: '🏠',
                small: true,
                primary: false,
                onTap: () {
                  widget.audio.click();
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    ).then((_) {
      // If the user dismissed via back button, still go back to the menu.
      if (mounted && _engine.phase == FillPhase.over) {
        // Dialog was dismissed without a choice — stay; the board is done.
      }
    });
  }

  String _winTitle() {
    if (_engine.starsEarned == 3) return 'Flooded in style!';
    if (_engine.starsEarned == 2) return 'Board flooded!';
    switch (widget.mode) {
      case FillMode.campaign:
        return 'Level ${widget.level} cleared!';
      case FillMode.daily:
        return 'Daily flooded!';
      case FillMode.quick:
        return 'Board flooded!';
    }
  }

  bool _hasNext() {
    if (widget.mode == FillMode.campaign) return widget.level < 20;
    if (widget.mode == FillMode.quick) return true;
    return false; // daily: one board per day
  }

  String _nextLabel() {
    if (widget.mode == FillMode.campaign) return 'Next level';
    return 'New board';
  }

  void _goNext() {
    final settings = widget.settings;
    final audio = widget.audio;
    if (widget.mode == FillMode.campaign) {
      final next = widget.level + 1;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            audio: audio,
            settings: settings,
            mode: FillMode.campaign,
            difficulty: MenuScreen.campaignDifficulty(next),
            level: next,
            title: 'Level $next',
          ),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameScreen(
            audio: audio,
            settings: settings,
            mode: FillMode.quick,
            difficulty: widget.difficulty,
            title: widget.title,
          ),
        ),
      );
    }
  }
}

/// Staggered star pop for the win dialog.
class _AnimatedStars extends StatefulWidget {
  final int stars;
  final FillThemeDef theme;
  const _AnimatedStars({required this.stars, required this.theme});

  @override
  State<_AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<_AnimatedStars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final t = (_c.value * 3 - i).clamp(0.0, 1.0);
              final eased = 1 - pow(1 - t, 3).toDouble();
              return Transform.scale(
                scale: 0.3 + 0.7 * eased,
                child: Opacity(
                  opacity: t,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      i < widget.stars ? Icons.star : Icons.star_border,
                      color: i < widget.stars
                          ? widget.theme.accent
                          : widget.theme.textSoft
                              .withValues(alpha: 0.4),
                      size: 44,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Board painter: physical tiles with weight. One CustomPaint draws the whole
// board; the engine's notifyListeners drives repaints during the flood wave.
// ---------------------------------------------------------------------------
class _BoardPainter extends CustomPainter {
  final ColorFillEngine engine;
  final List<Color> palette;
  final int style;

  _BoardPainter({
    required this.engine,
    required this.palette,
    required this.style,
  });

  int _hash(int r, int c) => (r * 73856093) ^ (c * 19349663) ^ 0x9E3779B9;

  Color _cellColor(int r, int c) {
    final w = engine.wave[r][c];
    int idx;
    if (engine.phase == FillPhase.flooding && w >= 0) {
      final front = engine.floodProgress * engine.waveTotal;
      idx = w < front ? engine.board[r][c] : engine.displayBoard[r][c];
    } else {
      idx = engine.board[r][c];
    }
    return palette[idx.clamp(0, palette.length - 1)];
  }

  double _pulse(int r, int c) {
    if (engine.phase != FillPhase.flooding) return 0.0;
    final w = engine.wave[r][c];
    if (w < 0) return 0.0;
    final front = engine.floodProgress * engine.waveTotal;
    final d = (front - w).abs();
    return d < 2.0 ? 1.0 - d / 2.0 : 0.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = engine.n;
    final cell = size.width / n;
    final gap = cell * 0.07;
    for (int r = 0; r < n; r++) {
      for (int c = 0; c < n; c++) {
        var rect = Rect.fromLTWH(
          c * cell + gap / 2,
          r * cell + gap / 2,
          cell - gap,
          cell - gap,
        );
        final pulse = _pulse(r, c);
        if (pulse > 0) {
          final grow = rect.shortestSide * 0.05 * pulse;
          rect = rect.inflate(grow);
        }
        _paintTile(
            canvas, rect, _cellColor(r, c), _hash(r, c).abs(), pulse);
      }
    }
  }

  void _paintTile(
      Canvas canvas, Rect rect, Color color, int hash, double pulse) {
    double radiusFrac = 0.22;
    switch (style) {
      case 1:
        radiusFrac = 0.5; // pebble
        break;
      case 2:
        radiusFrac = 0.14; // wood block
        break;
      case 3:
        radiusFrac = 0.2; // marble
        break;
      case 4:
        radiusFrac = 0.3; // candy
        break;
      case 5:
        radiusFrac = 0.18; // ceramic
        break;
      case 6:
        radiusFrac = 0.1 + 0.05 * (hash % 3); // slate
        break;
      case 7:
        radiusFrac = 0.38; // pillow
        break;
    }
    final radius = Radius.circular(rect.shortestSide * radiusFrac);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, radius));

    // Drop shadow: the tile's weight.
    canvas.save();
    canvas.translate(0, rect.height * 0.07);
    canvas.drawPath(
        path, Paint()..color = Colors.black.withValues(alpha: 0.3));
    canvas.restore();

    // Base.
    final base = style == 7
        ? _radial(rect, color, 0.18, -0.18)
        : _vertical(rect, color, 0.1, -0.12);
    canvas.drawPath(path, Paint()..shader = base);

    canvas.save();
    canvas.clipPath(path);

    // Top light / bottom shade give the bevel.
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.45),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - rect.height * 0.32, rect.width,
          rect.height * 0.32),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    // Style-specific surface detail (deterministic per tile).
    final rnd = Random(hash);
    switch (style) {
      case 2: // wood grain
        for (int i = 0; i < 2; i++) {
          final y = rect.top + rect.height * (0.3 + 0.35 * rnd.nextDouble());
          canvas.drawLine(
            Offset(rect.left + 2, y),
            Offset(rect.right - 2, y + (rnd.nextDouble() - 0.5) * 6),
            Paint()
              ..color = Colors.brown.withValues(alpha: 0.18)
              ..strokeWidth = 1.6,
          );
        }
        break;
      case 3: // marble veins
        for (int i = 0; i < 2; i++) {
          final p = Path()
            ..moveTo(rect.left + rnd.nextDouble() * rect.width, rect.top)
            ..quadraticBezierTo(
              rect.left + rnd.nextDouble() * rect.width,
              rect.top + rect.height * 0.5,
              rect.left + rnd.nextDouble() * rect.width,
              rect.bottom,
            );
          canvas.drawPath(
            p,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.3)
              ..strokeWidth = 1.4
              ..style = PaintingStyle.stroke,
          );
        }
        break;
      case 4: // candy gloss
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(rect.center.dx, rect.top + rect.height * 0.3),
            width: rect.width * 0.62,
            height: rect.height * 0.3,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.42),
        );
        break;
      case 5: // ceramic speckles
        for (int i = 0; i < 5; i++) {
          canvas.drawCircle(
            Offset(
              rect.left + rnd.nextDouble() * rect.width,
              rect.top + rnd.nextDouble() * rect.height,
            ),
            1.3,
            Paint()..color = Colors.black.withValues(alpha: 0.16),
          );
        }
        break;
      case 6: // slate top edge
        canvas.drawLine(
          Offset(rect.left + 3, rect.top + 2.5),
          Offset(rect.right - 3, rect.top + 2.5),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.25)
            ..strokeWidth = 1.6,
        );
        break;
      case 1: // pebble highlight
        canvas.drawCircle(
          Offset(rect.left + rect.width * 0.32, rect.top + rect.height * 0.3),
          rect.shortestSide * 0.16,
          Paint()..color = Colors.white.withValues(alpha: 0.35),
        );
        break;
    }

    // Wave-front glow on freshly flooded tiles (warm, not neon).
    if (pulse > 0) {
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: 0.22 * pulse),
      );
    }
    canvas.restore();

    // Crisp darker rim.
    canvas.drawPath(
      path,
      Paint()
        ..color = _darken(color, 0.72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  Shader _vertical(Rect r, Color c, double light, double dark) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(c, Colors.white, light)!,
          c,
          Color.lerp(c, Colors.black, -dark)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(r);

  Shader _radial(Rect r, Color c, double light, double dark) => RadialGradient(
        center: const Alignment(0, -0.15),
        radius: 1.15,
        colors: [
          Color.lerp(c, Colors.white, light)!,
          c,
          Color.lerp(c, Colors.black, -dark)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(r);

  Color _darken(Color c, double f) => Color.fromARGB(
        c.alpha,
        (c.red * f).round(),
        (c.green * f).round(),
        (c.blue * f).round(),
      );

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
