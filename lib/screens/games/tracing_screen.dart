import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../content/activities.dart';
import '../../content/tracing_glyphs.dart';
import '../../content/word_bank.dart';
import '../../core/sound.dart';
import '../../core/speech.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/grade.dart';
import '../../widgets/common.dart';
import '../../widgets/confetti.dart';
import '../../widgets/critter.dart';
import '../../widgets/game_scaffold.dart';
import '../activity_launcher.dart';

/// Trace letters, numbers or shapes with a finger, stroke by stroke.
class TracingScreen extends StatefulWidget {
  const TracingScreen({super.key, required this.activity, required this.grade});
  final ActivityDef activity;
  final Grade grade;

  @override
  State<TracingScreen> createState() => _TracingScreenState();
}

class _TracingScreenState extends QuietState<TracingScreen> {
  static const _rounds = 4;
  static const _tolerance = 13.0;

  final _rng = Random();
  final _confetti = ConfettiController();
  final _talk = TalkingController();
  late final List<Glyph> _glyphs;
  late List<List<Offset>> _points;
  int _index = 0;
  int _stroke = 0;
  int _progress = 0;
  bool _glyphDone = false;
  final List<Offset> _trail = [];

  bool get _isLetters => widget.activity.variant == 'upper' || widget.activity.variant == 'lower';

  @override
  void initState() {
    super.initState();
    final all = switch (widget.activity.variant) {
      'lower' => lowerGlyphs(),
      'digits' => digitGlyphs(),
      'shapes' => shapeGlyphs(),
      _ => upperGlyphs(),
    };
    _glyphs = _rng.sample(all, _rounds);
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announce());
  }

  @override
  void dispose() {
    _confetti.dispose();
    _talk.dispose();
    super.dispose();
  }

  Glyph get _glyph => _glyphs[_index];

  void _load() {
    _points = [for (final s in _glyph.strokes) samplePath(s)];
    _stroke = 0;
    _progress = 0;
    _glyphDone = false;
    _trail.clear();
  }

  void _announce() {
    if (!mounted) return;
    final g = _glyph;
    String line;
    if (_isLetters) {
      final info = letterInfo(g.label);
      line = "Let's trace the letter ${g.label.toUpperCase()}. ${g.label.toUpperCase()} is for ${info.main.word}!";
    } else if (widget.activity.variant == 'digits') {
      line = "Let's trace the number ${g.spoken}.";
    } else {
      line = "Let's trace a ${g.label}.";
    }
    if (_index == 0) line = '${widget.activity.intro} $line';
    _talk.talkFor(line);
    context.read<SpeechService>().sayNow(line);
  }

  void _onDrag(Offset p) {
    if (_glyphDone) return;
    _trail.add(p);
    if (_trail.length > 40) _trail.removeAt(0);
    final pts = _points[_stroke];
    // Advance along the stroke when the finger is near the next points.
    var advanced = false;
    for (var look = 0; look < 6 && _progress + look < pts.length; look++) {
      if ((pts[_progress + look] - p).distance < _tolerance) {
        _progress = _progress + look + 1;
        advanced = true;
        break;
      }
    }
    if (advanced && _progress >= pts.length) {
      context.read<SoundService>().play(Sfx.pop);
      if (_stroke + 1 < _points.length) {
        _stroke++;
        _progress = 0;
      } else {
        _complete();
      }
    }
    setState(() {});
  }

  Future<void> _complete() async {
    _glyphDone = true;
    context.read<SoundService>().play(Sfx.correct);
    _confetti.burst(origin: const Offset(0.5, 0.45), count: 60);
    final praise = context.read<SpeechService>().randomPraise();
    _talk.talkFor(praise);
    await context.read<SpeechService>().say(praise).timeout(const Duration(seconds: 4), onTimeout: () {});
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    if (_index + 1 >= _glyphs.length) {
      context.read<SoundService>().play(Sfx.win);
      finishActivity(
        context,
        activity: widget.activity,
        firstTryCorrect: _glyphs.length,
        total: _glyphs.length,
        seconds: elapsedSeconds,
        grade: widget.grade,
      );
      return;
    }
    setState(() {
      _index++;
      _load();
    });
    _announce();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.activity.subjectInfo.color;
    return GameScaffold(
      color: color,
      title: widget.activity.title,
      progress: _index + (_glyphDone ? 1 : 0),
      total: _glyphs.length,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, c) {
              final box = min(c.maxHeight - 16, c.maxWidth * 0.5);
              return Row(
                children: [
                  SizedBox(
                    width: max(120, (c.maxWidth - box) / 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _announce,
                          child: ValueListenableBuilder<bool>(
                            valueListenable: _talk,
                            builder: (context, talking, _) => Critter(
                              id: widget.activity.subjectInfo.host,
                              size: min(130, c.maxHeight * 0.36),
                              talking: talking,
                              mood: _glyphDone ? CritterMood.cheer : CritterMood.idle,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: box,
                    height: box,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 5))],
                      ),
                      child: LayoutBuilder(
                        builder: (context, inner) {
                          final scale = inner.maxWidth / 100;
                          Offset toUnits(Offset local) => local / scale;
                          return GestureDetector(
                            onPanStart: (d) => _onDrag(toUnits(d.localPosition)),
                            onPanUpdate: (d) => _onDrag(toUnits(d.localPosition)),
                            onPanEnd: (_) => setState(_trail.clear),
                            child: CustomPaint(
                              size: Size.square(inner.maxWidth),
                              painter: _TracePainter(
                                strokes: _points,
                                current: _stroke,
                                progress: _progress,
                                done: _glyphDone,
                                trail: List.of(_trail),
                                color: color,
                                guides: switch (widget.activity.variant) {
                                  'upper' => const [15.0, 50.0, 85.0],
                                  'lower' => const [12.0, 42.0, 75.0],
                                  _ => const <double>[],
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Wrap(
                        direction: Axis.vertical,
                        spacing: 8,
                        children: [
                          for (var i = 0; i < _glyphs.length; i++)
                            Container(
                              width: 54,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i < _index || (i == _index && _glyphDone) ? AppColors.success : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: i == _index ? color : Colors.transparent, width: 3),
                              ),
                              child: widget.activity.variant == 'shapes'
                                  ? const EmojiText('✏️', size: 22)
                                  : Text(
                                      _glyphs[i].label,
                                      style: KidText.reading(28, color: i < _index ? Colors.white : AppColors.ink),
                                    ),
                            ),
                        ],
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

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.strokes,
    required this.current,
    required this.progress,
    required this.done,
    required this.trail,
    required this.color,
    required this.guides,
  });

  final List<List<Offset>> strokes;
  final int current;
  final int progress;
  final bool done;
  final List<Offset> trail;
  final Color color;
  final List<double> guides;

  Path _poly(List<Offset> pts, double s) {
    final p = Path();
    for (var i = 0; i < pts.length; i++) {
      final o = pts[i] * s;
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    final guide = Paint()
      ..color = const Color(0xFFE9E5F5)
      ..strokeWidth = 1.5;
    for (final y in guides) {
      canvas.drawLine(Offset(6 * s, y * s), Offset(94 * s, y * s), guide);
    }
    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // All strokes as a soft guide.
    for (var i = 0; i < strokes.length; i++) {
      canvas.drawPath(_poly(strokes[i], s), stroke(i == current && !done ? const Color(0xFFD9D2F0) : const Color(0xFFEDEAF7), 15));
    }
    // Dashed center line for the current stroke.
    if (!done && current < strokes.length) {
      final pts = strokes[current];
      final dash = stroke(Colors.white, 2.2);
      for (var i = 0; i + 1 < pts.length; i += 2) {
        canvas.drawLine(pts[i] * s, pts[i + 1] * s, dash);
      }
    }
    // Finished strokes and progress in bright color.
    final ink = stroke(color, 13);
    for (var i = 0; i < strokes.length; i++) {
      if (done || i < current) {
        canvas.drawPath(_poly(strokes[i], s), ink);
      } else if (i == current && progress > 0) {
        canvas.drawPath(_poly(strokes[i].sublist(0, progress.clamp(0, strokes[i].length)), s), ink);
      }
    }
    // Start dot and direction arrow.
    if (!done && current < strokes.length) {
      final pts = strokes[current];
      final at = pts[progress.clamp(0, pts.length - 1)];
      canvas.drawCircle(at * s, 8 * s, Paint()..color = AppColors.success);
      canvas.drawCircle(at * s, 8 * s, stroke(Colors.white, 1.4));
      final ahead = pts[(progress + 5).clamp(0, pts.length - 1)];
      final dir = ahead - at;
      if (dir.distance > 0.5) {
        // A white chevron inside the dot shows which way to go.
        final u = dir / dir.distance;
        Offset rot(Offset v, double a) => Offset(v.dx * cos(a) - v.dy * sin(a), v.dx * sin(a) + v.dy * cos(a));
        final tip = at + u * 3;
        final chevron = Path()
          ..moveTo((tip - rot(u, 0.7) * 4.5).dx * s, (tip - rot(u, 0.7) * 4.5).dy * s)
          ..lineTo(tip.dx * s, tip.dy * s)
          ..lineTo((tip - rot(u, -0.7) * 4.5).dx * s, (tip - rot(u, -0.7) * 4.5).dy * s);
        canvas.drawPath(chevron, stroke(Colors.white, 2));
      }
    }
    // Finger trail.
    if (trail.length > 1) {
      canvas.drawPath(_poly(trail, s), stroke(color.withValues(alpha: 0.25), 4));
    }
  }

  @override
  bool shouldRepaint(covariant _TracePainter old) => true;
}
