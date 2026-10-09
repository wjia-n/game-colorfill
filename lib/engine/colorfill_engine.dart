import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Color Fill engine: deterministic flood-fill puzzle logic.
//
// The engine owns ALL phases and ALL timers. The UI only renders. A watchdog
// recovers any phase found without a live timer, so stuck states are
// impossible by construction.
// ---------------------------------------------------------------------------

/// Play modes.
enum FillMode { campaign, daily, quick }

/// Turn phases owned entirely by the engine. The UI only renders.
enum FillPhase {
  dealing, // board is being generated
  awaitingPick, // player may pick a color
  flooding, // flood wave animating — input locked
  hinting, // hint highlight showing (input still allowed, cancels hint)
  resolving, // win/fail celebration — input locked
  over, // terminal: UI shows the result dialog
}

enum FillEvent {
  fillStarted, // play the pour sound as the wave spreads
  invalidPick, // picked the current region color / locked phase
  undoDone,
  hintShown,
  levelWon, // payload in engine.starsEarned
  levelFailed,
  allComplete, // finished the final campaign level
}

/// Difficulty tiers. Easy/Medium are free; Hard is a Pro feature.
enum FillDifficulty { easy, medium, hard }

int difficultyIndex(FillDifficulty d) => d.index;

FillDifficulty difficultyFromIndex(int i) =>
    FillDifficulty.values[i.clamp(0, 2)];

/// Board parameters per difficulty.
class FillParams {
  final int size;
  final int colors;
  final int minGreedy; // minimum greedy-solver moves for a valid board
  const FillParams(this.size, this.colors, this.minGreedy);
}

FillParams paramsFor(FillDifficulty d) => switch (d) {
      FillDifficulty.easy => const FillParams(8, 5, 5),
      FillDifficulty.medium => const FillParams(10, 6, 7),
      FillDifficulty.hard => const FillParams(12, 7, 9),
    };

class ColorFillEngine extends ChangeNotifier {
  final FillMode mode;
  final FillDifficulty difficulty;
  final int level; // campaign level 1..20 (0 for daily/quick)
  final int seed;
  late final FillParams params;

  late List<List<int>> board; // logical board (post-flood at settle)
  late List<List<int>> displayBoard; // rendered board (pre-flood mid-anim)
  late List<List<int>> wave; // per-cell wave step, -1 = unchanged
  int waveTotal = 1;
  double floodProgress = 0.0; // 0..1 while flooding

  int moves = 0;
  int par = 1;
  int moveLimit = 1;
  int hintsLeft = 3;
  int? hintColor; // palette index highlighted, or null
  int starsEarned = 0;
  bool failed = false;
  bool paused = false;

  FillPhase phase = FillPhase.dealing;

  /// UI hook for sounds / haptics / persistence. Set by the screen.
  void Function(FillEvent event)? onEvent;

  Timer? _timer; // single phase timer (one-shot or periodic)
  Timer? _watchdog;
  bool _disposed = false;

  final List<_Snapshot> _undo = [];

  static const _floodTickMs = 45;
  static const _floodCellsPerTick = 6;
  static const _hintMs = 2400;
  static const _resolveMs = 1600;

  ColorFillEngine({
    required this.mode,
    required this.difficulty,
    this.level = 0,
    int? seed,
  }) : seed = seed ?? Random().nextInt(1 << 31) {
    params = paramsFor(difficulty);
    board = [];
    displayBoard = [];
    wave = [];
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    _deal();
  }

  int get n => params.size;
  int get colorCount => params.colors;
  int get regionColor => board.isEmpty ? 0 : board[0][0];
  bool get inputOpen =>
      (phase == FillPhase.awaitingPick || phase == FillPhase.hinting) &&
      !paused;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _armOneShot(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  void _armPeriodic(Duration d, void Function(Timer t) fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer.periodic(d, (t) {
      if (_disposed || paused) {
        t.cancel();
        return;
      }
      fn(t);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _cancelTimer();
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress, recover.
  /// Respects [paused].
  void _recover() {
    if (_disposed || paused || _timer != null) return;
    switch (phase) {
      case FillPhase.dealing:
        _deal();
        break;
      case FillPhase.flooding:
        _settleFlood(); // wave died mid-flight: snap to the solved flood
        break;
      case FillPhase.hinting:
        hintColor = null;
        phase = FillPhase.awaitingPick;
        notifyListeners();
        break;
      case FillPhase.resolving:
        _finishResolve();
        break;
      case FillPhase.awaitingPick:
      case FillPhase.over:
        break; // stable phases: nothing to recover
    }
  }

  // ------------------------------------------------------------ board setup
  void _deal() {
    phase = FillPhase.dealing;
    _undo.clear();
    moves = 0;
    hintsLeft = 3;
    hintColor = null;
    starsEarned = 0;
    failed = false;
    floodProgress = 0.0;
    notifyListeners();
    // Generation is fast, but run it behind a short timer so the dealing
    // shimmer actually shows and the phase is real (watchdog-verifiable).
    _armOneShot(const Duration(milliseconds: 180), () {
      final rnd = Random(seed);
      List<List<int>> b = [];
      int guard = 0;
      do {
        b = List.generate(
            n, (_) => List.generate(n, (_) => rnd.nextInt(colorCount)));
        guard++;
      } while (guard < 90 &&
          (!_allColorsPresent(b) || _greedyMoves(b) < params.minGreedy));
      board = b;
      displayBoard = [for (final r in b) [...r]];
      wave = List.generate(n, (_) => List.filled(n, -1));
      par = max(1, _greedyMoves(b));
      moveLimit = par + 8;
      phase = FillPhase.awaitingPick;
      notifyListeners();
    });
  }

  /// Restart with the SAME seed (retry the same board after a fail).
  void restart() {
    _cancelTimer();
    paused = false;
    _deal();
  }

  bool _allColorsPresent(List<List<int>> b) {
    final seen = <int>{};
    for (final row in b) {
      seen.addAll(row);
    }
    return seen.length == colorCount;
  }

  // ------------------------------------------------------------- flood core
  Set<String> _regionOf(List<List<int>> b) {
    final color = b[0][0];
    final seen = <String>{'0,0'};
    final stack = <List<int>>[
      [0, 0]
    ];
    while (stack.isNotEmpty) {
      final cell = stack.removeLast();
      for (final d in const [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1]
      ]) {
        final nr = cell[0] + d[0], nc = cell[1] + d[1];
        final key = '$nr,$nc';
        if (nr >= 0 &&
            nr < n &&
            nc >= 0 &&
            nc < n &&
            !seen.contains(key) &&
            b[nr][nc] == color) {
          seen.add(key);
          stack.add([nr, nc]);
        }
      }
    }
    return seen;
  }

  /// Flood the region with [color], returning the wave-step of every cell
  /// (0 = old region, 1+ = distance from the old boundary, -1 = unchanged).
  /// The logical board is updated in place.
  List<List<int>> _applyFlood(List<List<int>> b, int color) {
    final oldRegion = _regionOf(b);
    for (final key in oldRegion) {
      final parts = key.split(',');
      b[int.parse(parts[0])][int.parse(parts[1])] = color;
    }
    // BFS from the old boundary through new-color cells.
    final waveSteps =
        List.generate(n, (_) => List.filled(n, -1));
    final queue = <List<int>>[];
    for (final key in oldRegion) {
      final parts = key.split(',');
      final r = int.parse(parts[0]), c = int.parse(parts[1]);
      waveSteps[r][c] = 0;
      queue.add([r, c, 0]);
    }
    int qi = 0;
    while (qi < queue.length) {
      final cur = queue[qi++];
      final r = cur[0], c = cur[1], s = cur[2];
      for (final d in const [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1]
      ]) {
        final nr = r + d[0], nc = c + d[1];
        if (nr >= 0 && nr < n && nc >= 0 && nc < n && waveSteps[nr][nc] == -1) {
          if (b[nr][nc] == color) {
            waveSteps[nr][nc] = s + 1;
            queue.add([nr, nc, s + 1]);
          }
        }
      }
    }
    return waveSteps;
  }

  bool _solved(List<List<int>> b) {
    final c = b[0][0];
    for (final row in b) {
      for (final v in row) {
        if (v != c) return false;
      }
    }
    return true;
  }

  /// Greedy solver: always flood the color that grows the region most.
  /// Returns the move count — a solid upper bound used for par.
  int _greedyMoves(List<List<int>> start) {
    var b = [for (final r in start) [...r]];
    int count = 0;
    while (!_solved(b) && count < 80) {
      final region = _regionOf(b);
      int bestC = -1, bestGain = -1;
      for (int c = 0; c < colorCount; c++) {
        if (c == b[0][0]) continue;
        int gain = 0;
        final seen = <String>{};
        for (final key in region) {
          final parts = key.split(',');
          final r = int.parse(parts[0]), cc = int.parse(parts[1]);
          for (final d in const [
            [1, 0],
            [-1, 0],
            [0, 1],
            [0, -1]
          ]) {
            final nr = r + d[0], nc = cc + d[1];
            final k2 = '$nr,$nc';
            if (nr >= 0 &&
                nr < n &&
                nc >= 0 &&
                nc < n &&
                !seen.contains(k2) &&
                b[nr][nc] == c) {
              seen.add(k2);
              gain++;
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
      count++;
    }
    return count;
  }

  /// Greedy best next color (used for hints).
  int _bestMove() {
    final region = _regionOf(board);
    int bestC = -1, bestGain = -1;
    for (int c = 0; c < colorCount; c++) {
      if (c == board[0][0]) continue;
      int gain = 0;
      final seen = <String>{};
      for (final key in region) {
        final parts = key.split(',');
        final r = int.parse(parts[0]), cc = int.parse(parts[1]);
        for (final d in const [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1]
        ]) {
          final nr = r + d[0], nc = cc + d[1];
          final k2 = '$nr,$nc';
          if (nr >= 0 &&
              nr < n &&
              nc >= 0 &&
              nc < n &&
              !seen.contains(k2) &&
              board[nr][nc] == c) {
            seen.add(k2);
            gain++;
          }
        }
      }
      if (gain > bestGain) {
        bestGain = gain;
        bestC = c;
      }
    }
    return bestC < 0 ? (board[0][0] + 1) % colorCount : bestC;
  }

  // ------------------------------------------------------------------ input
  /// Player picks a palette color. Guarded: only in open phases, and never
  /// the current region color (a no-op pick is an invalid move, not a crash).
  void pick(int color) {
    if (!inputOpen || board.isEmpty) {
      onEvent?.call(FillEvent.invalidPick);
      return;
    }
    if (color == board[0][0]) {
      onEvent?.call(FillEvent.invalidPick);
      return;
    }
    // Picking cancels a visible hint.
    if (phase == FillPhase.hinting) {
      _cancelTimer();
      hintColor = null;
    }
    _undo.add(_Snapshot(board, moves));
    if (_undo.length > 30) _undo.removeAt(0);
    displayBoard = [for (final r in board) [...r]];
    wave = _applyFlood(board, color);
    waveTotal = 1;
    for (final row in wave) {
      for (final s in row) {
        if (s + 1 > waveTotal) waveTotal = s + 1;
      }
    }
    moves++;
    floodProgress = 0.0;
    phase = FillPhase.flooding;
    onEvent?.call(FillEvent.fillStarted);
    notifyListeners();
    _armPeriodic(const Duration(milliseconds: _floodTickMs), (t) {
      floodProgress += _floodCellsPerTick / waveTotal;
      if (floodProgress >= 1.0) {
        t.cancel();
        _timer = null;
        _settleFlood();
      } else {
        notifyListeners();
      }
    });
  }

  void _settleFlood() {
    if (phase != FillPhase.flooding || _disposed) return;
    _cancelTimer();
    floodProgress = 1.0;
    displayBoard = [for (final r in board) [...r]];
    wave = List.generate(n, (_) => List.filled(n, -1));
    if (_solved(board)) {
      _beginResolve(won: true);
      return;
    }
    if (moves >= moveLimit) {
      _beginResolve(won: false);
      return;
    }
    phase = FillPhase.awaitingPick;
    notifyListeners();
  }

  void undo() {
    if (!inputOpen || _undo.isEmpty || board.isEmpty) {
      onEvent?.call(FillEvent.invalidPick);
      return;
    }
    if (phase == FillPhase.hinting) {
      _cancelTimer();
      hintColor = null;
    }
    final s = _undo.removeLast();
    board = [for (final r in s.board) [...r]];
    displayBoard = [for (final r in board) [...r]];
    wave = List.generate(n, (_) => List.filled(n, -1));
    moves = max(0, s.moves);
    phase = FillPhase.awaitingPick;
    onEvent?.call(FillEvent.undoDone);
    notifyListeners();
  }

  void showHint() {
    if (!inputOpen || board.isEmpty || hintsLeft <= 0) {
      onEvent?.call(FillEvent.invalidPick);
      return;
    }
    hintsLeft--;
    hintColor = _bestMove();
    phase = FillPhase.hinting;
    onEvent?.call(FillEvent.hintShown);
    notifyListeners();
    _armOneShot(const Duration(milliseconds: _hintMs), () {
      if (phase == FillPhase.hinting) {
        hintColor = null;
        phase = FillPhase.awaitingPick;
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------------- resolve
  void _beginResolve({required bool won}) {
    phase = FillPhase.resolving;
    failed = !won;
    if (won) {
      starsEarned = moves <= par
          ? 3
          : (moves <= par + 3 ? 2 : 1);
    }
    notifyListeners(); // UI starts its celebration animation now
    _armOneShot(const Duration(milliseconds: _resolveMs), _finishResolve);
  }

  void _finishResolve() {
    if (phase != FillPhase.resolving || _disposed) return;
    phase = FillPhase.over;
    notifyListeners();
    if (failed) {
      onEvent?.call(FillEvent.levelFailed);
    } else if (mode == FillMode.campaign && level >= 20) {
      onEvent?.call(FillEvent.allComplete);
    } else {
      onEvent?.call(FillEvent.levelWon);
    }
  }

  // -------------------------------------------------------------- test hook
  @visibleForTesting
  void debugSetBoard(List<List<int>> b) {
    board = [for (final r in b) [...r]];
    displayBoard = [for (final r in b) [...r]];
    wave = List.generate(b.length, (_) => List.filled(b.length, -1));
    phase = FillPhase.awaitingPick;
    notifyListeners();
  }
}

class _Snapshot {
  final List<List<int>> board;
  final int moves;
  _Snapshot(this.board, this.moves);
}
