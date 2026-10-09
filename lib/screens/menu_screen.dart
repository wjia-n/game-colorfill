import 'package:flutter/material.dart';
import '../engine/colorfill_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../services/share_kit.dart';
import '../theme/artisan.dart';
import '../theme/fill_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'themes_screen.dart';

/// Main menu: campaign, daily challenge, quick play, themes, rules,
/// settings, Pro.
class MenuScreen extends StatelessWidget {
  final FillAudio audio;
  final FillSettings settings;
  const MenuScreen({super.key, required this.audio, required this.settings});

  FillThemeDef get _theme =>
      FillThemes.byId(settings.themeId, custom: settings.customTheme);

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final todayKey = FillSettings.dateKey(DateTime.now());
    final dailyDone = settings.lastDaily == todayKey;
    return Scaffold(
      body: TableBackdrop(
        theme: theme,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: theme.accent, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/colorfill_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text('Color Fill', style: Artisan.display(44, theme: theme)),
                  const SizedBox(height: 4),
                  Text(
                    'FLOOD THE WHOLE BOARD',
                    style: Artisan.label(12, theme: theme),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hey, ${settings.playerName}! ${settings.totalStars}⭐ collected',
                    style: Artisan.body(14, theme: theme),
                  ),
                  const SizedBox(height: 22),
                  FillButton(
                    label: 'Play — Level ${settings.unlocked}',
                    emoji: '🎨',
                    onTap: () {
                      audio.click();
                      final diff = MenuScreen.campaignDifficulty(
                          settings.unlocked);
                      if (diff == FillDifficulty.hard &&
                          !settings.isPro) {
                        // Hard campaign boards are a Pro feature.
                        audio.invalid();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProScreen(
                                audio: audio, settings: settings),
                          ),
                        );
                        return;
                      }
                      _openGame(
                        context,
                        mode: FillMode.campaign,
                        level: settings.unlocked,
                        difficulty: diff,
                        title: 'Level ${settings.unlocked}',
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  FillButton(
                    label: dailyDone
                        ? 'Daily done — streak ${settings.dailyStreak}🔥'
                        : 'Daily Challenge 🔥${settings.dailyStreak}',
                    emoji: '📅',
                    primary: false,
                    onTap: () {
                      audio.click();
                      final now = DateTime.now();
                      _openGame(
                        context,
                        mode: FillMode.daily,
                        difficulty: FillDifficulty.medium,
                        title: 'Daily Challenge',
                        seed: now.year * 10000 + now.month * 100 + now.day,
                      );
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  FillButton(
                    label: 'Quick Play',
                    emoji: '⚡',
                    primary: false,
                    onTap: () {
                      audio.click();
                      _quickPlaySheet(context);
                    },
                    theme: theme,
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FillButton(
                        label: 'Themes',
                        emoji: '🖌️',
                        small: true,
                        primary: false,
                        onTap: () {
                          audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ThemesScreen(
                                  audio: audio, settings: settings),
                            ),
                          );
                        },
                        theme: theme,
                      ),
                      FillButton(
                        label: 'How to Play',
                        emoji: '❓',
                        small: true,
                        primary: false,
                        onTap: () {
                          audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RulesScreen(
                                  audio: audio,
                                  settings: settings,
                                  theme: theme),
                            ),
                          );
                        },
                        theme: theme,
                      ),
                      FillButton(
                        label: 'Settings',
                        emoji: '⚙️',
                        small: true,
                        primary: false,
                        onTap: () {
                          audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                  audio: audio, settings: settings),
                            ),
                          );
                        },
                        theme: theme,
                      ),
                      FillButton(
                        label: settings.isPro ? 'PRO ⭐' : 'Go Pro',
                        emoji: '💎',
                        small: true,
                        primary: false,
                        onTap: () {
                          audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProScreen(audio: audio, settings: settings),
                            ),
                          );
                        },
                        theme: theme,
                      ),
                      FillButton(
                        label: 'Share',
                        emoji: '📣',
                        small: true,
                        primary: false,
                        onTap: () {
                          audio.click();
                          ShareKit.shareApp();
                        },
                        theme: theme,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/wajiha_logo.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Credits: WAJIHA',
                        style: Artisan.label(11, theme: theme),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static FillDifficulty campaignDifficulty(int level) {
    if (level <= 6) return FillDifficulty.easy;
    if (level <= 13) return FillDifficulty.medium;
    return FillDifficulty.hard;
  }

  void _openGame(
    BuildContext context, {
    required FillMode mode,
    required FillDifficulty difficulty,
    required String title,
    int level = 0,
    int? seed,
  }) {
    audio.startGameMusic();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: audio,
          settings: settings,
          mode: mode,
          difficulty: difficulty,
          level: level,
          title: title,
          seed: seed,
        ),
      ),
    );
  }

  void _quickPlaySheet(BuildContext context) {
    final theme = _theme;
    int diff = settings.quickDifficulty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: BoxDecoration(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.trayLight, theme.trayDark],
            ),
            border: Border.all(
                color: Colors.black.withValues(alpha: 0.4), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Quick Play',
                  style: Artisan.heading(20, theme: theme)),
              const SizedBox(height: 6),
              Text('Pick a difficulty, get a fresh board.',
                  style: Artisan.body(13, theme: theme)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: _diffChip(
                        ctx,
                        setSheet,
                        i,
                        diff,
                        theme,
                        onPick: (v) => diff = v,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FillButton(
                label: 'Deal me in!',
                emoji: '🎲',
                onTap: () {
                  audio.click();
                  settings.setQuickDifficulty(diff);
                  Navigator.pop(ctx);
                  final d = difficultyFromIndex(diff);
                  _openGame(
                    context,
                    mode: FillMode.quick,
                    difficulty: d,
                    title:
                        'Quick — ${['Easy', 'Medium', 'Hard'][diff]}',
                  );
                },
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _diffChip(BuildContext ctx, StateSetter setSheet, int i, int diff,
      FillThemeDef theme,
      {required void Function(int) onPick}) {
    final names = ['Easy', 'Medium', 'Hard'];
    final locked = i == 2 && !settings.isPro;
    final selected = diff == i;
    return GestureDetector(
      onTap: locked
          ? () {
              audio.invalid();
              Navigator.pop(ctx);
              Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ProScreen(audio: audio, settings: settings),
                ),
              );
            }
          : () {
              audio.click();
              setSheet(() => onPick(i));
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.accent : theme.tableDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.black.withValues(alpha: 0.4)
                : theme.accent.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              names[i],
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: selected ? theme.tableDark : theme.text,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 4),
              const Text('🔒', style: TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}
