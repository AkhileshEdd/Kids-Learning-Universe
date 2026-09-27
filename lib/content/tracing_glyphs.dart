import 'dart:math';
import 'dart:ui';

/// Stroke paths for handwriting practice, in a 100 x 100 box
/// (x to the right, y down). Each glyph is a list of strokes in the order a
/// child should write them.
class Glyph {
  const Glyph(this.label, this.strokes, {this.spoken});
  final String label;
  final List<Path> strokes;
  final String? spoken;
}

class _Pen {
  final Path path = Path();
  bool _started = false;

  _Pen m(double x, double y) {
    path.moveTo(x, y);
    _started = true;
    return this;
  }

  _Pen l(double x, double y) {
    if (!_started) return m(x, y);
    path.lineTo(x, y);
    return this;
  }

  _Pen q(double cx, double cy, double x, double y) {
    path.quadraticBezierTo(cx, cy, x, y);
    return this;
  }

  /// Elliptical arc. Angles in degrees; 0 = right, 90 = down (clockwise).
  _Pen a(double cx, double cy, double rx, double ry, double startDeg, double sweepDeg) {
    final s = startDeg * pi / 180;
    final start = Offset(cx + rx * cos(s), cy + ry * sin(s));
    if (!_started) {
      m(start.dx, start.dy);
    } else {
      path.lineTo(start.dx, start.dy);
    }
    // Split long sweeps: a single 360° arcTo can collapse to nothing.
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    final pieces = (sweepDeg.abs() / 90).ceil();
    final step = sweepDeg / pieces;
    for (var i = 0; i < pieces; i++) {
      path.arcTo(rect, (startDeg + step * i) * pi / 180, step * pi / 180, false);
    }
    return this;
  }
}

_Pen _p() => _Pen();
Path _line(List<double> pts) {
  final pen = _p();
  for (var i = 0; i < pts.length; i += 2) {
    pen.l(pts[i], pts[i + 1]);
  }
  return pen.path;
}

List<Glyph> upperGlyphs() => [
      Glyph('A', [_line([50, 15, 20, 85]), _line([50, 15, 80, 85]), _line([32, 58, 68, 58])]),
      Glyph('B', [
        _line([28, 15, 28, 85]),
        _p().l(28, 15).l(52, 15).a(52, 32.5, 18, 17.5, -90, 180).l(28, 50).path,
        _p().l(28, 50).l(55, 50).a(55, 67.5, 19, 17.5, -90, 180).l(28, 85).path,
      ]),
      Glyph('C', [_p().a(52, 50, 30, 35, -45, -270).path]),
      Glyph('D', [_line([28, 15, 28, 85]), _p().l(28, 15).l(42, 15).a(42, 50, 34, 35, -90, 180).l(28, 85).path]),
      Glyph('E', [_line([30, 15, 30, 85]), _line([30, 15, 72, 15]), _line([30, 50, 64, 50]), _line([30, 85, 72, 85])]),
      Glyph('F', [_line([30, 15, 30, 85]), _line([30, 15, 72, 15]), _line([30, 50, 64, 50])]),
      Glyph('G', [_p().a(52, 50, 30, 35, -45, -315).path, _line([60, 50, 82, 50])]),
      Glyph('H', [_line([25, 15, 25, 85]), _line([75, 15, 75, 85]), _line([25, 50, 75, 50])]),
      Glyph('I', [_line([50, 15, 50, 85]), _line([32, 15, 68, 15]), _line([32, 85, 68, 85])]),
      Glyph('J', [_p().l(64, 15).l(64, 64).a(46, 64, 18, 21, 0, 180).path]),
      Glyph('K', [_line([30, 15, 30, 85]), _line([72, 15, 30, 56]), _line([43, 45, 74, 85])]),
      Glyph('L', [_line([32, 15, 32, 85, 72, 85])]),
      Glyph('M', [_line([22, 85, 22, 15]), _line([22, 15, 50, 60, 78, 15, 78, 85])]),
      Glyph('N', [_line([27, 85, 27, 15]), _line([27, 15, 73, 85, 73, 15])]),
      Glyph('O', [_p().a(50, 50, 30, 35, -90, -360).path]),
      Glyph('P', [_line([30, 15, 30, 85]), _p().l(30, 15).l(54, 15).a(54, 33, 18, 18, -90, 180).l(30, 51).path]),
      Glyph('Q', [_p().a(50, 50, 30, 35, -90, -360).path, _line([56, 66, 78, 90])]),
      Glyph('R', [
        _line([30, 15, 30, 85]),
        _p().l(30, 15).l(54, 15).a(54, 33, 18, 18, -90, 180).l(30, 51).path,
        _line([48, 51, 74, 85]),
      ]),
      Glyph('S', [_p().a(50, 32, 21, 17, -20, -250).a(50, 67, 23, 18, -90, 250).path]),
      Glyph('T', [_line([20, 15, 80, 15]), _line([50, 15, 50, 85])]),
      Glyph('U', [_p().l(25, 15).l(25, 60).a(50, 60, 25, 25, 180, -180).l(75, 15).path]),
      Glyph('V', [_line([20, 15, 50, 85, 80, 15])]),
      Glyph('W', [_line([14, 15, 31, 85, 50, 36, 69, 85, 86, 15])]),
      Glyph('X', [_line([25, 15, 75, 85]), _line([75, 15, 25, 85])]),
      Glyph('Y', [_line([25, 15, 50, 50]), _line([75, 15, 50, 50, 50, 85])]),
      Glyph('Z', [_line([25, 15, 75, 15, 25, 85, 75, 85])]),
    ];

List<Glyph> lowerGlyphs() => [
      Glyph('a', [_p().a(48, 58.5, 17, 16.5, -20, -340).path, _line([65, 42, 65, 75])]),
      Glyph('b', [_line([32, 12, 32, 75]), _p().a(49, 58.5, 17, 16.5, 180, 360).path]),
      Glyph('c', [_p().a(52, 58.5, 17, 16.5, -40, -280).path]),
      Glyph('d', [_p().a(48, 58.5, 17, 16.5, -20, -340).path, _line([65, 12, 65, 75])]),
      Glyph('e', [_p().l(32, 58.5).l(68, 58.5).a(50, 58.5, 18, 16.5, 0, -300).path]),
      Glyph('f', [_p().a(60, 24, 12, 12, -30, -150).l(48, 75).path, _line([34, 42, 64, 42])]),
      Glyph('g', [_p().a(48, 58.5, 17, 16.5, -20, -340).path, _p().l(65, 42).l(65, 82).a(50, 82, 15, 14, 0, 160).path]),
      Glyph('h', [_line([32, 12, 32, 75]), _p().a(49, 55, 17, 13, 180, 180).l(66, 75).path]),
      Glyph('i', [_line([50, 42, 50, 75]), _line([50, 25, 50, 28])]),
      Glyph('j', [_p().l(56, 42).l(56, 84).a(42, 84, 14, 14, 0, 180).path, _line([56, 25, 56, 28])]),
      Glyph('k', [_line([32, 12, 32, 75]), _line([64, 42, 32, 62]), _line([43, 55, 66, 75])]),
      Glyph('l', [_line([50, 12, 50, 75])]),
      Glyph('m', [
        _line([22, 42, 22, 75]),
        _p().a(34, 55, 12, 12, 180, 180).l(46, 75).path,
        _p().a(58, 55, 12, 12, 180, 180).l(70, 75).path,
      ]),
      Glyph('n', [_line([30, 42, 30, 75]), _p().a(48, 56, 18, 14, 180, 180).l(66, 75).path]),
      Glyph('o', [_p().a(50, 58.5, 18, 16.5, -90, -360).path]),
      Glyph('p', [_line([32, 42, 32, 98]), _p().a(49, 58.5, 17, 16.5, 180, 360).path]),
      Glyph('q', [_p().a(48, 58.5, 17, 16.5, -20, -340).path, _line([65, 42, 65, 98])]),
      Glyph('r', [_line([36, 42, 36, 75]), _p().a(52, 56, 16, 12, 180, 120).path]),
      Glyph('s', [_p().a(50, 50, 13, 8.5, -20, -250).a(50, 67, 14, 8.5, -90, 250).path]),
      Glyph('t', [_line([48, 20, 48, 75]), _line([34, 42, 64, 42])]),
      Glyph('u', [_p().l(32, 42).l(32, 60).a(48, 60, 16, 15, 180, -180).path, _line([64, 42, 64, 75])]),
      Glyph('v', [_line([30, 42, 50, 75, 70, 42])]),
      Glyph('w', [_line([22, 42, 34, 75, 50, 50, 66, 75, 78, 42])]),
      Glyph('x', [_line([32, 42, 68, 75]), _line([68, 42, 32, 75])]),
      Glyph('y', [_line([32, 42, 50, 72]), _line([68, 42, 40, 98])]),
      Glyph('z', [_line([32, 42, 68, 42, 32, 75, 68, 75])]),
    ];

const _digitWords = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine'];

List<Glyph> digitGlyphs() => [
      Glyph('0', [_p().a(50, 50, 25, 35, -90, -360).path], spoken: _digitWords[0]),
      Glyph('1', [_line([36, 27, 52, 15, 52, 85])], spoken: _digitWords[1]),
      Glyph('2', [_p().a(50, 34, 20, 19, 200, 190).l(28, 85).l(74, 85).path], spoken: _digitWords[2]),
      Glyph('3', [_p().a(48, 32, 20, 17, 200, 250).a(48, 67, 22, 18, 270, 250).path], spoken: _digitWords[3]),
      Glyph('4', [_line([56, 15, 22, 62, 78, 62]), _line([60, 15, 60, 85])], spoken: _digitWords[4]),
      Glyph('5', [_p().l(34, 15).l(33, 46).a(49, 63, 21, 20, 235, 225).path, _line([34, 15, 70, 15])], spoken: _digitWords[5]),
      Glyph('6', [_p().m(66, 18).q(32, 22, 31, 66).a(50, 66, 19, 19, 180, -360).path], spoken: _digitWords[6]),
      Glyph('7', [_line([25, 15, 75, 15, 40, 85])], spoken: _digitWords[7]),
      Glyph('8', [_p().a(50, 32, 18, 17, -20, -250).a(50, 67, 20, 18, -90, 250).l(67, 26).path], spoken: _digitWords[8]),
      Glyph('9', [_p().a(50, 34, 18, 18, 0, -360).l(66, 85).path], spoken: _digitWords[9]),
    ];

List<Glyph> shapeGlyphs() {
  Path star() {
    final p = Path();
    for (var i = 0; i <= 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final r = i.isEven ? 36.0 : 15.0;
      final pt = Offset(50 + cos(a) * r, 54 + sin(a) * r);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p;
  }

  return [
    Glyph('circle', [_p().a(50, 50, 33, 33, -90, 360).path]),
    Glyph('square', [_line([20, 20, 80, 20, 80, 80, 20, 80, 20, 20])]),
    Glyph('triangle', [_line([50, 14, 84, 80, 16, 80, 50, 14])]),
    Glyph('rectangle', [_line([12, 28, 88, 28, 88, 72, 12, 72, 12, 28])]),
    Glyph('star', [star()]),
    Glyph('heart', [
      _p().m(50, 34).q(50, 12, 30, 16).q(10, 22, 18, 44).l(50, 82).path,
      _p().m(50, 34).q(50, 12, 70, 16).q(90, 22, 82, 44).l(50, 82).path,
    ]),
    Glyph('diamond', [_line([50, 12, 78, 50, 50, 88, 22, 50, 50, 12])]),
  ];
}

/// Evenly spaced points along a stroke (in glyph units).
List<Offset> samplePath(Path path, {double spacing = 2.5}) {
  final points = <Offset>[];
  for (final metric in path.computeMetrics()) {
    final len = metric.length;
    if (len < 0.5) continue;
    final steps = max(2, (len / spacing).ceil());
    for (var i = 0; i <= steps; i++) {
      final t = metric.getTangentForOffset(len * i / steps);
      if (t != null) points.add(t.position);
    }
  }
  return points;
}
