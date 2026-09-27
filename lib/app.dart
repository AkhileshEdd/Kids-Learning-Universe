import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/music_route.dart';
import 'core/sound.dart';
import 'core/speech.dart';
import 'core/theme.dart';
import 'dev/preview.dart';
import 'premium/premium_service.dart';
import 'screens/break_time_screen.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

class KidsLearningUniverseApp extends StatefulWidget {
  const KidsLearningUniverseApp({
    super.key,
    required this.appState,
    required this.premium,
    required this.speech,
    required this.sound,
  });

  final AppState appState;
  final PremiumService premium;
  final SpeechService speech;
  final SoundService sound;

  @override
  State<KidsLearningUniverseApp> createState() => _KidsLearningUniverseAppState();
}

class _KidsLearningUniverseAppState extends State<KidsLearningUniverseApp> with WidgetsBindingObserver {
  Timer? _clock;
  bool _foreground = true;
  static const _tickSeconds = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Learning-time tracking for reports and the daily limit.
    _clock = Timer.periodic(const Duration(seconds: _tickSeconds), (_) {
      if (_foreground) widget.appState.addLearningSeconds(_tickSeconds);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    widget.sound.onAppLifecycle(foreground: _foreground);
    if (!_foreground) {
      widget.speech.stop();
      widget.appState.saveNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: widget.appState),
        ChangeNotifierProvider<PremiumService>.value(value: widget.premium),
        Provider<SpeechService>.value(value: widget.speech),
        Provider<SoundService>.value(value: widget.sound),
      ],
      child: MaterialApp(
        title: 'Kids Learning Universe',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        navigatorObservers: [routeObserver],
        home: kPreviewEnabled ? const PreviewLauncher() : const SplashScreen(),
        builder: (context, child) => MediaQuery(
          // Keep layouts predictable for little ones: ignore huge system fonts.
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.15),
          ),
          child: ScreenTimeGuard(child: child ?? const SizedBox()),
        ),
      ),
    );
  }
}
