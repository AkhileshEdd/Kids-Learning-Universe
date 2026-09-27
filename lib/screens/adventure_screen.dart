import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/activities.dart';
import '../content/books.dart';
import '../content/characters.dart';
import '../core/music_route.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../premium/premium_service.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import '../widgets/critter.dart';
import '../widgets/space_background.dart';
import 'activity_launcher.dart';
import 'home_screen.dart' show stepEmoji, stepTitle;

/// Today's Adventure: a short path through reading, math, thinking and a book.
class AdventureScreen extends StatefulWidget {
  const AdventureScreen({super.key});

  @override
  State<AdventureScreen> createState() => _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> with MusicAware {
  @override
  bool get wantsMusic => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      final adv = state.adventureFor(state.active!, premium: context.read<PremiumService>().isPremium);
      context.read<SpeechService>().sayNow(adv.complete
          ? 'You finished all of today’s adventure! Come back tomorrow for a new one!'
          : "Let's go on today's adventure! Tap the glowing stop to start.");
    });
  }

  void _open(String step) {
    if (step.startsWith('book:')) {
      final book = bookById(step.substring(5));
      if (book != null) openBook(context, book);
    } else {
      final a = activityById(step);
      if (a != null) openActivity(context, a);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final premium = context.watch<PremiumService>().isPremium;
    final p = state.active!;
    final adv = state.adventureFor(p, premium: premium);
    final nextIndex = adv.steps.indexWhere((s) => !adv.done.contains(s));
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    RoundButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop(), semanticLabel: 'Back'),
                    const SizedBox(width: 12),
                    const EmojiText('🚀', size: 30),
                    const SizedBox(width: 8),
                    Text("Today's Adventure", style: KidText.display(28, color: Colors.white)),
                    const Spacer(),
                    StarPill(stars: p.stars, dark: true),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final count = adv.steps.length + 1;
                    final stationSize = (c.maxWidth / count * 0.62).clamp(70.0, 120.0);
                    return Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _PathPainter(count, adv.done.length))),
                        Row(
                          children: [
                            for (var i = 0; i < count; i++)
                              Expanded(
                                child: Align(
                                  alignment: Alignment(0, i.isEven ? -0.25 : 0.35),
                                  child: i < adv.steps.length
                                      ? _Station(
                                          emoji: stepEmoji(adv.steps[i]),
                                          title: stepTitle(adv.steps[i]),
                                          color: _stepColor(adv.steps[i]),
                                          size: stationSize,
                                          done: adv.done.contains(adv.steps[i]),
                                          current: i == nextIndex,
                                          onTap: () => _open(adv.steps[i]),
                                        )
                                      : _Trophy(size: stationSize, won: adv.complete),
                                ),
                              ),
                          ],
                        ),
                        if (nextIndex >= 0)
                          Positioned(
                            left: 8,
                            bottom: 4,
                            child: Critter(id: CharacterId.cosmo, size: 90, wave: true),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _stepColor(String step) {
    if (step.startsWith('book:')) return AppColors.stories;
    return activityById(step)?.subjectInfo.color ?? AppColors.adventure;
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.count, this.done);
  final int count;
  final int done;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (var i = 0; i < count; i++)
        Offset(size.width * (i + 0.5) / count, size.height * (i.isEven ? 0.375 : 0.675)),
    ];
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final paint = Paint()
        ..color = i < done ? AppColors.star : Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;
      const dashes = 14;
      for (var d = 0; d < dashes; d += 2) {
        final p1 = Offset.lerp(a, b, d / dashes)!;
        final p2 = Offset.lerp(a, b, (d + 1) / dashes)!;
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.count != count || old.done != done;
}

class _Station extends StatelessWidget {
  const _Station({
    required this.emoji,
    required this.title,
    required this.color,
    required this.size,
    required this.done,
    required this.current,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final Color color;
  final double size;
  final bool done;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final circle = BubblyButton(
      onTap: onTap,
      color: done ? AppColors.success : color,
      width: size,
      height: size,
      radius: size / 2,
      padding: EdgeInsets.zero,
      borderColor: current ? Colors.white : null,
      semanticLabel: title,
      child: done ? Icon(Icons.check_rounded, color: Colors.white, size: size * 0.6) : EmojiText(emoji, size: size * 0.5),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        current ? Floating(distance: 6, child: circle) : circle,
        const SizedBox(height: 6),
        SizedBox(
          width: size * 1.5,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: KidText.display(15, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _Trophy extends StatelessWidget {
  const _Trophy({required this.size, required this.won});
  final double size;
  final bool won;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: won ? 1 : 0.4,
          child: won
              ? Floating(child: EmojiText('🏆', size: size * 0.8))
              : EmojiText('🏆', size: size * 0.7),
        ),
        Text(won ? 'You did it!' : '+10 ⭐', style: KidText.display(16, color: Colors.white)),
      ],
    );
  }
}
