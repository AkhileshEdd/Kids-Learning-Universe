import 'dart:math';

import 'package:flutter/material.dart';

import '../content/books.dart';
import '../core/theme.dart';
import 'critter.dart';

/// Renders a storybook illustration: painted background + animated sprites.
class SceneView extends StatefulWidget {
  const SceneView({super.key, required this.scene, this.animate = true});

  final Scene scene;
  final bool animate;

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: CustomPaint(painter: SceneBackgroundPainter(widget.scene.bg))),
            for (final (i, s) in widget.scene.sprites.indexed) _sprite(s, i, size),
          ],
        );
      },
    );
  }

  Widget _sprite(Sprite s, int index, Size size) {
    final h = size.height * s.size;
    final Widget child = s.character != null
        ? Critter(id: s.character!, size: h / 1.25, animate: widget.animate)
        : Transform.flip(
            flipX: s.flip,
            child: Text(s.emoji!, style: KidText.emoji(h * 0.86)),
          );
    final w = s.character != null ? h / 1.25 : h;
    return Positioned(
      left: s.x * size.width - w / 2,
      top: s.y * size.height - h / 2,
      width: w,
      height: h,
      child: widget.animate && s.motion != SpriteMotion.none && s.character == null
          ? AnimatedBuilder(
              animation: _c,
              builder: (context, child) {
                final t = _c.value * 2 * pi + index * 1.3;
                switch (s.motion) {
                  case SpriteMotion.bob:
                    return Transform.translate(offset: Offset(0, sin(t * 2) * h * 0.04), child: child);
                  case SpriteMotion.sway:
                    return Transform.rotate(angle: sin(t * 2) * 0.08, alignment: Alignment.bottomCenter, child: child);
                  case SpriteMotion.drift:
                    return Transform.translate(offset: Offset(sin(t) * h * 0.12, cos(t * 2) * h * 0.05), child: child);
                  case SpriteMotion.pulse:
                    return Transform.scale(scale: 1 + sin(t * 3) * 0.06, child: child);
                  case SpriteMotion.spin:
                    return Transform.rotate(angle: _c.value * 2 * pi * 0.25, child: child);
                  case SpriteMotion.none:
                    return child!;
                }
              },
              child: FittedBox(child: child),
            )
          : FittedBox(child: child),
    );
  }
}

class SceneBackgroundPainter extends CustomPainter {
  SceneBackgroundPainter(this.bg);
  final SceneBg bg;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    List<Color> sky;
    switch (bg) {
      case SceneBg.space:
        sky = const [Color(0xFF0E0930), Color(0xFF2A1A6E)];
      case SceneBg.night:
        sky = const [Color(0xFF14124A), Color(0xFF3D2A86)];
      case SceneBg.sky:
      case SceneBg.meadow:
        sky = const [Color(0xFF7FD3FF), Color(0xFFD6F2FF)];
      case SceneBg.forest:
        sky = const [Color(0xFF9EE6C0), Color(0xFFE2FBE9)];
      case SceneBg.snow:
        sky = const [Color(0xFFBFE3FF), Color(0xFFF0F8FF)];
      case SceneBg.ocean:
        sky = const [Color(0xFF3FB6E8), Color(0xFF0B5E9E)];
      case SceneBg.beach:
        sky = const [Color(0xFF8ED8FF), Color(0xFFFFF1C9)];
      case SceneBg.indoor:
        sky = const [Color(0xFFFFE9C7), Color(0xFFFFD9A8)];
      case SceneBg.rain:
        sky = const [Color(0xFF8E9DB8), Color(0xFFC9D3E3)];
      case SceneBg.sunset:
        sky = const [Color(0xFFFF9A62), Color(0xFFFFD58A)];
    }
    canvas.drawRect(rect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(rect));

    final w = size.width, h = size.height;
    final rng = Random(bg.index + 3);
    switch (bg) {
      case SceneBg.space:
      case SceneBg.night:
        final star = Paint()..color = Colors.white.withValues(alpha: 0.85);
        for (var i = 0; i < 40; i++) {
          canvas.drawCircle(Offset(rng.nextDouble() * w, rng.nextDouble() * h * (bg == SceneBg.night ? 0.75 : 1)), 0.6 + rng.nextDouble() * 1.4, star);
        }
        if (bg == SceneBg.night) _hills(canvas, size, const Color(0xFF241A5C), const Color(0xFF2E2270));
      case SceneBg.sky:
        _clouds(canvas, size, rng);
        _hills(canvas, size, const Color(0xFF8BDB7A), const Color(0xFF6CC862));
      case SceneBg.meadow:
        _clouds(canvas, size, rng);
        _hills(canvas, size, const Color(0xFF9BE58A), const Color(0xFF6CC862));
        final flower = Paint();
        for (var i = 0; i < 10; i++) {
          flower.color = AppColors.playful[i % AppColors.playful.length].withValues(alpha: 0.8);
          canvas.drawCircle(Offset(rng.nextDouble() * w, h * (0.84 + rng.nextDouble() * 0.12)), 3, flower);
        }
      case SceneBg.forest:
        final trunk = Paint()..color = const Color(0xFF9C6B3F);
        for (var i = 0; i < 6; i++) {
          final x = w * (0.05 + i * 0.18) + rng.nextDouble() * 20;
          final th = h * (0.35 + rng.nextDouble() * 0.2);
          canvas.drawRect(Rect.fromLTWH(x - 5, h * 0.8 - th * 0.4, 10, th * 0.4), trunk);
          canvas.drawCircle(Offset(x, h * 0.8 - th * 0.55), th * 0.28, Paint()..color = const Color(0xFF4CB86B).withValues(alpha: 0.85));
        }
        _hills(canvas, size, const Color(0xFF6CC862), const Color(0xFF52B052));
      case SceneBg.snow:
        final flake = Paint()..color = Colors.white;
        for (var i = 0; i < 30; i++) {
          canvas.drawCircle(Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.7), 1.5 + rng.nextDouble() * 2, flake);
        }
        _hills(canvas, size, Colors.white, const Color(0xFFE3F1FF));
      case SceneBg.ocean:
        final bubble = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.5);
        for (var i = 0; i < 14; i++) {
          canvas.drawCircle(Offset(rng.nextDouble() * w, rng.nextDouble() * h * 0.8), 3 + rng.nextDouble() * 6, bubble);
        }
        final sand = Path()
          ..moveTo(0, h * 0.9)
          ..quadraticBezierTo(w * 0.3, h * 0.84, w * 0.6, h * 0.9)
          ..quadraticBezierTo(w * 0.85, h * 0.95, w, h * 0.88)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(sand, Paint()..color = const Color(0xFFF3D9A4));
      case SceneBg.beach:
        final sea = Rect.fromLTWH(0, h * 0.5, w, h * 0.2);
        canvas.drawRect(sea, Paint()..color = const Color(0xFF3FB6E8));
        final sand = Path()
          ..moveTo(0, h * 0.66)
          ..quadraticBezierTo(w * 0.5, h * 0.6, w, h * 0.68)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();
        canvas.drawPath(sand, Paint()..color = const Color(0xFFF7DFA8));
        canvas.drawCircle(Offset(w * 0.86, h * 0.16), h * 0.08, Paint()..color = const Color(0xFFFFD43B));
      case SceneBg.indoor:
        final floor = Rect.fromLTWH(0, h * 0.72, w, h * 0.28);
        canvas.drawRect(floor, Paint()..color = const Color(0xFFC98F5A));
        final plank = Paint()
          ..color = const Color(0xFFB27A48)
          ..strokeWidth = 2;
        for (var i = 1; i < 6; i++) {
          canvas.drawLine(Offset(w * i / 6, h * 0.72), Offset(w * i / 6 - 20, h), plank);
        }
        final window = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.12, w * 0.22, h * 0.3), const Radius.circular(8));
        canvas.drawRRect(window, Paint()..color = const Color(0xFF9EDCFF));
        canvas.drawRRect(window, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..color = Colors.white);
      case SceneBg.rain:
        _clouds(canvas, size, rng, color: const Color(0xFFE1E6EE));
        final drop = Paint()
          ..color = const Color(0xFF5B8DEF).withValues(alpha: 0.6)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 40; i++) {
          final x = rng.nextDouble() * w;
          final y = rng.nextDouble() * h * 0.8;
          canvas.drawLine(Offset(x, y), Offset(x - 3, y + 9), drop);
        }
        _hills(canvas, size, const Color(0xFF7BC47A), const Color(0xFF5FAE62));
      case SceneBg.sunset:
        canvas.drawCircle(Offset(w * 0.8, h * 0.62), h * 0.18, Paint()..color = const Color(0xFFFFE08A));
        _hills(canvas, size, const Color(0xFFE77F5A), const Color(0xFFCF6446));
    }
  }

  void _clouds(Canvas canvas, Size size, Random rng, {Color color = Colors.white}) {
    final p = Paint()..color = color.withValues(alpha: 0.9);
    for (var i = 0; i < 3; i++) {
      final c = Offset(size.width * (0.15 + i * 0.33) + rng.nextDouble() * 30, size.height * (0.12 + rng.nextDouble() * 0.15));
      final r = size.height * 0.06;
      canvas.drawCircle(c, r, p);
      canvas.drawCircle(c + Offset(r, r * 0.3), r * 0.8, p);
      canvas.drawCircle(c + Offset(-r, r * 0.3), r * 0.75, p);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c + Offset(0, r * 0.55), width: r * 3.4, height: r * 0.9), Radius.circular(r)), p);
    }
  }

  void _hills(Canvas canvas, Size size, Color back, Color front) {
    final w = size.width, h = size.height;
    final b = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.25, h * 0.66, w * 0.5, h * 0.76)
      ..quadraticBezierTo(w * 0.78, h * 0.86, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(b, Paint()..color = back);
    final f = Path()
      ..moveTo(0, h * 0.88)
      ..quadraticBezierTo(w * 0.35, h * 0.78, w * 0.65, h * 0.86)
      ..quadraticBezierTo(w * 0.85, h * 0.92, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(f, Paint()..color = front);
  }

  @override
  bool shouldRepaint(covariant SceneBackgroundPainter old) => old.bg != bg;
}
