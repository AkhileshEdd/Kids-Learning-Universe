import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../content/activities.dart';
import '../../content/word_bank.dart';
import '../../core/sound.dart';
import '../../core/speech.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/grade.dart';
import '../../state/app_state.dart';
import '../../widgets/bubbly_button.dart';
import '../../widgets/common.dart';
import '../../widgets/confetti.dart';
import '../../widgets/critter.dart';
import '../../widgets/game_scaffold.dart';
import '../activity_launcher.dart';

const _tileColors = [
  Color(0xFFFF5A5F), Color(0xFFFF9F1C), Color(0xFF3CCB7F), Color(0xFF3FA9F5),
  Color(0xFF8E6CF1), Color(0xFFFF5FA2), Color(0xFF2EC4B6),
];

class _Tile {
  _Tile(this.id, this.letter);
  final int id;
  final String letter;
}

/// Spell the pictured word by tapping letter tiles in order.
class WordBuilderScreen extends StatefulWidget {
  const WordBuilderScreen({super.key, required this.activity, required this.grade});
  final ActivityDef activity;
  final Grade grade;

  @override
  State<WordBuilderScreen> createState() => _WordBuilderScreenState();
}

class _WordBuilderScreenState extends QuietState<WordBuilderScreen> {
  final _rng = Random();
  final _confetti = ConfettiController();
  final _talk = TalkingController();
  late final int _rounds = min(widget.grade.rounds, 6);
  late final int _level = context.read<AppState>().levelFor(widget.activity.skillKey);
  late final List<PicWord> _words;
  int _round = 0;
  int _firstTryCorrect = 0;
  bool _firstTry = true;
  bool _solved = false;
  int _shake = 0;
  late List<_Tile> _bank;
  late List<_Tile?> _slots;

  PicWord get _word => _words[_round];

  bool get _hints => widget.grade == Grade.kindergarten && _level == 0;

  @override
  void initState() {
    super.initState();
    final pool = switch (widget.grade) {
      Grade.preschool || Grade.kindergarten => cvcWords,
      Grade.grade1 => _level == 0 ? cvcWords : shortWords,
      Grade.grade2 => _level == 0 ? shortWords : longWords,
    };
    _words = _rng.sample(pool.where((w) => RegExp(r'^[a-z]+$').hasMatch(w.word)).toList(), _rounds);
    _setup();
    WidgetsBinding.instance.addPostFrameCallback((_) => _say(intro: true));
  }

  @override
  void dispose() {
    _confetti.dispose();
    _talk.dispose();
    super.dispose();
  }

  void _setup() {
    final letters = _word.word.split('');
    final extras = switch (widget.grade) {
      Grade.preschool || Grade.kindergarten => _level,
      Grade.grade1 => 1 + _level,
      Grade.grade2 => 2 + _level,
    };
    final bank = [...letters];
    const pool = 'abcdefghijklmnopqrstuvwxyz';
    while (bank.length < letters.length + extras) {
      final c = pool[_rng.nextInt(pool.length)];
      if (!letters.contains(c)) bank.add(c);
    }
    bank.shuffle(_rng);
    _bank = [for (final (i, c) in bank.indexed) _Tile(i, c)];
    _slots = List.filled(letters.length, null);
    _firstTry = true;
    _solved = false;
  }

  void _say({bool intro = false}) {
    if (!mounted) return;
    final line = '${intro ? '${widget.activity.intro} ' : ''}Spell ${_word.word}. ${_word.word}.';
    _talk.talkFor(line);
    context.read<SpeechService>().sayNow(line);
  }

  void _place(_Tile t) {
    if (_solved) return;
    final slot = _slots.indexOf(null);
    if (slot < 0) return;
    context.read<SoundService>().play(Sfx.tap);
    context.read<SpeechService>().sayNow(t.letter.toUpperCase());
    setState(() {
      _slots[slot] = t;
      _bank.remove(t);
    });
    if (!_slots.contains(null)) _check();
  }

  void _unplace(int slot) {
    final t = _slots[slot];
    if (t == null || _solved) return;
    context.read<SoundService>().play(Sfx.tap);
    setState(() {
      _slots[slot] = null;
      _bank.add(t);
    });
  }

  Future<void> _check() async {
    final guess = _slots.map((t) => t!.letter).join();
    final speech = context.read<SpeechService>();
    final sound = context.read<SoundService>();
    if (guess == _word.word) {
      setState(() {
        _solved = true;
        if (_firstTry) _firstTryCorrect++;
      });
      sound.play(Sfx.correct);
      _confetti.burst(origin: const Offset(0.55, 0.35), count: 60);
      final line = '${_word.word.split('').map((c) => c.toUpperCase()).join(', ')}. ${_word.word}! ${speech.randomPraise()}';
      _talk.talkFor(line);
      await speech.say(line).timeout(const Duration(seconds: 7), onTimeout: () {});
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      if (_round + 1 >= _rounds) {
        sound.play(Sfx.win);
        finishActivity(
          context,
          activity: widget.activity,
          firstTryCorrect: _firstTryCorrect,
          total: _rounds,
          seconds: elapsedSeconds,
          grade: widget.grade,
        );
        return;
      }
      setState(() {
        _round++;
        _setup();
      });
      _say();
    } else {
      sound.play(Sfx.wrong);
      _firstTry = false;
      setState(() => _shake++);
      final line = speech.randomTryAgain();
      _talk.talkFor(line);
      speech.sayNow(line);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      // Send back the letters that are in the wrong place.
      setState(() {
        for (var i = 0; i < _slots.length; i++) {
          final t = _slots[i];
          if (t != null && t.letter != _word.word[i]) {
            _slots[i] = null;
            _bank.add(t);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.activity.subjectInfo.color;
    return GameScaffold(
      color: color,
      title: widget.activity.title,
      progress: _round + (_solved ? 1 : 0),
      total: _rounds,
      stars: _firstTryCorrect,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final slotSize = min(78.0, (c.maxWidth * 0.55) / max(_slots.length, 4) - 10);
              return Row(
                children: [
                  SizedBox(
                    width: c.maxWidth * 0.3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _say,
                          child: PopIn(
                            key: ValueKey(_round),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 5))],
                              ),
                              child: EmojiText(_word.emoji, size: min(110, c.maxHeight * 0.34)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        RoundButton(
                          icon: Icons.volume_up_rounded,
                          color: color,
                          iconColor: Colors.white,
                          onTap: _say,
                          semanticLabel: 'Hear the word',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Shake(
                          trigger: _shake,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < _slots.length; i++)
                                GestureDetector(
                                  onTap: () => _unplace(i),
                                  child: Container(
                                    width: slotSize,
                                    height: slotSize * 1.15,
                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _slots[i] != null ? (_solved ? const Color(0xFFE3F9EC) : Colors.white) : Colors.white.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _solved ? AppColors.success : color.withValues(alpha: _slots[i] != null ? 0.8 : 0.4),
                                        width: 3,
                                      ),
                                    ),
                                    child: _slots[i] != null
                                        ? PopIn(child: Text(_slots[i]!.letter, style: KidText.reading(slotSize * 0.62)))
                                        : (_hints
                                            ? Text(_word.word[i], style: KidText.reading(slotSize * 0.62, color: const Color(0xFFD9D4EA)))
                                            : null),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final t in _bank)
                              BubblyButton(
                                key: ValueKey(t.id),
                                onTap: () => _place(t),
                                color: _tileColors[t.letter.codeUnitAt(0) % _tileColors.length],
                                width: slotSize,
                                height: slotSize,
                                radius: 18,
                                padding: EdgeInsets.zero,
                                sound: null,
                                semanticLabel: t.letter,
                                child: Text(t.letter, style: KidText.reading(slotSize * 0.58, color: Colors.white)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned.fill(child: ConfettiLayer(controller: _confetti)),
        ],
      ),
    );
  }
}
