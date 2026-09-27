import 'dart:math';

import 'package:flutter/material.dart';

import '../content/subjects.dart';
import '../core/theme.dart';

/// Animated night sky: gradient, nebula glow, twinkling and shooting stars.
class SpaceBackground extends StatefulWidget {
  const SpaceBackground({super.key, required this.child, this.starCount = 90});

  final Widget child;
  final int starCount;

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    final rng = Random(21);
    _stars = List.generate(
      widget.starCount,
      (_) => _Star(
        Offset(rng.nextDouble(), rng.nextDouble()),
        0.6 + rng.nextDouble() * 1.8,
        rng.nextDouble(),
        rng.nextDouble() < 0.12,
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.spaceTop, AppColors.spaceMid, AppColors.spaceBottom],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _SkyPainter(_c, _stars)),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Star {
  _Star(this.pos, this.radius, this.phase, this.sparkle);
  final Offset pos;
  final double radius;
  final double phase;
  final bool sparkle;
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.anim, this.stars) : super(repaint: anim);

  final Animation<double> anim;
  final List<_Star> stars;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    // Nebula glows.
    void glow(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    glow(Offset(size.width * 0.18, size.height * 0.85), size.height * 0.7, AppColors.nebulaPink);
    glow(Offset(size.width * 0.85, size.height * 0.2), size.height * 0.6, AppColors.nebulaBlue);
    glow(Offset(size.width * 0.55, size.height * 1.05), size.height * 0.5, const Color(0xFF9B5CFF));

    final paint = Paint();
    for (final s in stars) {
      final twinkle = 0.45 + 0.55 * (sin((t * 6 + s.phase) * 2 * pi) * 0.5 + 0.5);
      final p = Offset(s.pos.dx * size.width, s.pos.dy * size.height);
      paint.color = Colors.white.withValues(alpha: twinkle);
      if (s.sparkle) {
        final r = s.radius * 2.6 * twinkle;
        final path = Path()
          ..moveTo(p.dx, p.dy - r)
          ..quadraticBezierTo(p.dx, p.dy, p.dx + r, p.dy)
          ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy + r)
          ..quadraticBezierTo(p.dx, p.dy, p.dx - r, p.dy)
          ..quadraticBezierTo(p.dx, p.dy, p.dx, p.dy - r);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawCircle(p, s.radius, paint);
      }
    }

    // A shooting star every few seconds.
    final cycle = (t * 3) % 1.0;
    if (cycle < 0.18) {
      final k = cycle / 0.18;
      final start = Offset(size.width * (0.2 + 0.5 * ((t * 3).floor() % 3) / 2), size.height * 0.08);
      final head = start + Offset(size.width * 0.3 * k, size.height * 0.22 * k);
      final tail = head - Offset(size.width * 0.08, size.height * 0.06);
      canvas.drawLine(
        tail,
        head,
        Paint()
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 1 - k)])
              .createShader(Rect.fromPoints(tail, head)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => false;
}

/// A glossy painted planet for a subject.
class PlanetView extends StatelessWidget {
  const PlanetView({super.key, required this.color, required this.style, this.size = 120, this.emoji});

  final Color color;
  final PlanetStyle style;
  final double size;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.5,
      height: size * 1.1,
      child: CustomPaint(
        painter: _PlanetPainter(color, style),
        child: emoji == null
            ? null
            : Center(
                child: Text(emoji!, style: KidText.emoji(size * 0.32)),
              ),
      ),
    );
  }
}

class _PlanetPainter extends CustomPainter {
  _PlanetPainter(this.color, this.style);
  final Color color;
  final PlanetStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.height / 2.2;
    final ringRect = Rect.fromCenter(center: c, width: r * 3.0, height: r * 0.8);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..color = Colors.white.withValues(alpha: 0.75);

    // Glow.
    canvas.drawCircle(
      c,
      r * 1.35,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r * 1.35)),
    );

    if (style == PlanetStyle.rings) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.25);
      canvas.translate(-c.dx, -c.dy);
      canvas.drawArc(ringRect, pi, pi, false, ringPaint);
      canvas.restore();
    }

    final sphere = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 1.05,
          colors: [color.lighten(0.2), color, color.darken(0.22)],
          stops: const [0, 0.55, 1],
        ).createShader(sphere),
    );

    canvas.save();
    canvas.clipPath(Path()..addOval(sphere));
    final detail = Paint()..color = color.darken(0.1).withValues(alpha: 0.55);
    final light = Paint()..color = Colors.white.withValues(alpha: 0.18);
    switch (style) {
      case PlanetStyle.stripes:
        for (var i = -2; i <= 2; i++) {
          final y = c.dy + i * r * 0.38;
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(c.dx, y), width: r * 2.2, height: r * 0.16), Radius.circular(r)),
            i.isEven ? detail : light,
          );
        }
      case PlanetStyle.craters:
      case PlanetStyle.moon:
        for (final (dx, dy, rr) in const [(-0.35, 0.3, 0.2), (0.35, -0.2, 0.14), (0.1, 0.55, 0.12), (0.45, 0.35, 0.09), (-0.2, -0.4, 0.1)]) {
          canvas.drawCircle(c + Offset(dx * r, dy * r), rr * r, detail);
          canvas.drawCircle(c + Offset(dx * r - rr * r * 0.2, dy * r - rr * r * 0.2), rr * r * 0.6, light);
        }
      case PlanetStyle.spots:
        for (final (dx, dy, rr) in const [(-0.4, -0.1, 0.22), (0.3, 0.3, 0.26), (0.25, -0.5, 0.14), (-0.1, 0.6, 0.12)]) {
          canvas.drawOval(Rect.fromCenter(center: c + Offset(dx * r, dy * r), width: rr * r * 2.4, height: rr * r * 1.7), detail);
        }
      case PlanetStyle.rings:
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, r * 0.3), width: r * 2.2, height: r * 0.2), Radius.circular(r)),
          light,
        );
    }
    canvas.restore();

    // Shine.
    canvas.drawOval(
      Rect.fromCenter(center: c + Offset(-r * 0.38, -r * 0.45), width: r * 0.55, height: r * 0.32),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );

    if (style == PlanetStyle.rings) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.25);
      canvas.translate(-c.dx, -c.dy);
      canvas.drawArc(ringRect, 0, pi, false, ringPaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PlanetPainter old) => old.color != color || old.style != style;
}
