import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../content/activities.dart';
import '../../core/sound.dart';
import '../../core/speech.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/grade.dart';
import '../../state/app_state.dart';
import '../../widgets/bubbly_button.dart';
import '../../widgets/confetti.dart';
import '../../widgets/game_scaffold.dart';
import '../activity_launcher.dart';

class _Bubble {
  _Bubble(this.id, this.label, this.x, this.speed, this.size, this.phase, this.color);
  final int id;
  final String label;
  final double x;
  final double speed;
  final double size;
  final double phase;
  final Color color;
  double y = 0;
  bool popped = false;
  double popT = 0;
}

/// Pop the floating bubbles that show the target letter or number.
class BubblePopScreen extends StatefulWidget {
  const BubblePopScreen({super.key, required this.activity, required this.grade});
  final ActivityDef activity;
  final Grade grade;

  @override
  State<BubblePopScreen> createState() => _BubblePopScreenState();
}

class _BubblePopScreenState extends QuietState<BubblePopScreen> with SingleTickerProviderStateMixin {
  final _rng = Random();
  final _confetti = ConfettiController();
  late final Ticker _ticker;
  final List<_Bubble> _bubbles = [];
  late final List<String> _targets;
  late final List<String> _pool;
  late final int _perTarget = widget.grade == Grade.preschool ? 3 : 4;
  late final int _level = context.read<AppState>().levelFor(widget.activity.skillKey);
  int _targetIndex = 0;
  int _popped = 0;
  int _mistakes = 0;
  int _nextId = 0;
  double _spawnClock = 0;
  Duration _last = Duration.zero;
  Size _area = Size.zero;
  bool _finished = false;

  bool get _numbers => widget.activity.variant == 'numbers';
  String get _target => _targets[_targetIndex];
  int get _goal => _perTarget * _targets.length;

  @override
  void initState() {
    super.initState();
    if (_numbers) {
      final maxN = switch (widget.grade) {
        Grade.preschool => 5 + _level * 2,
        Grade.kindergarten => 10 + _level * 5,
        _ => 20 + _level * 20,
      };
      _pool = [for (var i = 1; i <= maxN; i++) '$i'];
    } else {
      final lower = widget.grade != Grade.preschool && _level > 0;
      _pool = [for (final c in 'abcdefghijklmnopqrstuvwxyz'.split('')) lower ? c : c.toUpperCase()];
    }
    _targets = _rng.sample(_pool, 2);
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce(first: true));
  }

  @override
  void dispose() {
    _ticker.dispose();
    _confetti.dispose();
    super.dispose();
  }

  String _spoken(String label) => _numbers ? numberWord(int.parse(label)) : 'the letter ${label.toUpperCase()}';

  void _announce({bool first = false}) {
    if (!mounted) return;
    final line = '${first ? '${widget.activity.intro} ' : ''}Pop every bubble with ${_spoken(_target)}!';
    context.read<SpeechService>().sayNow(line);
  }

  void _spawn() {
    if (_area == Size.zero) return;
    final isTarget = _rng.chance(0.42);
    String label;
    if (isTarget) {
      label = _target;
    } else {
      do {
        label = _rng.pick(_pool);
      } while (label == _target);
    }
    final size = min(96.0, _area.height * 0.22) * (0.9 + _rng.nextDouble() * 0.25);
    _bubbles.add(_Bubble(
      _nextId++,
      label,
      0.08 + _rng.nextDouble() * 0.84,
      (38 + _rng.nextDouble() * 30) * (1 + _level * 0.18),
      size,
      _rng.nextDouble() * 2 * pi,
      AppColors.playful[_rng.nextInt(AppColors.playful.length)],
    )..y = -size);
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 0.016 : min(0.05, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    if (_finished) return;
    _spawnClock += dt;
    final onScreen = _bubbles.where((b) => !b.popped).length;
    if (_spawnClock > 0.85 && onScreen < 9) {
      _spawnClock = 0;
      _spawn();
    }
    for (final b in _bubbles) {
      if (b.popped) {
        b.popT += dt * 4;
      } else {
        b.y += b.speed * dt;
      }
    }
    _bubbles.removeWhere((b) => b.popT >= 1 || b.y > _area.height + b.size);
    // Make sure the target keeps appearing.
    if (!_bubbles.any((b) => !b.popped && b.label == _target) && _spawnClock > 0.4) {
      _spawnClock = 0;
      _bubbles.add(_Bubble(_nextId++, _target, 0.1 + _rng.nextDouble() * 0.8, 50, min(96.0, _area.height * 0.22), 0,
          AppColors.playful[_rng.nextInt(AppColors.playful.length)])
        ..y = -60);
    }
    setState(() {});
  }

  void _tapBubble(_Bubble b) {
    if (b.popped || _finished) return;
    final sound = context.read<SoundService>();
    final speech = context.read<SpeechService>();
    if (b.label == _target) {
      b.popped = true;
      _popped++;
      sound.play(Sfx.pop);
      if (_popped % _perTarget == 0) {
        if (_popped >= _goal) {
          _win();
        } else {
          _targetIndex++;
          sound.play(Sfx.star);
          speech.sayNow('${speech.randomPraise()} Now pop ${_spoken(_target)}!');
        }
      }
    } else {
      _mistakes++;
      sound.play(Sfx.wrong, volume: 0.6);
      speech.sayNow('That is ${_spoken(b.label)}. Find ${_spoken(_target)}!');
    }
  }

  Future<void> _win() async {
    _finished = true;
    _confetti.burst(count: 100);
    context.read<SoundService>().play(Sfx.win);
    context.read<SpeechService>().sayNow(context.read<SpeechService>().randomPraise());
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    finishActivity(
      context,
      activity: widget.activity,
      firstTryCorrect: (_goal - _mistakes).clamp(1, _goal),
      total: _goal,
      seconds: elapsedSeconds,
      grade: widget.grade,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.activity.subjectInfo.color;
    return GameScaffold(
      color: color,
      progress: _popped,
      total: _goal,
      actions: [
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _announce,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: color, width: 3)),
            child: Row(
              children: [
                Text('Pop', style: KidText.display(18, color: color)),
                const SizedBox(width: 8),
                Text(_target, style: KidText.reading(30)),
                const SizedBox(width: 6),
                RoundButton(icon: Icons.volume_up_rounded, size: 36, color: color, iconColor: Colors.white, onTap: _announce),
              ],
            ),
          ),
        ),
      ],
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              _area = c.biggest;
              return Stack(
                children: [
                  for (final b in _bubbles)
                    Positioned(
                      left: b.x * (c.maxWidth - b.size) + sin(b.y / 40 + b.phase) * 10,
                      top: c.maxHeight - b.y,
                      width: b.size,
                      height: b.size,
                      child: GestureDetector(
                        onTapDown: (_) => _tapBubble(b),
                        child: Opacity(
                          opacity: b.popped ? (1 - b.popT).clamp(0, 1) : 1,
                          child: Transform.scale(
                            scale: b.popped ? 1 + b.popT * 0.6 : 1,
                            child: _BubbleView(label: b.label, color: b.color, size: b.size),
                          ),
                        ),
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

class _BubbleView extends StatelessWidget {
  const _BubbleView({required this.label, required this.color, required this.size});
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          colors: [Colors.white.withValues(alpha: 0.95), color.withValues(alpha: 0.55), color.withValues(alpha: 0.85)],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12)],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: KidText.reading(size * (label.length > 1 ? 0.38 : 0.5), color: AppColors.ink),
      ),
    );
  }
}
