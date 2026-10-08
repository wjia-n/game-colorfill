import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

const _n = 10;
const _levels = 20;
const _fillColors = <Color>[
  Color(0xFFE5484D),
  Color(0xFFFF9F2E),
  Color(0xFFFFD60A),
  Color(0xFF30D158),
  Color(0xFF0A84FF),
  Color(0xFFBF5AF2),
];

class ColorFillScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const ColorFillScreen(
      {super.key, required this.players, required this.callbacks});

  @override
  State<ColorFillScreen> createState() => _ColorFillScreenState();
}

class _ColorFillScreenState extends State<ColorFillScreen> {
  int _level = 1;
  int _unlocked = 1;
  List<List<int>> _board = [];
  int _moves = 0;
  int _par = 20;
  bool _over = false;
  final List<List<List<int>>> _undo = [];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _unlocked = p.getInt('cf_unlocked') ?? 1;
        _level = min(_unlocked, _levels);
      });
      _deal();
    });
    _deal();
  }

  // Deterministic curated levels: pick seeds that give colorful,
  // non-trivial boards (greedy solver needs >= 7 moves).
  void _deal() {
    final rnd = Random(_level * 7919 + 13);
    List<List<int>> board = [];
    int guard = 0;
    do {
      board = List.generate(
          _n, (_) => List.generate(_n, (_) => rnd.nextInt(6)));
      guard++;
    } while (guard < 60 &&
        (!_allColorsPresent(board) || _greedyMoves(board) < 7));
    _board = board;
    _par = 15 + _level; // par grows gently with level
    _moves = 0;
    _over = false;
    _undo.clear();
    setState(() {});
  }

  bool _allColorsPresent(List<List<int>> b) {
    final seen = <int>{};
    for (final row in b) {
      seen.addAll(row);
    }
    return seen.length == 6;
  }

  // Greedy lower-bound estimate of difficulty: always flood the color that
  // grows the region most. Returns moves to solve.
  int _greedyMoves(List<List<int>> start) {
    var b = [for (final r in start) [...r]];
    int moves = 0;
    while (!_solved(b) && moves < 60) {
      final region = _region(b);
      int bestC = -1, bestGain = -1;
      for (int c = 0; c < 6; c++) {
        if (c == b[0][0]) continue;
        int gain = 0;
        final seen = <String>{};
        final stack = <List<int>>[];
        for (final cell in region) {
          final r = cell[0], cc = cell[1];
          for (final d in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
            final nr = r + d[0], nc = cc + d[1];
            final key = '$nr,$nc';
            if (nr >= 0 && nr < _n && nc >= 0 && nc < _n && !seen.contains(key)) {
              seen.add(key);
              if (b[nr][nc] == c) {
                gain++;
                stack.add([nr, nc]);
              }
            }
          }
        }
        if (gain > bestGain) {
          bestGain = gain;
          bestC = c;
        }
      }
      if (bestC == -1) break;
      _applyFlood(b, bestC);
      moves++;
    }
    return moves;
  }

  Set<List<int>> _region(List<List<int>> b) {
    final color = b[0][0];
    final seen = <String>{'0,0'};
    final out = <List<int>>{};
    final stack = <List<int>>[
      [0, 0]
    ];
    while (stack.isNotEmpty) {
      final cell = stack.removeLast();
      out.add(cell);
      for (final d in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        final nr = cell[0] + d[0], nc = cell[1] + d[1];
        final key = '$nr,$nc';
        if (nr >= 0 &&
            nr < _n &&
            nc >= 0 &&
            nc < _n &&
            !seen.contains(key) &&
            b[nr][nc] == color) {
          seen.add(key);
          stack.add([nr, nc]);
        }
      }
    }
    return out;
  }

  void _applyFlood(List<List<int>> b, int color) {
    final old = b[0][0];
    if (old == color) return;
    final stack = <List<int>>[
      [0, 0]
    ];
    final seen = <String>{'0,0'};
    while (stack.isNotEmpty) {
      final cell = stack.removeLast();
      b[cell[0]][cell[1]] = color;
      for (final d in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        final nr = cell[0] + d[0], nc = cell[1] + d[1];
        final key = '$nr,$nc';
        if (nr >= 0 &&
            nr < _n &&
            nc >= 0 &&
            nc < _n &&
            !seen.contains(key) &&
            b[nr][nc] == old) {
          seen.add(key);
          stack.add([nr, nc]);
        }
      }
    }
  }

  bool _solved(List<List<int>> b) {
    final c = b[0][0];
    return b.every((row) => row.every((v) => v == c));
  }

  void _pick(int color) {
    if (_over || _board.isEmpty || _board[0][0] == color) return;
    _undo.add([for (final r in _board) [...r]]);
    setState(() {
      _applyFlood(_board, color);
      _moves++;
    });
    Sfx.move();
    if (_solved(_board)) _winLevel();
  }

  void _undoMove() {
    if (_over || _undo.isEmpty) return;
    setState(() {
      _board = _undo.removeLast();
      _moves = max(0, _moves - 1);
    });
    Sfx.click();
  }

  int _stars() {
    if (_moves <= _par) return 3;
    if (_moves <= _par + 5) return 2;
    return 1;
  }

  Future<void> _winLevel() async {
    setState(() => _over = true);
    Sfx.win();
    final s = _stars();
    widget.players.first.score += s * 100 + _level * 10;
    widget.callbacks.refreshHud();
    if (_level == _unlocked && _unlocked < _levels) {
      _unlocked++;
      final p = await SharedPreferences.getInstance();
      await p.setInt('cf_unlocked', _unlocked);
      await p.setInt('cf_stars_$_level', s);
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_level >= _levels) {
      widget.callbacks.finish(
        headline: '🎨 All 20 boards flooded!',
        subline: 'A true color master. Museums are calling.',
      );
    } else {
      setState(() => _level++);
      _deal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WajihaButton(
                  label: 'Level $_level',
                  emoji: '🎨',
                  primary: false,
                  onTap: _showLevels),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: theme.surface, borderRadius: theme.radius),
                child: Text('$_moves / $_par moves',
                    style: TextStyle(
                        color: _moves > _par ? theme.accent : theme.text,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              WajihaButton(
                  label: 'Undo',
                  emoji: '↩️',
                  primary: false,
                  onTap: _undoMove),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: _board.isEmpty
                ? const CircularProgressIndicator()
                : LayoutBuilder(builder: (ctx, c) {
                    final size = min(c.maxWidth, c.maxHeight);
                    final cell = size / _n;
                    return SizedBox(
                      width: size,
                      height: size,
                      child: Column(
                        children: [
                          for (int r = 0; r < _n; r++)
                            Row(
                              children: [
                                for (int cIdx = 0; cIdx < _n; cIdx++)
                                  AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 220),
                                    width: cell,
                                    height: cell,
                                    decoration: BoxDecoration(
                                      color: _fillColors[_board[r][cIdx]],
                                      borderRadius: BorderRadius.circular(
                                          cell * 0.22),
                                    ),
                                    margin: EdgeInsets.all(cell * 0.04),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int c = 0; c < 6; c++)
                GestureDetector(
                  onTap: () => _pick(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: _fillColors[c],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _board.isNotEmpty && _board[0][0] == c
                              ? theme.text
                              : Colors.transparent,
                          width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showLevels() {
    final theme = ThemeController.of(context).theme;
    showDialog(
      context: context,
      builder: (ctx) => WajihaDialog(
        title: 'Pick a level',
        emoji: '🎨',
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (int l = 1; l <= _levels; l++)
                GestureDetector(
                  onTap: l <= _unlocked
                      ? () {
                          Navigator.pop(ctx);
                          setState(() => _level = l);
                          _deal();
                          Sfx.click();
                        }
                      : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: l == _level
                          ? theme.primary
                          : (l <= _unlocked ? theme.surface : theme.background),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: l <= _unlocked ? theme.primary : theme.muted),
                    ),
                    child: Text(l <= _unlocked ? '$l' : '🔒',
                        style: TextStyle(
                            color: l == _level ? Colors.white : theme.text,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
