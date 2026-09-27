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
import '../../widgets/common.dart';
import '../../widgets/confetti.dart';
import '../../widgets/game_scaffold.dart';
import '../activity_launcher.dart';

class _Card {
  _Card(this.pairId, this.text, {this.emoji = false, this.speech});
  final int pairId;
  final String text;
  final bool emoji;
  final String? speech;
  bool up = false;
  bool matched = false;
}

/// Flip cards to find matching pairs.
class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key, required this.activity, required this.grade});
  final ActivityDef activity;
  final Grade grade;

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends QuietState<MemoryScreen> {
  final _rng = Random();
  final _confetti = ConfettiController();
  late final List<_Card> _cards;
  late final int _pairs;
  final List<int> _open = [];
  int _misses = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _pairs = const [3, 4, 6, 8][widget.grade.index];
    _cards = _buildDeck()..shuffle(_rng);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SpeechService>().sayNow(widget.activity.intro);
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  List<_Card> _buildDeck() {
    final cards = <_Card>[];
    switch (widget.grade) {
      case Grade.preschool:
        final pics = _rng.sample(const ['🐶', '🐱', '🐻', '🐸', '🐵', '🦁', '🐷', '🐰', '🦊', '🐼'], _pairs);
        for (final (i, p) in pics.indexed) {
          cards.add(_Card(i, p, emoji: true));
          cards.add(_Card(i, p, emoji: true));
        }
      case Grade.kindergarten:
        final letters = _rng.sample(alphabet, _pairs);
        for (final (i, l) in letters.indexed) {
          cards.add(_Card(i, l.upper, speech: 'Big ${l.upper}'));
          cards.add(_Card(i, l.lower, speech: 'Little ${l.upper}'));
        }
      case Grade.grade1:
        final numbers = _rng.sample(List.generate(10, (i) => i + 1), _pairs);
        for (final (i, n) in numbers.indexed) {
          cards.add(_Card(i, '$n', speech: numberWord(n)));
          cards.add(_Card(i, numberWord(n), speech: numberWord(n)));
        }
      case Grade.grade2:
        final used = <int>{};
        var i = 0;
        while (i < _pairs) {
          final sum = _rng.range(6, 18);
          if (used.contains(sum)) continue;
          used.add(sum);
          final a = _rng.range(1, sum - 1);
          final minus = _rng.nextBool();
          final fact = minus ? '${sum + a} − $a' : '$a + ${sum - a}';
          cards.add(_Card(i, fact, speech: minus ? '${sum + a} minus $a' : '$a plus ${sum - a}'));
          cards.add(_Card(i, '$sum', speech: '$sum'));
          i++;
        }
    }
    return cards;
  }

  Future<void> _tap(int index) async {
    final card = _cards[index];
    if (_busy || card.up || card.matched) return;
    final sound = context.read<SoundService>();
    final speech = context.read<SpeechService>();
    sound.play(Sfx.flip);
    setState(() {
      card.up = true;
      _open.add(index);
    });
    if (card.speech != null) speech.sayNow(card.speech!);
    if (_open.length < 2) return;
    _busy = true;
    final a = _cards[_open[0]];
    final b = _cards[_open[1]];
    if (a.pairId == b.pairId) {
      await Future<void>.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      sound.play(Sfx.correct);
      setState(() {
        a.matched = true;
        b.matched = true;
        _open.clear();
      });
      _busy = false;
      if (_cards.every((c) => c.matched)) {
        _confetti.burst(count: 90);
        speech.sayNow('You found them all! ${speech.randomPraise()}');
        await Future<void>.delayed(const Duration(milliseconds: 1800));
        if (!mounted) return;
        sound.play(Sfx.win);
        final score = (_pairs - max(0, _misses - _pairs)).clamp(1, _pairs).toInt();
        finishActivity(
          context,
          activity: widget.activity,
          firstTryCorrect: score,
          total: _pairs,
          seconds: elapsedSeconds,
          grade: widget.grade,
        );
      } else {
        speech.sayNow('A match!');
      }
    } else {
      _misses++;
      await Future<void>.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;
      sound.play(Sfx.flip);
      setState(() {
        a.up = false;
        b.up = false;
        _open.clear();
      });
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.activity.subjectInfo.color;
    final matchedPairs = _cards.where((c) => c.matched).length ~/ 2;
    return GameScaffold(
      color: color,
      title: widget.activity.title,
      progress: matchedPairs,
      total: _pairs,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final columns = _cards.length ~/ 2;
              const rows = 2;
              const gap = 12.0;
              final w = (c.maxWidth - 40 - gap * (columns - 1)) / columns;
              final h = (c.maxHeight - 30 - gap * (rows - 1)) / rows;
              final cardW = min(w, h * 0.8);
              final cardH = min(h, cardW * 1.25);
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var r = 0; r < rows; r++)
                      Padding(
                        padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = r * columns; i < (r + 1) * columns; i++)
                              Padding(
                                padding: EdgeInsets.only(left: i % columns == 0 ? 0 : gap),
                                child: SizedBox(
                                  width: cardW,
                                  height: cardH,
                                  child: PopIn(
                                    delay: Duration(milliseconds: 40 * i),
                                    child: _FlipCard(card: _cards[i], color: color, onTap: () => _tap(i)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Positioned.fill(child: ConfettiLayer(controller: _confetti)),
        ],
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.card, required this.color, required this.onTap});
  final _Card card;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: card.up || card.matched ? 1 : 0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
        builder: (context, t, _) {
          final showFront = t > 0.5;
          final angle = t * pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(angle),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _front(),
                  )
                : _back(),
          );
        },
      ),
    );
  }

  Widget _back() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.lighten(0.1), color.darken(0.1)]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: const Center(child: EmojiText('⭐', size: 34)),
      );

  Widget _front() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: card.matched ? const Color(0xFFE3F9EC) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: card.matched ? AppColors.success : color.withValues(alpha: 0.4), width: 4),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Center(
          child: FittedBox(
            child: card.emoji
                ? EmojiText(card.text, size: 56)
                : Text(card.text, style: KidText.reading(card.text.length <= 2 ? 56 : 30)),
          ),
        ),
      );
}
