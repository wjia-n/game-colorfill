import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan.dart';
import '../theme/fill_themes.dart';

/// Settings: renameable player profile, music/SFX toggles + volume,
/// progress reset, credits.
class SettingsScreen extends StatefulWidget {
  final FillAudio audio;
  final FillSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final FocusNode _nameFocus;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.settings.playerName);
    _nameFocus = FocusNode();
    // Save on EVERY keystroke (never keyboard-done only)…
    _name.addListener(_onNameTyped);
    // …and commit on focus loss.
    _nameFocus.addListener(_onNameFocus);
  }

  @override
  void dispose() {
    _name.removeListener(_onNameTyped);
    _nameFocus.removeListener(_onNameFocus);
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onNameTyped() {
    // Fire-and-forget: the settings service serializes writes; the latest
    // keystroke always wins. Stored as ONE order-preserving JSON string.
    widget.settings.setPlayerName(_name.text);
  }

  void _onNameFocus() {
    if (_nameFocus.hasFocus) return;
    // Commit the final value when the field loses focus.
    widget.settings.setPlayerName(_name.text);
    // If the stored name was cleaned (e.g. empty → "Player"), show it.
    final stored = widget.settings.playerName;
    if (_name.text != stored) _name.text = stored;
  }

  FillThemeDef get _theme => FillThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final s = widget.settings;
    return ListenableBuilder(
      listenable: s,
      builder: (_, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: theme.text),
          title: Text('Settings',
              style: Artisan.heading(20, theme: theme)),
        ),
        extendBodyBehindAppBar: true,
        body: TableBackdrop(
          theme: theme,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Text('PLAYER', style: Artisan.label(12, theme: theme)),
                const SizedBox(height: 8),
                TextField(
                  controller: _name,
                  focusNode: _nameFocus,
                  maxLength: 20,
                  style: TextStyle(
                      color: theme.text,
                      fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Your name',
                    hintStyle:
                        TextStyle(color: theme.textSoft),
                    helperText: 'Saved automatically as you type ✏️',
                    helperStyle: TextStyle(
                        color: theme.textSoft, fontSize: 11),
                    filled: true,
                    fillColor:
                        Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: theme.accent
                              .withValues(alpha: 0.5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: theme.accent
                              .withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('AUDIO', style: Artisan.label(12, theme: theme)),
                const SizedBox(height: 8),
                _toggleRow(
                  theme,
                  'Music',
                  '🎵',
                  s.musicOn,
                  (v) {
                    s.setMusic(v);
                    widget.audio.configure(
                      musicOn: v,
                      sfxOn: s.sfxOn,
                      volume: s.volume,
                    );
                    if (v) widget.audio.startMenuMusic();
                    widget.audio.click();
                  },
                ),
                _toggleRow(
                  theme,
                  'Sound effects',
                  '🔔',
                  s.sfxOn,
                  (v) {
                    s.setSfx(v);
                    widget.audio.configure(
                      musicOn: s.musicOn,
                      sfxOn: v,
                      volume: s.volume,
                    );
                    widget.audio.click();
                  },
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('🔊', style: TextStyle(fontSize: 20)),
                    Expanded(
                      child: Slider(
                        value: s.volume,
                        activeColor: theme.accent,
                        inactiveColor: theme.textSoft
                            .withValues(alpha: 0.3),
                        onChanged: (v) {
                          s.setVolume(v);
                          widget.audio.configure(
                            musicOn: s.musicOn,
                            sfxOn: s.sfxOn,
                            volume: v,
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('PROGRESS', style: Artisan.label(12, theme: theme)),
                const SizedBox(height: 8),
                _statRow(theme, '🏆', 'Levels unlocked', '${s.unlocked} / 20'),
                _statRow(theme, '⭐', 'Stars collected', '${s.totalStars}'),
                _statRow(theme, '🎮', 'Games played', '${s.games}'),
                _statRow(theme, '🔥', 'Daily streak', '${s.dailyStreak}'),
                const SizedBox(height: 16),
                FillButton(
                  label: 'Reset all progress',
                  emoji: '🗑️',
                  primary: false,
                  onTap: () => _confirmReset(theme),
                  theme: theme,
                ),
                const SizedBox(height: 32),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/wajiha_logo.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Artisan.label(11, theme: theme)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleRow(FillThemeDef theme, String label, String emoji,
      bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: Artisan.body(15, theme: theme)),
          ),
          Switch(
            value: value,
            activeThumbColor: theme.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _statRow(
      FillThemeDef theme, String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: Artisan.body(14, theme: theme))),
          Text(value,
              style: Artisan.heading(14, theme: theme)),
        ],
      ),
    );
  }

  void _confirmReset(FillThemeDef theme) {
    widget.audio.click();
    showDialog(
      context: context,
      builder: (ctx) => FillDialog(
        title: 'Reset everything?',
        emoji: '⚠️',
        theme: theme,
        children: [
          Text(
            'This wipes your unlocked levels, stars, streak and stats. Your name and settings stay.',
            style: Artisan.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FillButton(
                label: 'Cancel',
                small: true,
                primary: false,
                onTap: () {
                  widget.audio.click();
                  Navigator.pop(ctx);
                },
                theme: theme,
              ),
              const SizedBox(width: 12),
              FillButton(
                label: 'Reset',
                small: true,
                onTap: () {
                  widget.audio.click();
                  widget.settings.resetProgress();
                  Navigator.pop(ctx);
                },
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
