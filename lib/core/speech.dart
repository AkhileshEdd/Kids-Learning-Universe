import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Word-progress callback: (text, startOffset, endOffset).
typedef SpeechProgress = void Function(String text, int start, int end);

/// Text-to-speech narrator. Every instruction in the app is spoken aloud so
/// that children who cannot read yet can play on their own.
class SpeechService {
  SpeechService();

  final FlutterTts _tts = FlutterTts();
  final _random = Random();
  bool _ready = false;
  bool enabled = true;
  double _rate = 0.42;
  String _language = 'en-US';
  SpeechProgress? _progress;
  VoidCallback? _completion;

  /// Locale used for English narration (the accent is a parent setting).
  String englishLocale = 'en-US';
  static const spanish = 'es-ES';

  Future<void> init({bool enabled = true, double rate = 0.42, String locale = 'en-US'}) async {
    this.enabled = enabled;
    _rate = rate;
    englishLocale = locale;
    _language = locale;
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(1.12);
      await _tts.setVolume(1.0);
      _tts.setProgressHandler((text, start, end, word) => _progress?.call(text, start, end));
      _tts.setCompletionHandler(() => _completion?.call());
      _tts.setCancelHandler(() => _completion?.call());
      _ready = true;
    } catch (e) {
      debugPrint('TTS unavailable: $e');
    }
  }

  Future<void> setRate(double rate) async {
    _rate = rate;
    if (_ready) {
      try {
        await _tts.setSpeechRate(rate);
      } catch (_) {}
    }
  }

  Future<void> _useLanguage(String language) async {
    if (language == _language) return;
    _language = language;
    try {
      if (language.startsWith('es')) {
        // Prefer any Spanish voice the device has.
        for (final candidate in const ['es-ES', 'es-MX', 'es-US']) {
          final ok = await _tts.isLanguageAvailable(candidate);
          if (ok == true || ok == 1) {
            await _tts.setLanguage(candidate);
            return;
          }
        }
      } else {
        final ok = await _tts.isLanguageAvailable(language);
        if (ok != true && ok != 1) {
          await _tts.setLanguage('en-US');
          return;
        }
      }
      await _tts.setLanguage(language);
    } catch (_) {}
  }

  /// Speaks [text]. Returns when the utterance finishes (or immediately if
  /// speech is off). Any speech already playing is interrupted.
  Future<void> say(String text, {String? language, SpeechProgress? onProgress}) async {
    if (!enabled || !_ready || text.trim().isEmpty) return;
    try {
      _progress = onProgress;
      await _tts.stop();
      await _useLanguage(language ?? englishLocale);
      // Some engines never report completion after an error; don't wait forever.
      await _tts.speak(text).timeout(
        Duration(milliseconds: 3000 + text.length * 120),
        onTimeout: () => null,
      );
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  /// Like [say] but doesn't make the caller wait.
  void sayNow(String text, {String? language}) {
    unawaited(say(text, language: language));
  }

  Future<void> stop() async {
    _progress = null;
    if (!_ready) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static const _praise = [
    'Great job!',
    'Awesome!',
    'You did it!',
    'Super!',
    'Fantastic!',
    'Way to go!',
    'Wow, amazing!',
    'Yes! Well done!',
    'You are a star!',
    'Brilliant!',
    'Hooray!',
    'Perfect!',
  ];

  static const _tryAgain = [
    'Try again!',
    'Almost! Try again.',
    'Oops! Try another one.',
    'Not quite. You can do it!',
    'Hmm, try again!',
  ];

  String randomPraise() => _praise[_random.nextInt(_praise.length)];
  String randomTryAgain() => _tryAgain[_random.nextInt(_tryAgain.length)];

  void praise() => sayNow(randomPraise());
  void encourage() => sayNow(randomTryAgain());
}
