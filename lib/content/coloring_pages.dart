import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

/// A picture made of tappable regions in a 100 x 100 box. The first region is
/// the background.
class ColoringPage {
  const ColoringPage(this.id, this.name, this.emoji, this.build, {this.premium = false});
  final String id;
  final String name;
  final String emoji;
  final List<Path> Function() build;
  final bool premium;
}

Path _rect(double x, double y, double w, double h) => Path()..addRect(Rect.fromLTWH(x, y, w, h));
Path _rrect(double x, double y, double w, double h, double r) =>
    Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)));
Path _circle(double cx, double cy, double r) => Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
Path _oval(double cx, double cy, double w, double h) => Path()..addOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: h));
Path _poly(List<double> p) {
  final path = Path()..moveTo(p[0], p[1]);
  for (var i = 2; i < p.length; i += 2) {
    path.lineTo(p[i], p[i + 1]);
  }
  return path..close();
}

Path _rotated(Path p, double cx, double cy, double degrees) {
  final a = degrees * pi / 180;
  final c = cos(a), s = sin(a);
  final m = Float64List.fromList([c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, cx - c * cx + s * cy, cy - s * cx - c * cy, 0, 1]);
  return p.transform(m);
}

final coloringPages = <ColoringPage>[
  ColoringPage('house', 'Happy House', '🏠', () => [
        _rect(0, 0, 100, 100),
        _rect(0, 80, 100, 20),
        _circle(84, 16, 9),
        _rect(58, 22, 8, 16),
        _rect(22, 46, 46, 34),
        _poly([16, 48, 45, 20, 74, 48]),
        _rrect(39, 60, 12, 20, 4),
        _rect(26, 54, 9, 9),
        _rect(55, 54, 9, 9),
        _rect(84, 60, 5, 20),
        _circle(86.5, 50, 11),
      ]),
  ColoringPage('fish', 'Silly Fish', '🐟', () => [
        _rect(0, 0, 100, 100),
        _poly([66, 50, 90, 32, 86, 50, 90, 68]),
        _poly([36, 36, 52, 20, 60, 36]),
        _oval(45, 50, 56, 36),
        _oval(46, 60, 12, 8),
        _circle(30, 45, 5),
        _circle(29, 44, 2.2),
        _circle(16, 26, 4),
        _circle(22, 14, 3),
        _rect(0, 90, 100, 10),
      ]),
  ColoringPage('rocket', 'Space Rocket', '🚀', () => [
        _rect(0, 0, 100, 100),
        _circle(18, 22, 9),
        _circle(82, 80, 6),
        _poly([44, 76, 50, 96, 56, 76]),
        _poly([40, 58, 28, 78, 40, 74]),
        _poly([60, 58, 72, 78, 60, 74]),
        _rrect(40, 28, 20, 48, 6),
        _poly([40, 30, 50, 8, 60, 30]),
        _circle(50, 42, 6),
        _rect(40, 62, 20, 4),
      ]),
  ColoringPage('flower', 'Sunny Flower', '🌻', () => [
        _rect(0, 0, 100, 100),
        _rect(0, 86, 100, 14),
        _rect(48.5, 46, 3, 38),
        _rotated(_oval(40, 66, 16, 7), 40, 66, -30),
        _rotated(_oval(60, 72, 16, 7), 60, 72, 30),
        for (var i = 0; i < 8; i++) _circle(50 + cos(i * pi / 4) * 14, 36 + sin(i * pi / 4) * 14, 8),
        _circle(50, 36, 10),
        _poly([36, 80, 64, 80, 60, 98, 40, 98]),
      ], premium: false),
  ColoringPage('butterfly', 'Butterfly', '🦋', () => [
        _rect(0, 0, 100, 100),
        _oval(32, 38, 30, 28),
        _oval(68, 38, 30, 28),
        _oval(35, 64, 22, 20),
        _oval(65, 64, 22, 20),
        _circle(30, 36, 6),
        _circle(70, 36, 6),
        _oval(50, 52, 7, 44),
        _circle(42, 22, 2.5),
        _circle(58, 22, 2.5),
      ], premium: true),
  ColoringPage('icecream', 'Ice Cream', '🍦', () => [
        _rect(0, 0, 100, 100),
        _poly([34, 52, 66, 52, 50, 94]),
        _circle(50, 44, 16),
        _circle(38, 32, 12),
        _circle(62, 32, 12),
        _circle(50, 22, 12),
        _circle(50, 8, 5),
      ], premium: true),
  ColoringPage('car', 'Zoom Car', '🚗', () => [
        _rect(0, 0, 100, 100),
        _rect(0, 76, 100, 24),
        _poly([30, 44, 38, 30, 64, 30, 74, 44]),
        _poly([36, 43, 42, 33, 50, 33, 50, 43]),
        _poly([53, 43, 53, 33, 62, 33, 69, 43]),
        _rrect(14, 44, 72, 22, 8),
        _circle(30, 68, 9),
        _circle(70, 68, 9),
        _circle(30, 68, 4),
        _circle(70, 68, 4),
        _rect(80, 50, 6, 5),
      ], premium: true),
  ColoringPage('cat', 'Kitty Cat', '🐱', () => [
        _rect(0, 0, 100, 100),
        _poly([22, 40, 26, 12, 44, 28]),
        _poly([78, 40, 74, 12, 56, 28]),
        _oval(50, 52, 64, 56),
        _oval(36, 48, 12, 14),
        _oval(64, 48, 12, 14),
        _poly([46, 60, 54, 60, 50, 65]),
        _oval(50, 90, 50, 16),
      ], premium: true),
];

/// Palette for the coloring book.
const coloringPalette = <Color>[
  Color(0xFFF03E3E), Color(0xFFFF922B), Color(0xFFFFD43B), Color(0xFF8CE99A), Color(0xFF37B24D),
  Color(0xFF74C0FC), Color(0xFF2F80ED), Color(0xFFB197FC), Color(0xFF8E44E8), Color(0xFFFF8FC8),
  Color(0xFF8B5A2B), Color(0xFFF5DEB3), Color(0xFF222222), Color(0xFFFFFFFF),
];
