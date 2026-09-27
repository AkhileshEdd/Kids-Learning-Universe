import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../content/characters.dart';

enum CritterMood { idle, happy, cheer }

/// An animated, hand-painted character (Cosmo, Lexi, Pip, Dash, Luna, Coco).
///
/// The character bobs gently, blinks, moves its mouth while [talking], waves
/// when [wave] is set and jumps for joy when [mood] is [CritterMood.cheer].
class Critter extends StatefulWidget {
  const Critter({
    super.key,
    required this.id,
    this.size = 120,
    this.talking = false,
    this.mood = CritterMood.idle,
    this.wave = false,
    this.showBody = true,
    this.animate = true,
  });

  final CharacterId id;

  /// Width in logical pixels (height is 1.25x with a body).
  final double size;
  final bool talking;
  final CritterMood mood;
  final bool wave;
  final bool showBody;
  final bool animate;

  @override
  State<Critter> createState() => _CritterState();
}

class _CritterState extends State<Critter> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _time = ValueNotifier<double>(0);
  double _blinkUntil = -1;
  double _nextBlink = 1.5;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final t = elapsed.inMicroseconds / 1e6;
      if (t > _nextBlink) {
        _blinkUntil = t + 0.14;
        _nextBlink = t + 2.2 + _rng.nextDouble() * 3;
      }
      _time.value = t;
    });
    if (widget.animate) _ticker.start();
  }

  @override
  void didUpdateWidget(Critter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ticker.isActive) _ticker.start();
    if (!widget.animate && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.showBody ? widget.size * 1.25 : widget.size;
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: h,
        child: CustomPaint(
          painter: CritterPainter(
            id: widget.id,
            time: _time,
            blinkUntil: () => _blinkUntil,
            talking: widget.talking,
            mood: widget.mood,
            wave: widget.wave,
            showBody: widget.showBody,
          ),
        ),
      ),
    );
  }
}

class _Palette {
  const _Palette({
    required this.fur,
    required this.belly,
    required this.accent,
    required this.dark,
    this.suit,
  });

  final Color fur;
  final Color belly;
  final Color accent;
  final Color dark;
  final Color? suit;
}

const _palettes = {
  CharacterId.cosmo: _Palette(
    fur: Color(0xFFB9784A),
    belly: Color(0xFFF3D9BC),
    accent: Color(0xFFF3C49B),
    dark: Color(0xFF4A2E23),
    suit: Color(0xFFF1F4FF),
  ),
  CharacterId.lexi: _Palette(fur: Color(0xFFFF8A3D), belly: Color(0xFFFFF3E6), accent: Color(0xFFFFD1B0), dark: Color(0xFF4A3028)),
  CharacterId.pip: _Palette(fur: Color(0xFF2F3E75), belly: Color(0xFFFFFFFF), accent: Color(0xFFFFA62B), dark: Color(0xFF1C2447)),
  CharacterId.dash: _Palette(fur: Color(0xFF4CC38A), belly: Color(0xFFC8F5D9), accent: Color(0xFFFFB321), dark: Color(0xFF1F6B46)),
  CharacterId.luna: _Palette(fur: Color(0xFF8E6CF1), belly: Color(0xFFE8DEFF), accent: Color(0xFFFFC93C), dark: Color(0xFF4B3494)),
  CharacterId.coco: _Palette(fur: Color(0xFFFFF0F5), belly: Color(0xFFFFFFFF), accent: Color(0xFFFF9CC2), dark: Color(0xFF6B4A5A)),
};

class CritterPainter extends CustomPainter {
  CritterPainter({
    required this.id,
    required this.time,
    required this.blinkUntil,
    required this.talking,
    required this.mood,
    required this.wave,
    required this.showBody,
  }) : super(repaint: time);

  final CharacterId id;
  final ValueNotifier<double> time;
  final double Function() blinkUntil;
  final bool talking;
  final CritterMood mood;
  final bool wave;
  final bool showBody;

  static const _ink = Color(0xFF2B2140);
  static const _mouth = Color(0xFF7A2E3A);
  static const _tongue = Color(0xFFFF8FA3);

  _Palette get _p => _palettes[id]!;

  Paint _fill(Color c) => Paint()..color = c;

  Paint _outline([double w = 2.2]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = _p.dark.withValues(alpha: 0.55);

  void _shape(Canvas c, Path path, Color color, {bool outline = true}) {
    c.drawPath(path, _fill(color));
    if (outline) c.drawPath(path, _outline());
  }

  Path _oval(double cx, double cy, double w, double h) =>
      Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final s = size.width / 100;
    canvas.save();
    canvas.scale(s);

    final blinking = t < blinkUntil();
    var bob = sin(t * 2.4) * 1.6;
    if (mood == CritterMood.cheer) bob = -(sin(t * 7).abs()) * 9;
    final mouthOpen = talking ? (0.35 + 0.65 * (sin(t * 16) * 0.5 + 0.5)) : 0.0;
    final waveAngle = wave || mood == CritterMood.cheer ? sin(t * 8) * 0.35 : 0.0;

    // Ground shadow.
    if (showBody) {
      final shadowScale = mood == CritterMood.cheer ? 1 + bob / 30 : 1.0;
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(50, 123), width: 52 * shadowScale, height: 6),
        _fill(Colors.black.withValues(alpha: 0.14)),
      );
    }

    canvas.translate(0, bob);
    if (showBody) _body(canvas, t, waveAngle);
    _head(canvas, t, blinking, mouthOpen);
    canvas.restore();
  }

  // ------------------------------------------------------------------ body

  void _body(Canvas c, double t, double waveAngle) {
    final suit = _p.suit ?? _p.fur;
    // Tails behind the body.
    if (id == CharacterId.lexi) {
      c.save();
      c.translate(74, 104);
      c.rotate(-0.7 + sin(t * 2) * 0.12);
      _shape(c, _oval(0, -12, 18, 34), _p.fur);
      c.drawPath(_oval(0, -24, 11, 12), _fill(_p.belly));
      c.restore();
    } else if (id == CharacterId.dash) {
      final tail = Path()
        ..moveTo(32, 108)
        ..quadraticBezierTo(10, 116, 4, 100 + sin(t * 2) * 3)
        ..quadraticBezierTo(16, 104, 34, 96)
        ..close();
      _shape(c, tail, _p.fur);
    } else if (id == CharacterId.coco) {
      _shape(c, _oval(72, 112, 14, 14), Colors.white);
    }

    // Feet.
    final footColor = switch (id) {
      CharacterId.pip => _p.accent,
      CharacterId.cosmo => const Color(0xFF7D86B3),
      _ => _p.fur,
    };
    _shape(c, _oval(38, 120, 20, 10), footColor);
    _shape(c, _oval(62, 120, 20, 10), footColor);

    // Left arm (static).
    c.save();
    c.translate(29, 88);
    c.rotate(0.45 + sin(t * 2.4) * 0.05);
    _shape(c, _oval(0, 10, 13, 26), id == CharacterId.cosmo ? suit : (id == CharacterId.luna ? _p.dark : _p.fur));
    c.restore();

    // Torso.
    final body = _oval(50, 100, 56, 46);
    _shape(c, body, suit);
    if (id == CharacterId.cosmo) {
      // Space suit details: collar, belt and a star badge.
      c.drawPath(_oval(50, 102, 34, 30), _fill(const Color(0xFFDDE3FA)));
      _star(c, const Offset(58, 96), 5.5, const Color(0xFFFFC93C));
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(50, 112), width: 44, height: 5), const Radius.circular(3)),
        _fill(const Color(0xFFFF7A59)),
      );
    } else if (id == CharacterId.luna) {
      c.drawPath(_oval(50, 103, 34, 32), _fill(_p.belly));
      final scallop = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _p.fur.withValues(alpha: 0.5);
      for (final y in [96.0, 104.0, 112.0]) {
        for (final x in [42.0, 50.0, 58.0]) {
          c.drawArc(Rect.fromCenter(center: Offset(x, y), width: 7, height: 6), 0.2, pi - 0.4, false, scallop);
        }
      }
    } else {
      c.drawPath(_oval(50, 104, 34, 32), _fill(_p.belly));
    }
    if (id == CharacterId.pip) {
      // A cozy yellow scarf.
      final scarf = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(50, 81), width: 46, height: 9), const Radius.circular(5));
      c.drawRRect(scarf, _fill(const Color(0xFFFFC93C)));
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(56, 82, 9, 18), const Radius.circular(4)),
        _fill(const Color(0xFFF2A007)),
      );
    }

    // Right arm (waves).
    c.save();
    c.translate(71, 88);
    final raise = waveAngle != 0 ? -2.3 + waveAngle : -0.45 - sin(t * 2.4) * 0.05;
    c.rotate(raise);
    _shape(c, _oval(0, 10, 13, 26), id == CharacterId.cosmo ? suit : (id == CharacterId.luna ? _p.dark : _p.fur));
    c.restore();
  }

  void _star(Canvas c, Offset center, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final pt = center + Offset(cos(a), sin(a)) * rr;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, _fill(color));
  }

  // ------------------------------------------------------------------ head

  void _head(Canvas c, double t, bool blinking, double mouthOpen) {
    switch (id) {
      case CharacterId.cosmo:
        _bearHead(c);
      case CharacterId.lexi:
        _foxHead(c);
      case CharacterId.pip:
        _penguinHead(c);
      case CharacterId.dash:
        _dinoHead(c, t);
      case CharacterId.luna:
        _owlHead(c);
      case CharacterId.coco:
        _bunnyHead(c, t);
    }

    final happyEyes = mood != CritterMood.idle;
    if (id == CharacterId.luna) {
      _owlEyes(c, blinking, happyEyes);
    } else {
      final eyeY = id == CharacterId.pip ? 50.0 : 47.0;
      final spread = id == CharacterId.dash ? 14.0 : 12.0;
      _eyes(c, Offset(50 - spread, eyeY), Offset(50 + spread, eyeY), blinking, happyEyes);
    }

    // Cheeks.
    final cheek = _fill(const Color(0xFFFF7FA0).withValues(alpha: id == CharacterId.coco ? 0.55 : 0.4));
    c.drawCircle(const Offset(29, 60), 5.2, cheek);
    c.drawCircle(const Offset(71, 60), 5.2, cheek);

    _mouthAt(c, id == CharacterId.pip ? const Offset(50, 69) : const Offset(50, 64), mouthOpen);

    if (id == CharacterId.cosmo) _helmet(c);
  }

  void _bearHead(Canvas c) {
    for (final x in [24.0, 76.0]) {
      _shape(c, _oval(x, 22, 24, 24), _p.fur);
      c.drawPath(_oval(x, 23, 13, 13), _fill(_p.accent));
    }
    _shape(c, _oval(50, 48, 68, 62), _p.fur);
    c.drawPath(_oval(50, 61, 30, 22), _fill(_p.belly));
    final nose = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(50, 55), width: 11, height: 7.5), const Radius.circular(4));
    c.drawRRect(nose, _fill(_p.dark));
    c.drawCircle(const Offset(48, 53.5), 1.4, _fill(Colors.white.withValues(alpha: 0.7)));
  }

  void _helmet(Canvas c) {
    final rect = Rect.fromCircle(center: const Offset(50, 46), radius: 45);
    c.drawOval(rect, _fill(const Color(0xFFBFE6FF).withValues(alpha: 0.16)));
    c.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..color = Colors.white.withValues(alpha: 0.9),
    );
    c.drawArc(
      Rect.fromCircle(center: const Offset(50, 46), radius: 38),
      pi * 1.1,
      pi * 0.35,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.75),
    );
    // Antenna.
    c.drawLine(const Offset(50, 1), const Offset(50, -7), Paint()
      ..strokeWidth = 2
      ..color = Colors.white);
    c.drawCircle(const Offset(50, -8), 3.2, _fill(const Color(0xFFFF7A59)));
  }

  void _foxHead(Canvas c) {
    for (final side in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(50 + side * 8, 24)
        ..lineTo(50 + side * 31, 1)
        ..lineTo(50 + side * 32, 36)
        ..close();
      _shape(c, ear, _p.fur);
      final inner = Path()
        ..moveTo(50 + side * 14, 24)
        ..lineTo(50 + side * 29, 8)
        ..lineTo(50 + side * 29, 30)
        ..close();
      c.drawPath(inner, _fill(_p.accent));
      final tip = Path()
        ..moveTo(50 + side * 26, 7)
        ..lineTo(50 + side * 31, 1)
        ..lineTo(50 + side * 31.5, 12)
        ..close();
      c.drawPath(tip, _fill(_p.dark));
    }
    final head = Path()
      ..moveTo(50, 16)
      ..cubicTo(78, 16, 88, 40, 86, 58)
      ..lineTo(92, 62)
      ..cubicTo(80, 80, 64, 82, 50, 82)
      ..cubicTo(36, 82, 20, 80, 8, 62)
      ..lineTo(14, 58)
      ..cubicTo(12, 40, 22, 16, 50, 16)
      ..close();
    _shape(c, head, _p.fur);
    final mask = Path()
      ..moveTo(50, 50)
      ..cubicTo(40, 50, 24, 56, 14, 60)
      ..cubicTo(22, 74, 36, 80, 50, 80)
      ..cubicTo(64, 80, 78, 74, 86, 60)
      ..cubicTo(76, 56, 60, 50, 50, 50)
      ..close();
    c.drawPath(mask, _fill(_p.belly));
    c.drawPath(_oval(50, 57, 9, 6.5), _fill(_p.dark));
  }

  void _penguinHead(Canvas c) {
    _shape(c, _oval(50, 48, 70, 64), _p.fur);
    // Tuft.
    final tuft = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = _p.fur;
    c.drawArc(Rect.fromCenter(center: const Offset(46, 16), width: 12, height: 14), pi, 1.4, false, tuft);
    c.drawArc(Rect.fromCenter(center: const Offset(54, 15), width: 12, height: 14), pi * 1.6, 1.2, false, tuft);
    final face = Path()
      ..addOval(Rect.fromCenter(center: const Offset(39, 52), width: 30, height: 32))
      ..addOval(Rect.fromCenter(center: const Offset(61, 52), width: 30, height: 32))
      ..addOval(Rect.fromCenter(center: const Offset(50, 64), width: 40, height: 26));
    c.drawPath(face, _fill(_p.belly));
    final beak = Path()
      ..moveTo(43, 59)
      ..quadraticBezierTo(50, 55, 57, 59)
      ..quadraticBezierTo(50, 68, 43, 59)
      ..close();
    c.drawPath(beak, _fill(_p.accent));
  }

  void _dinoHead(Canvas c, double t) {
    // Spikes along the top.
    for (var i = 0; i < 4; i++) {
      final x = 30.0 + i * 13;
      final y = 18 + (i == 0 || i == 3 ? 5 : 0);
      final spike = Path()
        ..moveTo(x - 6, y + 6)
        ..lineTo(x, y - 8)
        ..lineTo(x + 6, y + 6)
        ..close();
      _shape(c, spike, _p.accent);
    }
    _shape(c, _oval(50, 50, 76, 62), _p.fur);
    c.drawCircle(const Offset(30, 30), 4, _fill(_p.belly.withValues(alpha: 0.7)));
    c.drawCircle(const Offset(72, 34), 3, _fill(_p.belly.withValues(alpha: 0.7)));
    c.drawPath(_oval(50, 62, 40, 22), _fill(_p.belly));
    c.drawCircle(const Offset(45, 57), 1.6, _fill(_p.dark));
    c.drawCircle(const Offset(55, 57), 1.6, _fill(_p.dark));
  }

  void _owlHead(Canvas c) {
    for (final side in [-1.0, 1.0]) {
      final tuft = Path()
        ..moveTo(50 + side * 14, 20)
        ..lineTo(50 + side * 30, 4)
        ..lineTo(50 + side * 32, 28)
        ..close();
      _shape(c, tuft, _p.fur);
    }
    _shape(c, _oval(50, 48, 72, 64), _p.fur);
    // Little moon on the forehead.
    final moon = Path()
      ..addOval(Rect.fromCircle(center: const Offset(50, 25), radius: 5))
      ..fillType = PathFillType.evenOdd;
    final cut = Path()..addOval(Rect.fromCircle(center: const Offset(52.5, 23.5), radius: 4.3));
    c.drawPath(Path.combine(PathOperation.difference, moon, cut), _fill(_p.accent));
    final beak = Path()
      ..moveTo(45, 58)
      ..lineTo(55, 58)
      ..lineTo(50, 66)
      ..close();
    c.drawPath(beak, _fill(const Color(0xFFFFA62B)));
  }

  void _owlEyes(Canvas c, bool blinking, bool happy) {
    for (final x in [36.0, 64.0]) {
      c.drawCircle(Offset(x, 46), 13, _fill(Colors.white));
      c.drawCircle(
        Offset(x, 46),
        13,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..color = _p.accent,
      );
      if (blinking || happy) {
        final lid = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = _ink;
        if (happy && !blinking) {
          c.drawArc(Rect.fromCenter(center: Offset(x, 49), width: 13, height: 11), pi * 1.1, pi * 0.8, false, lid);
        } else {
          c.drawLine(Offset(x - 6, 47), Offset(x + 6, 47), lid);
        }
      } else {
        c.drawCircle(Offset(x, 47), 6.4, _fill(_ink));
        c.drawCircle(Offset(x - 2, 44.5), 2.2, _fill(Colors.white));
      }
    }
  }

  void _bunnyHead(Canvas c, double t) {
    for (final side in [-1.0, 1.0]) {
      c.save();
      c.translate(50 + side * 13, 20);
      c.rotate(side * (0.18 + sin(t * 1.6 + side) * 0.04));
      final ear = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -16), width: 16, height: 42), const Radius.circular(9));
      c.drawRRect(ear, _fill(_p.fur));
      c.drawRRect(ear, _outline());
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, -15), width: 8, height: 32), const Radius.circular(5)),
        _fill(_p.accent),
      );
      c.restore();
    }
    _shape(c, _oval(50, 50, 68, 60), _p.fur);
    // Artist's beret.
    c.save();
    c.translate(36, 22);
    c.rotate(-0.35);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: 32, height: 13), _fill(const Color(0xFFFF5A5F)));
    c.drawCircle(const Offset(0, -7), 2.4, _fill(const Color(0xFFFF5A5F)));
    c.restore();
    final nose = Path()
      ..moveTo(46, 56)
      ..lineTo(54, 56)
      ..lineTo(50, 60)
      ..close();
    c.drawPath(nose, _fill(_p.accent));
    final whisker = Paint()
      ..strokeWidth = 1.1
      ..color = _p.dark.withValues(alpha: 0.45);
    for (final side in [-1.0, 1.0]) {
      c.drawLine(Offset(50 + side * 12, 60), Offset(50 + side * 26, 57), whisker);
      c.drawLine(Offset(50 + side * 12, 62), Offset(50 + side * 26, 64), whisker);
    }
  }

  void _eyes(Canvas c, Offset l, Offset r, bool blinking, bool happy) {
    final lineP = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..color = _ink;
    for (final e in [l, r]) {
      if (happy && !blinking) {
        c.drawArc(Rect.fromCenter(center: e + const Offset(0, 2), width: 11, height: 10), pi * 1.1, pi * 0.8, false, lineP);
      } else if (blinking) {
        c.drawLine(e + const Offset(-4.5, 0), e + const Offset(4.5, 0), lineP);
      } else {
        c.drawOval(Rect.fromCenter(center: e, width: 9.5, height: 11.5), _fill(_ink));
        c.drawCircle(e + const Offset(-1.6, -2.6), 2.2, _fill(Colors.white));
        c.drawCircle(e + const Offset(1.8, 2.4), 1, _fill(Colors.white.withValues(alpha: 0.7)));
      }
    }
  }

  void _mouthAt(Canvas c, Offset m, double open) {
    if (mood == CritterMood.cheer || (mood == CritterMood.happy && open == 0)) {
      final big = mood == CritterMood.cheer;
      final w = big ? 16.0 : 12.0;
      final h = big ? 12.0 : 7.0;
      final path = Path()
        ..moveTo(m.dx - w / 2, m.dy)
        ..quadraticBezierTo(m.dx, m.dy + h * 1.6, m.dx + w / 2, m.dy)
        ..close();
      c.drawPath(path, _fill(_mouth));
      c.save();
      c.clipPath(path);
      c.drawOval(Rect.fromCenter(center: Offset(m.dx, m.dy + h * 0.95), width: w * 0.7, height: h * 0.7), _fill(_tongue));
      c.restore();
      return;
    }
    if (open > 0) {
      final rect = Rect.fromCenter(center: m + Offset(0, 1 + open * 2), width: 9 + open * 2, height: 3 + open * 8);
      c.drawOval(rect, _fill(_mouth));
      c.save();
      c.clipPath(Path()..addOval(rect));
      c.drawOval(Rect.fromCenter(center: Offset(m.dx, rect.bottom - 1), width: rect.width * 0.7, height: rect.height * 0.5), _fill(_tongue));
      c.restore();
      return;
    }
    final smile = Path()
      ..moveTo(m.dx - 6, m.dy)
      ..quadraticBezierTo(m.dx, m.dy + 6, m.dx + 6, m.dy);
    c.drawPath(
      smile,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = _ink,
    );
    if (id == CharacterId.coco) {
      c.drawRect(Rect.fromLTWH(m.dx - 3, m.dy + 2.5, 2.8, 3.2), _fill(Colors.white));
      c.drawRect(Rect.fromLTWH(m.dx + 0.2, m.dy + 2.5, 2.8, 3.2), _fill(Colors.white));
    }
  }

  @override
  bool shouldRepaint(covariant CritterPainter old) =>
      old.id != id || old.talking != talking || old.mood != mood || old.wave != wave || old.showBody != showBody;
}

/// Plays a talking animation for roughly as long as [text] takes to say.
class TalkingController extends ValueNotifier<bool> {
  TalkingController() : super(false);
  Timer? _timer;

  void talkFor(String text) {
    _timer?.cancel();
    value = true;
    final ms = (text.split(' ').length * 380).clamp(600, 9000);
    _timer = Timer(Duration(milliseconds: ms), () => value = false);
  }

  void stop() {
    _timer?.cancel();
    value = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
