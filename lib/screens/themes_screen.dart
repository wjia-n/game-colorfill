import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/artisan.dart';
import '../theme/fill_themes.dart';
import 'pro_screen.dart';

/// Themes + tile styles + the custom theme creator (Pro).
class ThemesScreen extends StatefulWidget {
  final FillAudio audio;
  final FillSettings settings;
  const ThemesScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  static const List<int> _swatches = [
    0xFFE5484D, 0xFFD63A3A, 0xFFC4452B, 0xFF8A2B2B,
    0xFFFF9F2E, 0xFFE8813A, 0xFFF08A35, 0xFF9C5A24,
    0xFFFFD60A, 0xFFF2C230, 0xFFFFD23F, 0xFFB8943F,
    0xFF30B158, 0xFF4E9B4E, 0xFF7FB069, 0xFF2E6B34,
    0xFF2E9BF0, 0xFF3A7BD5, 0xFF4D96D9, 0xFF274E7D,
    0xFF9B6BF3, 0xFF7E5AC9, 0xFFA179D4, 0xFF5E3F8A,
    0xFF2EC4B6, 0xFF4FB5AE, 0xFF45C4B0, 0xFF2A6E66,
    0xFFF26D9D, 0xFFD96C8A, 0xFFF0789F, 0xFF8A3A55,
    0xFF8A5A33, 0xFF5C3A21, 0xFFD9BE96, 0xFFF5EFE0,
  ];

  static const List<int> _bgSwatches = [
    0xFF4A3428, 0xFF3B2416, 0xFF2F5450, 0xFF44582C,
    0xFF63331A, 0xFF363B42, 0xFF5A4418, 0xFF434C5E,
    0xFF33431F, 0xFF5C3E24, 0xFF3B251B, 0xFF4C5E2E,
  ];

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
          title: Text('Themes & Tiles',
              style: Artisan.heading(20, theme: theme)),
        ),
        extendBodyBehindAppBar: true,
        body: TableBackdrop(
          theme: theme,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                Text('TABLE THEMES',
                    style: Artisan.label(12, theme: theme)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.35,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: FillThemes.all.length + 1, // + custom slot
                  itemBuilder: (_, i) => i < FillThemes.all.length
                      ? _themeCard(theme, FillThemes.all[i])
                      : _customCard(theme),
                ),
                const SizedBox(height: 24),
                Text('TILE STYLES',
                    style: Artisan.label(12, theme: theme)),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: TileStyles.names.length,
                  itemBuilder: (_, i) => _styleCard(theme, i),
                ),
                if (s.isPro) ...[
                  const SizedBox(height: 24),
                  Text('CUSTOM CREATOR',
                      style: Artisan.label(12, theme: theme)),
                  const SizedBox(height: 6),
                  Text(
                    'Design your own 6-color palette and table.',
                    style: Artisan.body(13, theme: theme),
                  ),
                  const SizedBox(height: 12),
                  _customCreator(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeCard(FillThemeDef theme, FillThemeDef t) {
    final s = widget.settings;
    final locked = t.pro && !s.isPro;
    final selected = s.themeId == t.id;
    return GestureDetector(
      onTap: () {
        if (locked) {
          widget.audio.invalid();
          _goPro();
          return;
        }
        widget.audio.click();
        s.setTheme(t.id);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [t.tableMid, t.tableDark],
          ),
          border: Border.all(
            color: selected
                ? theme.accent
                : Colors.black.withValues(alpha: 0.4),
            width: selected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: t.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (locked)
                  const Text('🔒', style: TextStyle(fontSize: 13)),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                for (int i = 0; i < 6; i++)
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: t.palette[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.black.withValues(alpha: 0.35)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _customCard(FillThemeDef theme) {
    final s = widget.settings;
    final selected = s.themeId == 'custom';
    return GestureDetector(
      onTap: () {
        if (!s.isPro) {
          widget.audio.invalid();
          _goPro();
          return;
        }
        widget.audio.click();
        s.setTheme('custom');
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected
                ? theme.accent
                : theme.accent.withValues(alpha: 0.4),
            width: selected ? 3 : 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🖌️', style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text('My Creation',
                style: Artisan.body(13, theme: theme)),
            if (!s.isPro) ProBadge(theme: theme),
          ],
        ),
      ),
    );
  }

  Widget _styleCard(FillThemeDef theme, int i) {
    final s = widget.settings;
    final locked = TileStyles.isPro(i) && !s.isPro;
    final selected = s.tileStyle == i;
    return GestureDetector(
      onTap: () {
        if (locked) {
          widget.audio.invalid();
          _goPro();
          return;
        }
        widget.audio.click();
        s.setTileStyle(i);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.black.withValues(alpha: 0.3),
          border: Border.all(
            color: selected
                ? theme.accent
                : Colors.black.withValues(alpha: 0.35),
            width: selected ? 2.5 : 1.5,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stylePreview(theme, i),
            const SizedBox(height: 6),
            Text(
              TileStyles.names[i],
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (locked)
              const Text('🔒', style: TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _stylePreview(FillThemeDef theme, int i) {
    final c = theme.palette[i % theme.palette.length];
    final shape = switch (i) {
      1 => BoxShape.circle,
      _ => BoxShape.rectangle,
    };
    final radius = switch (i) {
      1 => null,
      2 => BorderRadius.circular(4.0),
      6 => BorderRadius.circular(3.0),
      7 => BorderRadius.circular(14.0),
      _ => BorderRadius.circular(8.0),
    };
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(c, Colors.white, 0.18)!,
            c,
            Color.lerp(c, Colors.black, 0.2)!,
          ],
        ),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 3),
            blurRadius: 5,
          ),
        ],
      ),
    );
  }

  Widget _customCreator(FillThemeDef theme) {
    final s = widget.settings;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(
            color: theme.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Palette (6 colors)',
              style: Artisan.body(14, theme: theme)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < 6; i++)
                GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    _pickSwatch(theme, i);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(s.customPalette[i]),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          offset: const Offset(0, 3),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Table color',
              style: Artisan.body(14, theme: theme)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final bg in _bgSwatches)
                GestureDetector(
                  onTap: () {
                    widget.audio.click();
                    s.setCustomBg(bg);
                  },
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Color(bg),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: s.customBg == bg
                            ? theme.accent
                            : Colors.black.withValues(alpha: 0.4),
                        width: s.customBg == bg ? 3 : 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: FillButton(
              label: 'Use my creation',
              emoji: '✨',
              small: true,
              onTap: () {
                widget.audio.click();
                s.setTheme('custom');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Your theme is live!')),
                );
              },
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  void _pickSwatch(FillThemeDef theme, int slot) {
    final s = widget.settings;
    showDialog(
      context: context,
      builder: (ctx) => FillDialog(
        title: 'Pick color ${slot + 1}',
        emoji: '🎨',
        theme: theme,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final c in _swatches)
                GestureDetector(
                  onTap: () {
                    final pal = List.of(s.customPalette);
                    pal[slot] = c;
                    s.setCustomPalette(pal);
                    widget.audio.click();
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: s.customPalette[slot] == c
                            ? theme.accent
                            : Colors.black.withValues(alpha: 0.35),
                        width: s.customPalette[slot] == c ? 3 : 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _goPro() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProScreen(audio: widget.audio, settings: widget.settings),
      ),
    );
  }
}
