import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/sound.dart';
import 'core/speech.dart';
import 'premium/premium_service.dart';
import 'state/app_state.dart';

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

  // Swap TestPurchaseBackend for a Google Play Billing backend to go live.
  final premium = PremiumService(TestPurchaseBackend(prefs), prefs);
  await premium.init();

  final speech = SpeechService();
  final sound = SoundService();
  final s = appState.settings;
  unawaited(speech.init(enabled: s.voice, rate: s.speechRate, locale: s.voiceLocale));
  unawaited(sound.init(sfx: s.soundEffects, music: s.music));

  runApp(KidsLearningUniverseApp(appState: appState, premium: premium, speech: speech, sound: sound));
}
