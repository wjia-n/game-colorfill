import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/fill_themes.dart';

/// Persisted settings + stats for Color Fill.
///
/// The renameable player profile is persisted as ONE order-preserving JSON
/// string under [colorfill_player_names_json] via setString — NEVER
/// setStringList (on Android a StringList is backed by an unordered
/// StringSet and comes back scrambled). It is saved on every keystroke and
/// committed on focus loss, with one-time migration from legacy keys.
/// Everything else (progress, stats, theme) lives in a separate profile
/// JSON under [_kProfile].
class FillSettings extends ChangeNotifier {
  static const _kProfile = 'cf_profile_json';
  // Renameable player profile: ONE order-preserving JSON string.
  // NEVER setStringList — Android backs it with an unordered StringSet.
  static const _kNamesJson = 'colorfill_player_names_json';
  // Legacy keys from the v1 build — migrated once, then deleted.
  static const _kLegacyName = 'cf_player_name';
  static const _kLegacyUnlocked = 'cf_unlocked';
  static const _kLegacyStarsPrefix = 'cf_stars_';

  static const defaultName = 'Player';

  /// Single renameable player slot, kept as an order-preserving list so the
  /// format stays future-proof (Color Fill is single-player: slot 0 only).
  List<String> playerNames = [defaultName];

  /// The display name — always the first (and only) profile slot.
  String get playerName =>
      playerNames.isNotEmpty ? playerNames.first : defaultName;

  static const List<int> defaultCustomPalette = [
    0xFFE5484D,
    0xFFFF9F2E,
    0xFFFFD60A,
    0xFF30B158,
    0xFF2E9BF0,
    0xFF9B6BF3,
  ];
  static const int defaultCustomBg = 0xFF4A3428;

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String themeId = 'toybox';
  int tileStyle = 0;
  List<int> customPalette = List.of(defaultCustomPalette);
  int customBg = defaultCustomBg;
  int quickDifficulty = 1; // 0 easy, 1 medium, 2 hard (hard = Pro)
  int unlocked = 1; // campaign levels unlocked (1..20)
  Map<int, int> stars = {}; // level -> 1..3
  int games = 0;
  int wins = 0;
  int dailyStreak = 0;
  String lastDaily = ''; // yyyy-MM-dd of last completed daily
  int winsForReview = 0; // wins since last review prompt
  bool isPro = false;

  /// The custom theme built from the user's own colors (Pro feature).
  FillThemeDef get customTheme => FillThemeDef(
        id: 'custom',
        name: 'My Creation',
        tableDark: const Color(0xFF241611),
        tableMid: Color(customBg),
        trayLight: const Color(0xFF6B4A2E),
        trayDark: const Color(0xFF3A2413),
        accent: const Color(0xFFE3B968),
        accentDark: const Color(0xFF9D7F45),
        text: const Color(0xFFF9F0E0),
        textSoft: const Color(0xFFCBB08E),
        palette: [
          for (final a in customPalette) Color(a),
          const Color(0xFF2EC4B6),
          const Color(0xFFF26D9D),
        ],
        paletteNames: const [
          'Custom 1',
          'Custom 2',
          'Custom 3',
          'Custom 4',
          'Custom 5',
          'Custom 6',
          'Lagoon',
          'Rose'
        ],
      );

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    final raw = p.getString(_kProfile);
    if (raw != null) {
      _decode(raw);
    }
    _migrateNames(p);
    _migrateLegacy(p);
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  void _decode(String raw) {
    try {
      final d = jsonDecode(raw);
      if (d is! Map) return;
      playerNames = [_cleanName(d['name'])]; // may be re-seeded by _migrateNames
      musicOn = d['music'] is bool ? d['music'] as bool : true;
      sfxOn = d['sfx'] is bool ? d['sfx'] as bool : true;
      volume = (d['volume'] is num ? (d['volume'] as num).toDouble() : 0.8)
          .clamp(0.0, 1.0);
      themeId = d['theme'] is String ? d['theme'] as String : 'toybox';
      tileStyle = (d['tile'] is int ? d['tile'] as int : 0).clamp(0, 7);
      final pal = d['palette'];
      if (pal is List && pal.length == 6 && pal.every((e) => e is int)) {
        customPalette = [for (final e in pal) e as int];
      }
      if (d['bg'] is int) customBg = d['bg'] as int;
      quickDifficulty =
          (d['diff'] is int ? d['diff'] as int : 1).clamp(0, 2);
      unlocked = (d['unlocked'] is int ? d['unlocked'] as int : 1).clamp(1, 20);
      final st = d['stars'];
      if (st is Map) {
        stars = {
          for (final e in st.entries)
            int.tryParse('${e.key}') ?? -1: (e.value is int
                ? (e.value as int).clamp(1, 3)
                : 1)
        }..remove(-1);
      }
      games = d['games'] is int ? d['games'] as int : 0;
      wins = d['wins'] is int ? d['wins'] as int : 0;
      dailyStreak = d['streak'] is int ? d['streak'] as int : 0;
      lastDaily = d['lastDaily'] is String ? d['lastDaily'] as String : '';
      winsForReview = d['wfr'] is int ? d['wfr'] as int : 0;
      isPro = d['pro'] is bool ? d['pro'] as bool : false;
    } catch (_) {
      // Corrupt profile: fall back to defaults rather than crashing.
    }
  }

  String _cleanName(Object? v) {
    final s = v is String ? v.trim() : '';
    if (s.isEmpty) return defaultName;
    return s.length > 20 ? s.substring(0, 20) : s;
  }

  /// One-time migration of the renameable profile into the order-preserving
  /// JSON names key. Sources, in order: an existing `colorfill_player_names_json`
  /// (authoritative — keep it), the legacy `cf_player_name` string, the old
  /// profile JSON's `name` field, then the default.
  void _migrateNames(SharedPreferences p) {
    List<String>? names;
    final raw = p.getString(_kNamesJson);
    if (raw != null) {
      try {
        final l = jsonDecode(raw);
        if (l is List && l.isNotEmpty && l.every((e) => e is String)) {
          names = [for (final e in l) _cleanName(e)];
        }
      } catch (_) {}
    }
    if (names == null) {
      final legacy = p.getString(_kLegacyName);
      if (legacy != null && legacy.trim().isNotEmpty) {
        names = [_cleanName(legacy)];
        p.remove(_kLegacyName);
      } else {
        // Seeded from the old profile layout (or the default).
        names = [playerName];
      }
      p.setString(_kNamesJson, jsonEncode(names));
    }
    playerNames = names;
  }

  /// Persist the names list as ONE order-preserving JSON string.
  Future<void> _saveNames() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kNamesJson, jsonEncode(playerNames));
  }

  /// One-time migration from the v1 key-per-value layout.
  void _migrateLegacy(SharedPreferences p) {
    var changed = false;
    final legacyUnlocked = p.getInt(_kLegacyUnlocked);
    if (legacyUnlocked != null) {
      unlocked = legacyUnlocked.clamp(1, 20);
      p.remove(_kLegacyUnlocked);
      changed = true;
    }
    for (int l = 1; l <= 20; l++) {
      final s = p.getInt('$_kLegacyStarsPrefix$l');
      if (s != null) {
        stars[l] = s.clamp(1, 3);
        p.remove('$_kLegacyStarsPrefix$l');
        changed = true;
      }
    }
    if (changed) _save();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    final data = {
      'v': 2,
      'name': playerName,
      'music': musicOn,
      'sfx': sfxOn,
      'volume': volume,
      'theme': themeId,
      'tile': tileStyle,
      'palette': customPalette,
      'bg': customBg,
      'diff': quickDifficulty,
      'unlocked': unlocked,
      'stars': {for (final e in stars.entries) '${e.key}': e.value},
      'games': games,
      'wins': wins,
      'streak': dailyStreak,
      'lastDaily': lastDaily,
      'wfr': winsForReview,
      'pro': isPro,
    };
    await p.setString(_kProfile, jsonEncode(data));
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || FillThemes.isProTheme(themeId)) {
      themeId = 'toybox';
      changed = true;
    }
    if (TileStyles.isPro(tileStyle)) {
      tileStyle = 0;
      changed = true;
    }
    if (quickDifficulty > 1) {
      quickDifficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String v) async {
    playerNames = [_cleanName(v)];
    notifyListeners();
    await _saveNames(); // authoritative order-preserving names JSON
    await _save(); // keep the legacy profile JSON consistent too
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || FillThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTileStyle(int v) async {
    v = v.clamp(0, TileStyles.names.length - 1);
    if (!isPro && TileStyles.isPro(v)) return;
    tileStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomPalette(List<int> colors) async {
    if (!isPro || colors.length != 6) return;
    customPalette = List.of(colors);
    notifyListeners();
    await _save();
  }

  Future<void> setCustomBg(int argb) async {
    if (!isPro) return;
    customBg = argb;
    notifyListeners();
    await _save();
  }

  Future<void> setQuickDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return; // hard is a Pro feature
    quickDifficulty = v;
    notifyListeners();
    await _save();
  }

  /// Record a finished level. Returns true when a review prompt is due.
  Future<bool> recordWin({
    required int level,
    required int starsEarned,
    required bool isDaily,
    required String dailyKey,
  }) async {
    games++;
    wins++;
    winsForReview++;
    if (level >= 1 && level <= 20) {
      final prev = stars[level] ?? 0;
      if (starsEarned > prev) stars[level] = starsEarned;
      if (level == unlocked && unlocked < 20) unlocked++;
    }
    if (isDaily) {
      final yesterday = _dateKey(DateTime.now().subtract(
        const Duration(days: 1),
      ));
      dailyStreak = (lastDaily == yesterday) ? dailyStreak + 1 : 1;
      lastDaily = dailyKey;
    }
    notifyListeners();
    await _save();
    // Ask for a review every ~6 wins; the screen decides the exact moment.
    return winsForReview >= 6;
  }

  Future<void> reviewPrompted() async {
    winsForReview = 0;
    await _save();
  }

  Future<void> recordLoss() async {
    games++;
    notifyListeners();
    await _save();
  }

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dateKey(DateTime d) => dateKey(d);

  int get totalStars => stars.values.fold(0, (a, b) => a + b);

  Future<void> resetProgress() async {
    unlocked = 1;
    stars = {};
    games = 0;
    wins = 0;
    dailyStreak = 0;
    lastDaily = '';
    winsForReview = 0;
    notifyListeners();
    await _save();
  }
}
