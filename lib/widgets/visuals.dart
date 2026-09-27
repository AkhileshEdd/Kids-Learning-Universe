import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/sound.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import 'common.dart';

// ---------------------------------------------------------------------------
// Colors
// ---------------------------------------------------------------------------

class NamedColor {
  const NamedColor(this.name, this.color);
  final String name;
  final Color color;
}

const basicColors = <NamedColor>[
  NamedColor('red', Color(0xFFF03E3E)),
  NamedColor('blue', Color(0xFF2F80ED)),
  NamedColor('yellow', Color(0xFFFFD43B)),
  NamedColor('green', Color(0xFF37B24D)),
  NamedColor('orange', Color(0xFFFF922B)),
  NamedColor('purple', Color(0xFF8E44E8)),
];

const moreColors = <NamedColor>[
  NamedColor('pink', Color(0xFFFF6FB5)),
  NamedColor('brown', Color(0xFF8B5A2B)),
  NamedColor('black', Color(0xFF222222)),
  NamedColor('white', Color(0xFFFFFFFF)),
  NamedColor('gray', Color(0xFF9AA0A6)),
];

// ---------------------------------------------------------------------------
// Shapes
// ---------------------------------------------------------------------------

enum ShapeKind {
  circle('circle', 0),
  square('square', 4),
  triangle('triangle', 3),
  rectangle('rectangle', 4),
  oval('oval', 0),
  star('star', 10),
  heart('heart', 0),
  diamond('diamond', 4),
  pentagon('pentagon', 5),
  hexagon('hexagon', 6),
  octagon('octagon', 8),
  trapezoid('trapezoid', 4);

  const ShapeKind(this.label, this.sides);
  final String label;
  final int sides;
}

Path shapePath(ShapeKind kind, Size s) {
  final w = s.width, h = s.height;
  final c = Offset(w / 2, h / 2);
  final r = min(w, h) / 2;
  Path polygon(int n, {double rotation = -pi / 2, double radius = 1}) {
    final p = Path();
    for (var i = 0; i < n; i++) {
      final a = rotation + i * 2 * pi / n;
      final pt = c + Offset(cos(a), sin(a)) * r * radius;
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  switch (kind) {
    case ShapeKind.circle:
      return Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.92));
    case ShapeKind.square:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r * 1.6, height: r * 1.6), Radius.circular(r * 0.08)));
    case ShapeKind.triangle:
      return Path()
        ..moveTo(c.dx, c.dy - r * 0.9)
        ..lineTo(c.dx + r * 0.95, c.dy + r * 0.75)
        ..lineTo(c.dx - r * 0.95, c.dy + r * 0.75)
        ..close();
    case ShapeKind.rectangle:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: r * 1.95, height: r * 1.1), Radius.circular(r * 0.06)));
    case ShapeKind.oval:
      return Path()..addOval(Rect.fromCenter(center: c, width: r * 1.95, height: r * 1.25));
    case ShapeKind.star:
      final p = Path();
      for (var i = 0; i < 10; i++) {
        final a = -pi / 2 + i * pi / 5;
        final rr = i.isEven ? r * 0.95 : r * 0.42;
        final pt = c + Offset(cos(a), sin(a)) * rr;
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    case ShapeKind.heart:
      final p = Path();
      final top = c.dy - r * 0.45;
      p.moveTo(c.dx, c.dy + r * 0.85);
      p.cubicTo(c.dx - r * 1.35, c.dy + r * 0.05, c.dx - r * 0.75, top - r * 0.75, c.dx, top);
      p.cubicTo(c.dx + r * 0.75, top - r * 0.75, c.dx + r * 1.35, c.dy + r * 0.05, c.dx, c.dy + r * 0.85);
      return p..close();
    case ShapeKind.diamond:
      return Path()
        ..moveTo(c.dx, c.dy - r * 0.95)
        ..lineTo(c.dx + r * 0.65, c.dy)
        ..lineTo(c.dx, c.dy + r * 0.95)
        ..lineTo(c.dx - r * 0.65, c.dy)
        ..close();
    case ShapeKind.pentagon:
      return polygon(5, radius: 0.95);
    case ShapeKind.hexagon:
      return polygon(6, rotation: 0, radius: 0.92);
    case ShapeKind.octagon:
      return polygon(8, rotation: pi / 8, radius: 0.92);
    case ShapeKind.trapezoid:
      return Path()
        ..moveTo(c.dx - r * 0.5, c.dy - r * 0.55)
        ..lineTo(c.dx + r * 0.5, c.dy - r * 0.55)
        ..lineTo(c.dx + r * 0.98, c.dy + r * 0.55)
        ..lineTo(c.dx - r * 0.98, c.dy + r * 0.55)
        ..close();
  }
}

class ShapeView extends StatelessWidget {
  const ShapeView({super.key, required this.kind, required this.color, this.size = 90, this.showFace = false});

  final ShapeKind kind;
  final Color color;
  final double size;
  final bool showFace;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _ShapePainter(kind, color, showFace)),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.kind, this.color, this.face);

  final ShapeKind kind;
  final Color color;
  final bool face;

  @override
  void paint(Canvas canvas, Size size) {
    final path = shapePath(kind, size);
    canvas.drawShadow(path, Colors.black26, 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.lighten(0.1), color],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035
        ..strokeJoin = StrokeJoin.round
        ..color = color.darken(0.2),
    );
    if (face) {
      final c = size.center(Offset.zero);
      final u = size.width / 20;
      final eye = Paint()..color = AppColors.ink;
      canvas.drawCircle(c + Offset(-2.2 * u, -0.6 * u), 0.9 * u, eye);
      canvas.drawCircle(c + Offset(2.2 * u, -0.6 * u), 0.9 * u, eye);
      canvas.drawArc(
        Rect.fromCenter(center: c + Offset(0, 0.8 * u), width: 3.2 * u, height: 2.4 * u),
        0.2,
        pi - 0.4,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7 * u
          ..strokeCap = StrokeCap.round
          ..color = AppColors.ink,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) => old.kind != kind || old.color != color;
}

// ---------------------------------------------------------------------------
// Balloon (for colors)
// ---------------------------------------------------------------------------

class BalloonView extends StatelessWidget {
  const BalloonView({super.key, required this.color, this.size = 90});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size * 0.8, height: size * 1.15, child: CustomPaint(painter: _BalloonPainter(color)));
  }
}

class _BalloonPainter extends CustomPainter {
  _BalloonPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Rect.fromLTWH(w * 0.05, 0, w * 0.9, h * 0.78);
    final stringPaint = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final string = Path()
      ..moveTo(w / 2, h * 0.8)
      ..quadraticBezierTo(w * 0.35, h * 0.9, w / 2, h);
    canvas.drawPath(string, stringPaint);
    final knot = Path()
      ..moveTo(w / 2, h * 0.76)
      ..lineTo(w * 0.44, h * 0.82)
      ..lineTo(w * 0.56, h * 0.82)
      ..close();
    canvas.drawPath(knot, Paint()..color = color.darken(0.12));
    final isWhite = color.computeLuminance() > 0.9;
    canvas.drawOval(
      body,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [color.lighten(0.12), color, color.darken(0.1)],
        ).createShader(body),
    );
    if (isWhite) {
      canvas.drawOval(body, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black26);
    }
    canvas.drawOval(
      Rect.fromLTWH(w * 0.24, h * 0.1, w * 0.18, h * 0.2),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _BalloonPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Clock
// ---------------------------------------------------------------------------

class ClockFace extends StatelessWidget {
  const ClockFace({super.key, required this.hour, required this.minute, this.size = 200});

  final int hour;
  final int minute;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: size, child: CustomPaint(painter: _ClockPainter(hour, minute)));
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.hour, this.minute);
  final int hour;
  final int minute;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c + const Offset(0, 4), r * 0.96, Paint()..color = Colors.black12);
    canvas.drawCircle(c, r * 0.96, Paint()..color = AppColors.math);
    canvas.drawCircle(c, r * 0.84, Paint()..color = Colors.white);
    final tick = Paint()
      ..color = AppColors.inkSoft
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final a = -pi / 2 + i * pi / 30;
      final major = i % 5 == 0;
      final inner = r * (major ? 0.72 : 0.77);
      tick.strokeWidth = major ? 3 : 1.4;
      canvas.drawLine(c + Offset(cos(a), sin(a)) * inner, c + Offset(cos(a), sin(a)) * r * 0.8, tick);
    }
    for (var n = 1; n <= 12; n++) {
      final a = -pi / 2 + n * pi / 6;
      final tp = TextPainter(
        text: TextSpan(text: '$n', style: KidText.display(r * 0.17, color: AppColors.ink)),
        textDirection: TextDirection.ltr,
      )..layout();
      final pos = c + Offset(cos(a), sin(a)) * r * 0.58;
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
    final hourAngle = -pi / 2 + ((hour % 12) + minute / 60) * pi / 6;
    final minuteAngle = -pi / 2 + minute * pi / 30;
    final hourHand = Paint()
      ..color = AppColors.reading
      ..strokeWidth = r * 0.075
      ..strokeCap = StrokeCap.round;
    final minuteHand = Paint()
      ..color = AppColors.stories
      ..strokeWidth = r * 0.05
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, c + Offset(cos(hourAngle), sin(hourAngle)) * r * 0.4, hourHand);
    canvas.drawLine(c, c + Offset(cos(minuteAngle), sin(minuteAngle)) * r * 0.66, minuteHand);
    canvas.drawCircle(c, r * 0.06, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter old) => old.hour != hour || old.minute != minute;
}

String timeLabel(int hour, int minute) => '$hour:${minute.toString().padLeft(2, '0')}';

String timeSpeech(int hour, int minute) {
  if (minute == 0) return "$hour o'clock";
  if (minute == 30) return 'half past $hour';
  if (minute == 15) return 'quarter past $hour';
  if (minute == 45) return 'quarter to ${hour % 12 + 1}';
  return '$hour ${minute < 10 ? 'oh ${numberWord(minute)}' : numberWord(minute)}';
}

// ---------------------------------------------------------------------------
// Base-ten blocks
// ---------------------------------------------------------------------------

class BaseTenBlocks extends StatelessWidget {
  const BaseTenBlocks({super.key, this.hundreds = 0, required this.tens, required this.ones, this.unit = 14});

  final int hundreds;
  final int tens;
  final int ones;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    Widget cube(Color c) => Container(
          width: u,
          height: u,
          margin: const EdgeInsets.all(0.5),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: c.darken(0.2), width: 1),
          ),
        );
    Widget rod() => Container(
          margin: EdgeInsets.symmetric(horizontal: u * 0.12),
          child: Column(mainAxisSize: MainAxisSize.min, children: List.generate(10, (_) => cube(AppColors.math))),
        );
    Widget flat() => Container(
          margin: EdgeInsets.only(right: u * 0.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              10,
              (_) => Row(mainAxisSize: MainAxisSize.min, children: List.generate(10, (_) => cube(AppColors.art))),
            ),
          ),
        );
    return FittedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < hundreds; i++) flat(),
          for (var i = 0; i < tens; i++) rod(),
          if (ones > 0) SizedBox(width: u * 0.8),
          if (ones > 0)
            SizedBox(
              width: (u + 1) * 2 + 2,
              child: Wrap(
                verticalDirection: VerticalDirection.up,
                children: List.generate(ones, (_) => cube(AppColors.adventure)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Emoji groups
// ---------------------------------------------------------------------------

/// A neat arrangement of [count] emoji. With [tapToCount], each tap numbers an
/// object and says the number out loud.
class EmojiGroup extends StatefulWidget {
  const EmojiGroup({
    super.key,
    required this.emoji,
    required this.count,
    this.size = 44,
    this.tapToCount = false,
    this.crossedOut = 0,
    this.maxPerRow = 5,
  });

  final String emoji;
  final int count;
  final double size;
  final bool tapToCount;

  /// The last [crossedOut] items are shown faded with a cross (take away).
  final int crossedOut;
  final int maxPerRow;

  @override
  State<EmojiGroup> createState() => _EmojiGroupState();
}

class _EmojiGroupState extends State<EmojiGroup> {
  final Map<int, int> _counted = {};

  void _tap(int index) {
    if (!widget.tapToCount || _counted.containsKey(index)) return;
    setState(() => _counted[index] = _counted.length + 1);
    context.read<SoundService>().play(Sfx.pop, volume: 0.6);
    context.read<SpeechService>().sayNow(numberWord(_counted[index]!));
  }

  @override
  Widget build(BuildContext context) {
    final rows = <List<int>>[];
    for (var i = 0; i < widget.count; i += widget.maxPerRow) {
      rows.add(List.generate(min(widget.maxPerRow, widget.count - i), (j) => i + j));
    }
    return FittedBox(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final row in rows)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final i in row)
                  GestureDetector(
                    onTap: () => _tap(i),
                    child: Padding(
                      padding: EdgeInsets.all(widget.size * 0.08),
                      child: _item(i),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _item(int i) {
    final crossed = i >= widget.count - widget.crossedOut;
    final n = _counted[i];
    return SizedBox(
      width: widget.size * 1.15,
      height: widget.size * 1.15,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedScale(
            scale: n != null ? 1.12 : 1,
            duration: const Duration(milliseconds: 200),
            child: Opacity(opacity: crossed ? 0.35 : 1, child: EmojiText(widget.emoji, size: widget.size)),
          ),
          if (crossed) Icon(Icons.close_rounded, color: AppColors.oops, size: widget.size * 1.1),
          if (n != null)
            Positioned(
              right: -4,
              top: -4,
              child: PopIn(
                child: Container(
                  width: widget.size * 0.55,
                  height: widget.size * 0.55,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.math, shape: BoxShape.circle),
                  child: Text('$n', style: KidText.display(widget.size * 0.3, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Emoji on a card with an optional caption.
class PictureCard extends StatelessWidget {
  const PictureCard({super.key, required this.emoji, this.label, this.size = 90, this.color = Colors.white});

  final String emoji;
  final String? label;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiText(emoji, size: size),
          if (label != null) ...[
            SizedBox(height: size * 0.06),
            Text(label!, style: KidText.reading(size * 0.3)),
          ],
        ],
      ),
    );
  }
}

/// A row of pattern items with the next one hidden behind a "?".
class PatternRow extends StatelessWidget {
  const PatternRow({super.key, required this.items, this.size = 46});

  final List<Widget> items;
  final double size;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: item),
            Container(
              width: size * 1.1,
              height: size * 1.1,
              margin: const EdgeInsets.only(left: 4),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.puzzles.pastel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.puzzles, width: 3),
              ),
              child: Text('?', style: KidText.display(size * 0.7, color: AppColors.puzzles)),
            ),
          ],
        ),
      ),
    );
  }
}

/// A big word, letter or number on a card.
class BigTextCard extends StatelessWidget {
  const BigTextCard({super.key, required this.text, this.color = AppColors.reading, this.size = 72, this.reading = true});

  final String text;
  final Color color;
  final double size;
  final bool reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.4, vertical: size * 0.16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 4),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: reading ? KidText.reading(size, color: color) : KidText.display(size, color: color),
      ),
    );
  }
}

/// A short reading passage.
class PassageCard extends StatelessWidget {
  const PassageCard({super.key, required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmojiText(emoji, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(text, style: KidText.reading(19, weight: FontWeight.w400)),
            ),
          ),
        ],
      ),
    );
  }
}
