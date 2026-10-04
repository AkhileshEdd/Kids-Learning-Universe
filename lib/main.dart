import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/sound.dart';
import 'core/speech.dart';
import 'premium/google_play_backend.dart';
import 'premium/premium_service.dart';
import 'state/app_state.dart';

/// Build with `--dart-define=TEST_STORE=true` to simulate purchases on a
/// phone before the products exist in the Google Play Console.
const _testStore = bool.fromEnvironment('TEST_STORE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();
  final appState = AppState(prefs);
  await appState.load();

  // Google Play Billing on Android. The simulated store is used for web
  // previews and for builds made with --dart-define=TEST_STORE=true.
  final useGooglePlay = !kIsWeb && defaultTargetPlatform == TargetPlatform.android && !_testStore;
  final premium = PremiumService(useGooglePlay ? GooglePlayPurchaseBackend() : TestPurchaseBackend(prefs), prefs);
  unawaited(premium.init());

  final speech = SpeechService();
  final sound = SoundService();
  final s = appState.settings;
  unawaited(speech.init(enabled: s.voice, rate: s.speechRate, locale: s.voiceLocale));
  unawaited(sound.init(sfx: s.soundEffects, music: s.music));

  runApp(KidsLearningUniverseApp(appState: appState, premium: premium, speech: speech, sound: sound));
}
