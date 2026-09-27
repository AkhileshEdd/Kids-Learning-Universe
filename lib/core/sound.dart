import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum Sfx { tap, pop, correct, wrong, star, win, flip, whoosh, sticker, page }

/// Sound effects and background music.
class SoundService {
  SoundService();

  final Map<Sfx, AudioPool> _pools = {};
  AudioPlayer? _music;
  bool sfxEnabled = true;
  bool _musicEnabled = true;
  bool _musicWanted = false;
  bool _appInForeground = true;

  static const _musicVolume = 0.16;

  Future<void> init({bool sfx = true, bool music = true}) async {
    sfxEnabled = sfx;
    _musicEnabled = music;
    try {
      // Mix with the narrator voice instead of stealing audio focus from it.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build(),
      );
    } catch (e) {
      debugPrint('Audio context not set: $e');
    }
    for (final s in Sfx.values) {
      try {
        _pools[s] = await AudioPool.createFromAsset(
          path: 'sfx/${s.name}.wav',
          maxPlayers: s == Sfx.pop || s == Sfx.tap ? 4 : 2,
          playerMode: kIsWeb ? PlayerMode.mediaPlayer : PlayerMode.lowLatency,
        );
      } catch (e) {
        debugPrint('Could not load sound ${s.name}: $e');
      }
    }
  }

  void play(Sfx sfx, {double volume = 1.0}) {
    if (!sfxEnabled) return;
    final pool = _pools[sfx];
    if (pool == null) return;
    unawaited(pool.start(volume: volume).then((_) {}, onError: (_) {}));
  }

  bool get musicEnabled => _musicEnabled;

  set musicEnabled(bool value) {
    _musicEnabled = value;
    _syncMusic();
  }

  /// Screens that want background music call this (home, maps).
  void wantMusic(bool wanted) {
    _musicWanted = wanted;
    _syncMusic();
  }

  void onAppLifecycle({required bool foreground}) {
    _appInForeground = foreground;
    _syncMusic();
  }

  Future<void> _syncMusic() async {
    final shouldPlay = _musicEnabled && _musicWanted && _appInForeground;
    try {
      if (shouldPlay) {
        if (_music == null) {
          final player = AudioPlayer(playerId: 'music');
          _music = player;
          await player.setReleaseMode(ReleaseMode.loop);
          await player.setVolume(_musicVolume);
          await player.play(AssetSource('music/space_lullaby.wav'), volume: _musicVolume);
        } else if (_music!.state != PlayerState.playing) {
          await _music!.resume();
        }
      } else if (_music != null && _music!.state == PlayerState.playing) {
        await _music!.pause();
      }
    } catch (e) {
      debugPrint('Music error: $e');
    }
  }
}
