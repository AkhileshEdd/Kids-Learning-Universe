import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../content/activities.dart';
import '../../content/coloring_pages.dart';
import '../../core/sound.dart';
import '../../core/speech.dart';
import '../../core/theme.dart';
import '../../models/grade.dart';
import '../../premium/premium_service.dart';
import '../../widgets/bubbly_button.dart';
import '../../widgets/common.dart';
import '../../widgets/game_scaffold.dart';
import '../activity_launcher.dart';

/// Tap-to-fill coloring book.
class ColoringScreen extends StatefulWidget {
  const ColoringScreen({super.key, required this.activity});
  final ActivityDef activity;

  @override
  State<ColoringScreen> createState() => _ColoringScreenState();
}

class _ColoringScreenState extends QuietState<ColoringScreen> {
  ColoringPage? _page;
  List<Path> _regions = const [];
  final Map<int, Color> _fills = {};
  Color _color = coloringPalette[0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SpeechService>().sayNow('Pick a picture to color!');
    });
  }

  void _open(ColoringPage page) {
    final premium = context.read<PremiumService>().isPremium;
    if (page.premium && !premium) {
      showPremiumLock(context, what: page.name);
      return;
    }
    setState(() {
      _page = page;
      _regions = page.build();
      _fills.clear();
    });
    context.read<SpeechService>().sayNow(widget.activity.intro);
  }

  void _tap(Offset units) {
    for (var i = _regions.length - 1; i >= 0; i--) {
      if (_regions[i].contains(units)) {
        context.read<SoundService>().play(Sfx.pop, volume: 0.7);
        setState(() => _fills[i] = _color);
        return;
      }
    }
  }

  void _done() {
    context.read<SpeechService>().stop();
    if (_fills.length < 3) {
      setState(() => _page = null);
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
    final page = _page;
    return GameScaffold(
      color: color,
      title: page?.name ?? widget.activity.title,
      actions: [
        if (page != null) ...[
          RoundButton(
            icon: Icons.grid_view_rounded,
            size: 44,
            semanticLabel: 'All pictures',
            onTap: () => setState(() => _page = null),
          ),
          const SizedBox(width: 8),
          BubblyButton.label(label: 'Done', icon: Icons.check_rounded, color: AppColors.success, fontSize: 18, onTap: _done),
        ],
      ],
      child: page == null ? _picker(color) : _canvas(color),
    );
  }

  Widget _picker(Color color) {
    final premium = context.watch<PremiumService>().isPremium;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: coloringPages.length,
      itemBuilder: (context, i) {
        final p = coloringPages[i];
        return PopIn(
          delay: Duration(milliseconds: 50 * i),
          child: BubblyButton(
            onTap: () => _open(p),
            color: Colors.white,
            gradient: false,
            radius: 24,
            padding: const EdgeInsets.all(8),
            semanticLabel: p.name,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: CustomPaint(painter: _ColoringPainter(p.build(), const {})),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(p.name, style: KidText.display(15)),
                  ],
                ),
                if (p.premium && !premium) const Positioned(right: -4, top: -4, child: LockBadge()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _canvas(Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: LayoutBuilder(
        builder: (context, c) {
          final side = c.maxHeight;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: side,
                height: side,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 4))],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: GestureDetector(
                    onTapDown: (d) => _tap(d.localPosition / (side / 100)),
                    child: CustomPaint(painter: _ColoringPainter(_regions, Map.of(_fills))),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 170,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final col in coloringPalette)
                        GestureDetector(
                          onTap: () {
                            context.read<SoundService>().play(Sfx.tap);
                            setState(() => _color = col);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(color: _color == col ? AppColors.ink : Colors.white, width: _color == col ? 4 : 2),
                              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4)],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ColoringPainter extends CustomPainter {
  _ColoringPainter(this.regions, this.fills);
  final List<Path> regions;
  final Map<int, Color> fills;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.ink;
    for (var i = 0; i < regions.length; i++) {
      canvas.drawPath(regions[i], Paint()..color = fills[i] ?? Colors.white);
      if (i > 0) canvas.drawPath(regions[i], outline);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ColoringPainter old) => true;
}
