import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/settings_service.dart';
import 'theme/fill_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = FillSettings();
  await settings.load();
  final audio = FillAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  runApp(ColorFillApp(settings: settings, audio: audio));
}

class ColorFillApp extends StatefulWidget {
  final FillSettings settings;
  final FillAudio audio;
  const ColorFillApp({super.key, required this.settings, required this.audio});

  @override
  State<ColorFillApp> createState() => _ColorFillAppState();
}

class _ColorFillAppState extends State<ColorFillApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) {
        final theme = FillThemes.byId(
          widget.settings.themeId,
          custom: widget.settings.customTheme,
        );
        return MaterialApp(
          title: 'Color Fill',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: theme.tableDark,
            colorScheme: ColorScheme.dark(
              primary: theme.accent,
              surface: theme.trayDark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: Colors.transparent,
            ),
          ),
          home: SplashScreen(
              audio: widget.audio, settings: widget.settings),
        );
      },
    );
  }
}
