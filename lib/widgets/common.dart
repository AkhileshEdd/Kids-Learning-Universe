import 'dart:math';

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Renders an emoji with the bundled color emoji font.
class EmojiText extends StatelessWidget {
  const EmojiText(this.emoji, {super.key, this.size = 40});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: KidText.emoji(size),
      textAlign: TextAlign.center,
      textScaler: TextScaler.noScaling,
    );
  }
}

/// ⭐ 123 pill used in top bars.
class StarPill extends StatelessWidget {
  const StarPill({super.key, required this.stars, this.dark = false});

  final int stars;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 5, 16, 5),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.14) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: dark ? Colors.white24 : const Color(0xFFFFE08A), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EmojiText('⭐', size: 24),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Text(
              '$stars',
              key: ValueKey(stars),
              style: KidText.display(22, color: dark ? Colors.white : AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

enum BubbleTail { left, bottom, none }

/// Comic-style speech bubble.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.child,
    this.tail = BubbleTail.left,
    this.color = Colors.white,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
  });

  final Widget child;
  final BubbleTail tail;
  final Color color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(color: color, tail: tail),
      child: Padding(
        padding: EdgeInsets.only(
          left: tail == BubbleTail.left ? 12 : 0,
          bottom: tail == BubbleTail.bottom ? 12 : 0,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.color, required this.tail});

  final Color color;
  final BubbleTail tail;

  @override
  void paint(Canvas canvas, Size size) {
    final left = tail == BubbleTail.left ? 12.0 : 0.0;
    final bottom = tail == BubbleTail.bottom ? 12.0 : 0.0;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 0, size.width - left, size.height - bottom),
      const Radius.circular(22),
    );
    final path = Path()..addRRect(body);
    if (tail == BubbleTail.left) {
      final cy = min(size.height * 0.5, 34.0);
      path
        ..moveTo(left + 2, cy - 9)
        ..lineTo(0, cy + 4)
        ..lineTo(left + 2, cy + 9)
        ..close();
    } else if (tail == BubbleTail.bottom) {
      final cx = size.width * 0.25;
      path
        ..moveTo(cx - 10, size.height - bottom - 2)
        ..lineTo(cx - 4, size.height)
        ..lineTo(cx + 10, size.height - bottom - 2)
        ..close();
    }
    canvas.drawShadow(path, Colors.black26, 3, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter old) => old.color != color || old.tail != tail;
}

/// Shakes its child horizontally whenever [trigger] changes.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        final dx = sin(t * pi * 6) * 12 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Pops its child in with a bouncy scale when first shown.
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 520)});

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Gently floats its child up and down forever.
class Floating extends StatefulWidget {
  const Floating({super.key, required this.child, this.distance = 6, this.period = const Duration(seconds: 3), this.phase = 0});

  final Widget child;
  final double distance;
  final Duration period;
  final double phase;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, sin((_c.value + widget.phase) * 2 * pi) * widget.distance),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Soft pastel background with floating bubbles, used on subject screens.
class PlayfulBackground extends StatelessWidget {
  const PlayfulBackground({super.key, required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.9)!, Color.lerp(color, Colors.white, 0.78)!],
        ),
      ),
      child: CustomPaint(
        painter: _DotsPainter(color),
        child: child,
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(4);
    final paint = Paint()..color = color.withValues(alpha: 0.08);
    for (var i = 0; i < 18; i++) {
      final r = 10.0 + rng.nextDouble() * 50;
      canvas.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter old) => old.color != color;
}

/// Small label chip.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.text, this.color = AppColors.stories, this.textColor = Colors.white, this.fontSize = 14});

  final String text;
  final Color color;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(30)),
      child: Text(text, style: KidText.display(fontSize, color: textColor, weight: FontWeight.w600)),
    );
  }
}

/// Premium lock badge.
class LockBadge extends StatelessWidget {
  const LockBadge({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD86B), AppColors.starDeep]),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Icon(Icons.lock_rounded, color: Colors.white, size: size * 0.55),
    );
  }
}
