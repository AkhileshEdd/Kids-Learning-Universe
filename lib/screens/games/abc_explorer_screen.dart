import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../content/activities.dart';
import '../../content/word_bank.dart';
import '../../core/sound.dart';
import '../../core/speech.dart';
import '../../core/theme.dart';
import '../../models/grade.dart';
import '../../widgets/bubbly_button.dart';
import '../../widgets/common.dart';
import '../../widgets/game_scaffold.dart';
import '../activity_launcher.dart';

/// Browse the alphabet: tap a letter to see and hear it with pictures.
class AbcExplorerScreen extends StatefulWidget {
  const AbcExplorerScreen({super.key, required this.activity});
  final ActivityDef activity;

  @override
  State<AbcExplorerScreen> createState() => _AbcExplorerScreenState();
}

class _AbcExplorerScreenState extends QuietState<AbcExplorerScreen> {
  int _selected = 0;
  final Set<int> _visited = {};
  static const _goal = 6;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SpeechService>().sayNow(widget.activity.intro);
    });
  }

  void _select(int i) {
    final info = alphabet[i];
    context.read<SoundService>().play(Sfx.pop, volume: 0.6);
    setState(() {
      _selected = i;
      _visited.add(i);
    });
    final line = info.note ?? '${info.upper}. ${info.upper} is for ${info.main.word}. ${info.main.word}!';
    context.read<SpeechService>().sayNow(line);
  }

  void _done() {
    context.read<SpeechService>().stop();
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
    final info = alphabet[_selected];
    return GameScaffold(
      color: color,
      title: widget.activity.title,
      progress: _visited.length.clamp(0, _goal),
      total: _goal,
      actions: [
        if (_visited.length >= _goal)
          PopIn(
            child: BubblyButton.label(label: 'Done', icon: Icons.check_rounded, color: AppColors.success, fontSize: 18, onTap: _done),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
        child: Row(
          children: [
            Expanded(
              flex: 6,
              child: LayoutBuilder(
                builder: (context, c) {
                  const cols = 7;
                  const rows = 4;
                  final cell = max(28.0, min((c.maxWidth - 6 * cols) / cols, (c.maxHeight - 6 * rows) / rows));
                  return Center(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < alphabet.length; i++)
                          BubblyButton(
                            onTap: () => _select(i),
                            color: i == _selected
                                ? color
                                : (_visited.contains(i) ? color.lighten(0.25) : AppColors.playful[i % AppColors.playful.length].lighten(0.28)),
                            width: cell,
                            height: cell - 4,
                            depth: 4,
                            radius: 14,
                            padding: EdgeInsets.zero,
                            sound: null,
                            semanticLabel: alphabet[i].upper,
                            child: Text(
                              '${alphabet[i].upper}${alphabet[i].lower}',
                              style: KidText.reading(cell * 0.4, color: i == _selected ? Colors.white : AppColors.ink),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 5,
              child: GestureDetector(
                onTap: () => _select(_selected),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                  child: Container(
                    key: ValueKey(_selected),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: color.withValues(alpha: 0.4), width: 4),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: FittedBox(
                            child: Text('${info.upper} ${info.lower}', style: KidText.reading(90, color: color)),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final w in info.words.take(3))
                              GestureDetector(
                                onTap: () => context.read<SpeechService>().sayNow(w.word),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Column(
                                    children: [
                                      EmojiText(w.emoji, size: 46),
                                      Text(w.word, style: KidText.reading(16)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
