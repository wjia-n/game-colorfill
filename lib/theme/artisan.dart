import 'package:flutter/material.dart';
import 'fill_themes.dart';

/// Shared physical-material widgets for Color Fill: wooden buttons, felt
/// table backdrops, paper dialogs. Kept deliberately small and self-contained.
class Artisan {
  static TextStyle display(double size, {required FillThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: theme.text,
        letterSpacing: 1.2,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      );

  static TextStyle heading(double size, {required FillThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: theme.text,
        letterSpacing: 0.6,
      );

  static TextStyle body(double size,
          {required FillThemeDef theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: color ?? theme.textSoft,
        height: 1.35,
      );

  static TextStyle label(double size, {required FillThemeDef theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: theme.textSoft,
        letterSpacing: 1.6,
      );
}

/// Warm felt-table backdrop with vignette.
class TableBackdrop extends StatelessWidget {
  final FillThemeDef theme;
  final Widget child;
  const TableBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.35),
          radius: 1.25,
          colors: [theme.tableMid, theme.tableDark],
          stops: const [0.0, 1.0],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.35),
            ],
            stops: const [0.55, 1.0],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Chunky wooden button with bevel + shadow.
class FillButton extends StatelessWidget {
  final String label;
  final String? emoji;
  final bool primary;
  final bool small;
  final VoidCallback? onTap;
  final FillThemeDef theme;

  const FillButton({
    super.key,
    required this.label,
    this.emoji,
    this.primary = true,
    this.small = false,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? theme.accent : theme.trayLight;
    final fg = primary ? theme.tableDark : theme.text;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 14 : 22,
            vertical: small ? 9 : 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(small ? 12 : 16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg.withValues(alpha: 1.0), _darken(bg, 0.82)],
            ),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.22),
                offset: const Offset(0, 1.5),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null) ...[
                Text(emoji!, style: TextStyle(fontSize: small ? 15 : 19)),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: small ? 14 : 17,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _darken(Color c, double f) => Color.fromARGB(
        c.alpha,
        (c.red * f).round(),
        (c.green * f).round(),
        (c.blue * f).round(),
      );
}

/// Round wooden icon button.
class FillIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final FillThemeDef theme;
  final double size;
  final String? badge;

  const FillIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.theme,
    this.size = 46,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1.0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.trayLight, theme.trayDark],
                ),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(icon, color: theme.text, size: size * 0.48),
            ),
            if (badge != null)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.accent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: theme.tableDark,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Paper dialog card.
class FillDialog extends StatelessWidget {
  final String title;
  final String? emoji;
  final List<Widget> children;
  final FillThemeDef theme;

  const FillDialog({
    super.key,
    required this.title,
    this.emoji,
    required this.children,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
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
              color: Colors.black.withValues(alpha: 0.6),
              offset: const Offset(0, 12),
              blurRadius: 28,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (emoji != null) ...[
                    Text(emoji!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: Artisan.heading(20, theme: theme),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "PRO" lock badge.
class ProBadge extends StatelessWidget {
  final FillThemeDef theme;
  const ProBadge({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.accent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.3)),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: theme.tableDark,
        ),
      ),
    );
  }
}

/// Star row (earned / total).
class StarsRow extends StatelessWidget {
  final int earned;
  final int total;
  final double size;
  final FillThemeDef theme;
  const StarsRow({
    super.key,
    required this.earned,
    this.total = 3,
    this.size = 22,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              i < earned ? Icons.star : Icons.star_border,
              color: i < earned
                  ? theme.accent
                  : theme.textSoft.withValues(alpha: 0.5),
              size: size,
            ),
          ),
      ],
    );
  }
}
