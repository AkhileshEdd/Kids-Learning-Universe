import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/music_route.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import 'bubbly_button.dart';
import 'common.dart';

/// Shared frame for all games: close button, title/progress and star count.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.color,
    required this.child,
    this.title,
    this.progress,
    this.total,
    this.stars,
    this.actions = const [],
    this.onClose,
  });

  final Color color;
  final Widget child;
  final String? title;

  /// Completed rounds (for the progress bar).
  final int? progress;
  final int? total;
  final int? stars;
  final List<Widget> actions;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PlayfulBackground(
        color: color,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
                child: Row(
                  children: [
                    RoundButton(
                      icon: Icons.close_rounded,
                      size: 48,
                      semanticLabel: 'Close',
                      onTap: () {
                        context.read<SpeechService>().stop();
                        (onClose ?? () => Navigator.of(context).maybePop())();
                      },
                    ),
                    const SizedBox(width: 12),
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(title!, style: KidText.display(22, color: color.darken(0.2))),
                      ),
                    Expanded(
                      child: progress != null && total != null
                          ? ProgressDots(done: progress!, total: total!, color: color)
                          : const SizedBox(),
                    ),
                    ...actions,
                    if (stars != null) ...[const SizedBox(width: 10), StarPill(stars: stars!)],
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressDots extends StatelessWidget {
  const ProgressDots({super.key, required this.done, required this.total, required this.color});
  final int done;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: i < done ? color : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Games don't play background music (so the narrator can be heard).
mixin QuietGame<T extends StatefulWidget> on State<T> {
  final DateTime startedAt = DateTime.now();
  int get elapsedSeconds => DateTime.now().difference(startedAt).inSeconds;
}

/// A State that turns music off while visible.
abstract class QuietState<T extends StatefulWidget> extends State<T> with MusicAware<T>, QuietGame<T> {
  @override
  bool get wantsMusic => false;
}
