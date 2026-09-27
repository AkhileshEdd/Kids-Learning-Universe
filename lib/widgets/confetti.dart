import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/theme.dart';

/// Call [burst] to throw confetti from a point (fractions of the area).
class ConfettiController extends ChangeNotifier {
  Offset origin = const Offset(0.5, 0.5);
  int count = 60;
  int _shots = 0;
  int get shots => _shots;

  void burst({Offset origin = const Offset(0.5, 0.5), int count = 60}) {
    this.origin = origin;
    this.count = count;
    _shots++;
    notifyListeners();
  }
}

class ConfettiLayer extends StatefulWidget {
  const ConfettiLayer({super.key, required this.controller});
  final ConfettiController controller;

  @override
  State<ConfettiLayer> createState() => _ConfettiLayerState();
}

class _Piece {
  _Piece(this.pos, this.vel, this.color, this.size, this.spin, this.shape);
  Offset pos;
  Offset vel;
  final Color color;
  final double size;
  final double spin;
  final int shape;
  double angle = 0;
  double life = 0;
}

class _ConfettiLayerState extends State<ConfettiLayer> with SingleTickerProviderStateMixin {
  final List<_Piece> _pieces = [];
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final _rng = Random();
  final _tick = ValueNotifier<int>(0);
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.controller.addListener(_spawn);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_spawn);
    _ticker.dispose();
    _tick.dispose();
    super.dispose();
  }

  void _spawn() {
    if (_size == Size.zero) return;
    final o = Offset(widget.controller.origin.dx * _size.width, widget.controller.origin.dy * _size.height);
    for (var i = 0; i < widget.controller.count; i++) {
      final a = -pi / 2 + (_rng.nextDouble() - 0.5) * pi * 1.3;
      final speed = 380 + _rng.nextDouble() * 520;
      _pieces.add(_Piece(
        o,
        Offset(cos(a), sin(a)) * speed,
        AppColors.playful[_rng.nextInt(AppColors.playful.length)],
        6 + _rng.nextDouble() * 7,
        (_rng.nextDouble() - 0.5) * 12,
        _rng.nextInt(3),
      ));
    }
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero ? 0.016 : (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    for (final p in _pieces) {
      p.vel = Offset(p.vel.dx * (1 - 1.2 * dt), p.vel.dy + 900 * dt);
      p.pos += p.vel * dt;
      p.angle += p.spin * dt;
      p.life += dt;
    }
    _pieces.removeWhere((p) => p.life > 2.6 || p.pos.dy > _size.height + 40);
    if (_pieces.isEmpty) _ticker.stop();
    _tick.value++;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return CustomPaint(size: _size, painter: _ConfettiPainter(_pieces, _tick));
        },
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, Listenable repaint) : super(repaint: repaint);
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in pieces) {
      paint.color = p.color.withValues(alpha: (1 - (p.life - 1.8).clamp(0, 0.8) / 0.8));
      canvas.save();
      canvas.translate(p.pos.dx, p.pos.dy);
      canvas.rotate(p.angle);
      switch (p.shape) {
        case 0:
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6), paint);
        case 1:
          canvas.drawCircle(Offset.zero, p.size * 0.42, paint);
        default:
          final path = Path()
            ..moveTo(0, -p.size * 0.6)
            ..lineTo(p.size * 0.5, p.size * 0.4)
            ..lineTo(-p.size * 0.5, p.size * 0.4)
            ..close();
          canvas.drawPath(path, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
