import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/activities.dart';
import '../content/quiz.dart';
import '../core/sound.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../models/grade.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/critter.dart';
import '../widgets/game_scaffold.dart';
import 'activity_launcher.dart';

/// Plays any multiple-choice activity: narrated prompt, big answer cards,
/// friendly feedback and adaptive difficulty.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.activity, required this.grade});

  final ActivityDef activity;
  final Grade grade;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends QuietState<QuizScreen> {
  final _rng = Random();
  final _confetti = ConfettiController();
  final _talk = TalkingController();
  final _seen = <String>{};
  late final int _rounds = widget.grade.rounds;
  late final int _level;

  late QuizQuestion _q;
  int _round = 0;
  int _firstTryCorrect = 0;
  bool _firstTry = true;
  bool _solved = false;
  final Set<int> _wrong = {};
  final Map<int, int> _shakes = {};
  final _choiceKeys = <int, GlobalKey>{};
  CritterMood _mood = CritterMood.idle;

  SpeechService get _speech => context.read<SpeechService>();
  SoundService get _sound => context.read<SoundService>();

  @override
  void initState() {
    super.initState();
    _level = context.read<AppState>().levelFor(widget.activity.skillKey);
    _q = _generate();
    WidgetsBinding.instance.addPostFrameCallback((_) => _introduce());
  }

  @override
  void dispose() {
    _confetti.dispose();
    _talk.dispose();
    super.dispose();
  }

  QuizQuestion _generate() {
    final ctx = GenContext(grade: widget.grade, level: _level, rng: _rng);
    QuizQuestion q = widget.activity.generator!(ctx);
    for (var i = 0; i < 12 && _seen.contains(q.key); i++) {
      q = widget.activity.generator!(ctx);
    }
    _seen.add(q.key);
    return q;
  }

  Future<void> _introduce() async {
    if (!mounted) return;
    _talk.talkFor(widget.activity.intro);
    await _speech.say(widget.activity.intro);
    if (!mounted) return;
    _askQuestion();
  }

  void _askQuestion() {
    if (!mounted) return;
    _talk.talkFor(_q.speech);
    _speech.sayNow(_q.speech);
  }

  Future<void> _choose(int index) async {
    if (_solved || _wrong.contains(index)) return;
    if (index == _q.answer) {
      setState(() {
        _solved = true;
        _mood = CritterMood.cheer;
        if (_firstTry) _firstTryCorrect++;
      });
      _sound.play(Sfx.correct);
      _burstFrom(index);
      final praise = _speech.randomPraise();
      final line = _q.explanation != null && (_rng.nextBool() || widget.grade.index >= 2) ? '$praise ${_q.explanation}' : praise;
      _talk.talkFor(line);
      final started = DateTime.now();
      await _speech.say(line).timeout(const Duration(seconds: 6), onTimeout: () {});
      final waited = DateTime.now().difference(started);
      if (waited < const Duration(milliseconds: 1300)) {
        await Future<void>.delayed(const Duration(milliseconds: 1300) - waited);
      }
      if (!mounted) return;
      _next();
    } else {
      setState(() {
        _firstTry = false;
        _wrong.add(index);
        _shakes[index] = (_shakes[index] ?? 0) + 1;
        _mood = CritterMood.idle;
      });
      _sound.play(Sfx.wrong);
      final line = _speech.randomTryAgain();
      _talk.talkFor(line);
      _speech.sayNow(line);
    }
  }

  void _burstFrom(int index) {
    final box = _choiceKeys[index]?.currentContext?.findRenderObject() as RenderBox?;
    final size = MediaQuery.sizeOf(context);
    if (box != null && box.hasSize) {
      final center = box.localToGlobal(box.size.center(Offset.zero));
      _confetti.burst(origin: Offset(center.dx / size.width, center.dy / size.height), count: 45);
    } else {
      _confetti.burst();
    }
  }

  void _next() {
    if (_round + 1 >= _rounds) {
      _sound.play(Sfx.win);
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
      _q = _generate();
      _solved = false;
      _firstTry = true;
      _wrong.clear();
      _shakes.clear();
      _choiceKeys.clear();
      _mood = CritterMood.idle;
    });
    _askQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.activity.subjectInfo.color;
    return GameScaffold(
      color: color,
      progress: _round + (_solved ? 1 : 0),
      total: _rounds,
      stars: _firstTryCorrect,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final hostSize = min(130.0, c.maxHeight * 0.34);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: hostSize + 30,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _askQuestion,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _talk,
                            builder: (context, talking, _) => Critter(
                              id: widget.activity.subjectInfo.host,
                              size: hostSize,
                              talking: talking,
                              mood: _mood,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(key: ValueKey(_round), child: _questionArea(color, c)),
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

  Widget _questionArea(Color color, BoxConstraints c) {
    final q = _q;
    final prompt = Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 16, 8),
      child: Row(
        children: [
          Flexible(
            child: SpeechBubble(
              child: Text(
                q.prompt,
                style: q.promptIsReading ? KidText.reading(22) : KidText.display(26),
              ),
            ),
          ),
          const SizedBox(width: 10),
          RoundButton(
            icon: Icons.volume_up_rounded,
            color: color,
            iconColor: Colors.white,
            size: 48,
            onTap: _askQuestion,
            semanticLabel: 'Hear again',
          ),
        ],
      ),
    );

    final choices = _choicesArea(q, color, hasVisual: q.visual != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        prompt,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
            child: q.visual == null
                ? Center(child: choices)
                : Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: Center(child: PopIn(child: q.visual!(context))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(flex: 9, child: Center(child: choices)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _choicesArea(QuizQuestion q, Color color, {required bool hasVisual}) {
    return LayoutBuilder(
      builder: (context, c) {
        final n = q.choices.length;
        final columns = hasVisual ? (n <= 2 ? 1 : 2) : n;
        final rows = (n / columns).ceil();
        final gap = 12.0;
        final maxW = (c.maxWidth - gap * (columns - 1)) / columns;
        final maxH = (c.maxHeight - gap * (rows - 1)) / rows - 8;
        final cell = min(min(maxW, maxH * 1.25), hasVisual ? 170.0 : 200.0);
        final height = min(maxH, cell * 0.85);
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < n; i++)
              SizedBox(
                key: _choiceKeys.putIfAbsent(i, GlobalKey.new),
                width: cell,
                height: height,
                child: PopIn(
                  delay: Duration(milliseconds: 60 * i),
                  child: Shake(trigger: _shakes[i] ?? 0, child: _choiceCard(q, i, color, height)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _choiceCard(QuizQuestion q, int i, Color color, double height) {
    final choice = q.choices[i];
    final wrong = _wrong.contains(i);
    final correct = _solved && i == q.answer;
    final inner = height - 20;
    Widget content;
    switch (choice.look) {
      case ChoiceLook.custom:
        content = FittedBox(child: choice.builder!(context));
      case ChoiceLook.picture:
        content = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: FittedBox(child: EmojiText(choice.emoji!, size: 64))),
            if (choice.label != null)
              FittedBox(
                child: Text(
                  choice.label!,
                  style: choice.readingFont ? KidText.reading(22) : KidText.display(22),
                ),
              ),
          ],
        );
      case ChoiceLook.text:
        final label = choice.label!;
        if (label.length > 10) {
          // Phrases wrap at one comfortable size.
          content = Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: choice.readingFont ? KidText.reading(22, color: AppColors.ink) : KidText.display(22, color: AppColors.ink),
          );
          break;
        }
        final size = label.length <= 2
            ? inner * 0.62
            : label.length <= 5
                ? inner * 0.42
                : inner * 0.28;
        content = FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: choice.readingFont
                ? KidText.reading(size.clamp(16, 80), color: AppColors.ink)
                : KidText.display(size.clamp(16, 80), color: AppColors.ink),
          ),
        );
    }
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: wrong ? 0.4 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: BubblyButton(
              onTap: () => _choose(i),
              color: correct ? const Color(0xFFE3F9EC) : Colors.white,
              borderColor: correct ? AppColors.success : (wrong ? AppColors.oops : color.withValues(alpha: 0.25)),
              gradient: false,
              radius: 24,
              padding: const EdgeInsets.all(8),
              sound: null,
              semanticLabel: choice.speech ?? choice.label,
              child: Center(child: content),
            ),
          ),
          if (correct)
            const Positioned(
              right: -6,
              top: -6,
              child: PopIn(child: _Badge(icon: Icons.check_rounded, color: AppColors.success)),
            ),
          if (wrong)
            const Positioned(
              right: -6,
              top: -6,
              child: _Badge(icon: Icons.close_rounded, color: AppColors.oops),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
