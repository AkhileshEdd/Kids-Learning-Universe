import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../content/activities.dart';
import '../../core/sound.dart';
import '../../core/speech.dart';
import '../../core/theme.dart';
import '../../models/grade.dart';
import '../../widgets/bubbly_button.dart';
import '../../widgets/common.dart';
import '../../widgets/game_scaffold.dart';
import '../activity_launcher.dart';

const drawingColors = <Color>[
  Color(0xFFF03E3E), Color(0xFFFF922B), Color(0xFFFFD43B), Color(0xFF37B24D), Color(0xFF2EC4B6),
  Color(0xFF2F80ED), Color(0xFF8E44E8), Color(0xFFFF6FB5), Color(0xFF8B5A2B), Color(0xFF222222),
];

enum _Tool { brush, rainbow, eraser, stamp }

class _Mark {
  _Mark.stroke(this.color, this.width, {this.rainbow = false})
      : points = [],
        emoji = null;
  _Mark.stamp(this.emoji, Offset at, this.width)
      : points = [at],
        color = Colors.transparent,
        rainbow = false;

  final List<Offset> points;
  final Color color;
  final double width;
  final bool rainbow;
  final String? emoji;
}

/// Free drawing with colors, a rainbow brush and emoji stamps.
class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key, required this.activity});
  final ActivityDef activity;

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends QuietState<DrawingScreen> {
  final List<_Mark> _marks = [];
  _Tool _tool = _Tool.brush;
  Color _color = drawingColors[5];
  double _width = 12;
  String _stamp = '⭐';
  int _repaint = 0;

  static const _stamps = ['⭐', '❤️', '🌸', '🦋', '🚀', '🌈', '🐱', '🍎'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SpeechService>().sayNow(widget.activity.intro);
    });
  }

  void _start(Offset p) {
    if (_tool == _Tool.stamp) {
      context.read<SoundService>().play(Sfx.pop);
      setState(() => _marks.add(_Mark.stamp(_stamp, p, _width * 3.5)));
      return;
    }
    final mark = switch (_tool) {
      _Tool.eraser => _Mark.stroke(Colors.white, _width * 2.2),
      _Tool.rainbow => _Mark.stroke(Colors.red, _width, rainbow: true),
      _ => _Mark.stroke(_color, _width),
    };
    mark.points.add(p);
    setState(() => _marks.add(mark));
  }

  void _move(Offset p) {
    if (_tool == _Tool.stamp || _marks.isEmpty) return;
    _marks.last.points.add(p);
    setState(() => _repaint++);
  }

  void _done() {
    context.read<SpeechService>().stop();
    if (_marks.length < 3) {
      Navigator.of(context).pop();
      return;
    }
    context.read<SoundService>().play(Sfx.win);
    finishActivity(
      context,
      activity: widget.activity,
      firstTryCorrect: 0,
      total: 0,
      seconds: elapsedSeconds,
      grade: Grade.preschool,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.activity.subjectInfo.color;
    Widget toolButton(_Tool tool, Widget icon, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BubblyButton(
            onTap: () => setState(() => _tool = tool),
            color: _tool == tool ? color : Colors.white,
            width: 56,
            height: 48,
            depth: 4,
            radius: 16,
            padding: EdgeInsets.zero,
            gradient: false,
            semanticLabel: label,
            child: icon,
          ),
        );

    return GameScaffold(
      color: color,
      title: widget.activity.title,
      actions: [
        RoundButton(
          icon: Icons.undo_rounded,
          size: 44,
          semanticLabel: 'Undo',
          onTap: _marks.isEmpty ? null : () => setState(() => _marks.removeLast()),
        ),
        const SizedBox(width: 8),
        RoundButton(
          icon: Icons.delete_sweep_rounded,
          size: 44,
          semanticLabel: 'Clear',
          onTap: _marks.isEmpty
              ? null
              : () {
                  context.read<SoundService>().play(Sfx.whoosh);
                  setState(_marks.clear);
                },
        ),
        const SizedBox(width: 8),
        BubblyButton.label(label: 'Done', icon: Icons.check_rounded, color: AppColors.success, fontSize: 18, onTap: _done),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Row(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  toolButton(_Tool.brush, Icon(Icons.brush_rounded, color: _tool == _Tool.brush ? Colors.white : AppColors.ink), 'Brush'),
                  toolButton(_Tool.rainbow, const EmojiText('🌈', size: 26), 'Rainbow brush'),
                  toolButton(_Tool.stamp, EmojiText(_stamp, size: 24), 'Stamps'),
                  toolButton(_Tool.eraser, Icon(Icons.auto_fix_normal_rounded, color: _tool == _Tool.eraser ? Colors.white : AppColors.ink), 'Eraser'),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Container(
                  color: Colors.white,
                  child: GestureDetector(
                    onPanStart: (d) => _start(d.localPosition),
                    onPanUpdate: (d) => _move(d.localPosition),
                    onTapDown: (d) {
                      if (_tool == _Tool.stamp) _start(d.localPosition);
                    },
                    child: CustomPaint(
                      painter: _DrawingPainter(_marks, _repaint),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 96,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (final w in const [6.0, 12.0, 20.0])
                          GestureDetector(
                            onTap: () => setState(() => _width = w),
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _width == w ? color.pastel : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: _width == w ? color : Colors.transparent, width: 2),
                              ),
                              child: Container(
                                width: w,
                                height: w,
                                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _tool == _Tool.stamp
                    ? Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final s in _stamps)
                            GestureDetector(
                              onTap: () => setState(() => _stamp = s),
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: s == _stamp ? color.pastel : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: s == _stamp ? color : Colors.transparent, width: 2),
                                ),
                                child: EmojiText(s, size: 26),
                              ),
                            ),
                        ],
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in drawingColors)
                            GestureDetector(
                              onTap: () => setState(() {
                                _color = c;
                                if (_tool != _Tool.brush) _tool = _Tool.brush;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: c,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: _color == c && _tool == _Tool.brush ? 5 : 2),
                                  boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  _DrawingPainter(this.marks, this.version);
  final List<_Mark> marks;
  final int version;

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in marks) {
      if (m.emoji != null) {
        final tp = TextPainter(
          text: TextSpan(text: m.emoji, style: KidText.emoji(m.width)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, m.points.first - Offset(tp.width / 2, tp.height / 2));
        continue;
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = m.width;
      if (m.points.length == 1) {
        canvas.drawCircle(m.points.first, m.width / 2, Paint()..color = m.rainbow ? Colors.red : m.color);
        continue;
      }
      if (m.rainbow) {
        for (var i = 1; i < m.points.length; i++) {
          paint.color = HSVColor.fromAHSV(1, (i * 6) % 360, 0.85, 1).toColor();
          canvas.drawLine(m.points[i - 1], m.points[i], paint);
        }
      } else {
        paint.color = m.color;
        final path = Path()..moveTo(m.points.first.dx, m.points.first.dy);
        for (final p in m.points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter old) => true;
}
