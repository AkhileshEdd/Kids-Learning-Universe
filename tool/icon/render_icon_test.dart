// Renders the launcher icon artwork with the same painters the app uses.
//
//   flutter test tool/icon/render_icon_test.dart
//   python3 tool/icon/make_launcher_icons.py
//
// Outputs 1024 px PNGs to tool/icon/out/.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_universe/content/characters.dart';
import 'package:kids_learning_universe/widgets/critter.dart';

class _SpacePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E1356), Color(0xFF3B2A86), Color(0xFF6A3AA8)],
        ).createShader(rect),
    );
    void glow(Offset c, double r, Color color) => canvas.drawCircle(
          c,
          r,
          Paint()
            ..shader = RadialGradient(colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0)])
                .createShader(Rect.fromCircle(center: c, radius: r)),
        );
    glow(Offset(size.width * 0.15, size.height * 0.9), size.width * 0.6, const Color(0xFFFF6FB5));
    glow(Offset(size.width * 0.9, size.height * 0.1), size.width * 0.5, const Color(0xFF4FC3FF));
    final rng = Random(3);
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 40; i++) {
      final p = Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height);
      star.color = Colors.white.withValues(alpha: 0.5 + rng.nextDouble() * 0.5);
      canvas.drawCircle(p, 2 + rng.nextDouble() * 5, star);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _capture(WidgetTester tester, Widget child, String name) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(key: key, child: SizedBox(width: 1024, height: 1024, child: child)),
      ),
    ),
  );
  await tester.pump();
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  });
  final out = File('tool/icon/out/$name.png')..createSync(recursive: true);
  out.writeAsBytesSync(bytes!);
}

Widget _cosmo(double size) => Center(
      child: Padding(
        padding: EdgeInsets.only(top: size * 0.12),
        child: Critter(id: CharacterId.cosmo, size: size, showBody: false, animate: false),
      ),
    );

void main() {
  testWidgets('render launcher icon layers', (tester) async {
    tester.view.physicalSize = const Size(1024, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _capture(tester, CustomPaint(painter: _SpacePainter()), 'background');
    // Adaptive icons keep the important part inside the middle 66%.
    await _capture(tester, _cosmo(560), 'foreground');
    await _capture(
      tester,
      Stack(children: [Positioned.fill(child: CustomPaint(painter: _SpacePainter())), _cosmo(720)]),
      'full',
    );
    await _capture(tester, _cosmo(760), 'splash');
  });
}
