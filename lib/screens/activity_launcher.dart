import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/activities.dart';
import '../content/books.dart';
import '../content/characters.dart';
import '../core/routes.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../models/grade.dart';
import '../premium/premium_service.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/critter.dart';
import 'games/abc_explorer_screen.dart';
import 'games/bubble_pop_screen.dart';
import 'games/coloring_screen.dart';
import 'games/drawing_screen.dart';
import 'games/memory_screen.dart';
import 'games/tracing_screen.dart';
import 'games/word_builder_screen.dart';
import 'parents/parental_gate.dart';
import 'parents/paywall_screen.dart';
import 'quiz_screen.dart';
import 'reward_screen.dart';
import 'story_reader_screen.dart';

/// Opens an activity, or shows the "ask a grown-up" lock for premium ones.
Future<void> openActivity(BuildContext context, ActivityDef activity, {Grade? grade}) async {
  final premium = context.read<PremiumService>().isPremium;
  if (activity.premium && !premium) {
    await showPremiumLock(context, what: activity.title);
    return;
  }
  final g = grade ?? context.read<AppState>().active?.grade ?? Grade.kindergarten;
  final Widget screen = switch (activity.kind) {
    ActivityKind.quiz => QuizScreen(activity: activity, grade: g),
    ActivityKind.explorer => AbcExplorerScreen(activity: activity),
    ActivityKind.tracing => TracingScreen(activity: activity, grade: g),
    ActivityKind.memory => MemoryScreen(activity: activity, grade: g),
    ActivityKind.wordBuilder => WordBuilderScreen(activity: activity, grade: g),
    ActivityKind.bubblePop => BubblePopScreen(activity: activity, grade: g),
    ActivityKind.drawing => DrawingScreen(activity: activity),
    ActivityKind.coloring => ColoringScreen(activity: activity),
  };
  await pushScreen(context, screen);
}

Future<void> openBook(BuildContext context, Book book) async {
  final premium = context.read<PremiumService>().isPremium;
  if (book.premium && !premium) {
    await showPremiumLock(context, what: book.title);
    return;
  }
  await pushScreen(context, StoryReaderScreen(book: book));
}

/// Records the result and swaps the game for the reward screen.
void finishActivity(
  BuildContext context, {
  required ActivityDef activity,
  required int firstTryCorrect,
  required int total,
  required int seconds,
  required Grade grade,
}) {
  final premium = context.read<PremiumService>().isPremium;
  final reward = context.read<AppState>().recordActivity(
        activity: activity,
        firstTryCorrect: firstTryCorrect,
        total: total,
        seconds: seconds,
        premium: premium,
      );
  replaceScreen(
    context,
    RewardScreen(
      reward: reward,
      correct: firstTryCorrect,
      total: total,
      host: activity.subjectInfo.host,
      onPlayAgain: (ctx) => openActivity(ctx, activity, grade: grade),
    ),
  );
}

/// Friendly lock shown to kids when they tap premium content.
Future<void> showPremiumLock(BuildContext context, {required String what}) async {
  context.read<SpeechService>().sayNow('This one is locked. Ask a grown-up to unlock it!');
  final unlock = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Row(
            children: [
              const Critter(id: CharacterId.cosmo, size: 110, mood: CritterMood.happy),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔒 Premium', style: KidText.display(26, color: AppColors.starDeep)),
                    const SizedBox(height: 6),
                    Text('“$what” is part of Premium. Ask a grown-up to unlock it!', style: KidText.body(17)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        BubblyButton.label(
                          label: 'Grown-ups',
                          icon: Icons.lock_open_rounded,
                          fontSize: 18,
                          color: AppColors.stories,
                          onTap: () => Navigator.of(context).pop(true),
                        ),
                        BubblyButton.label(
                          label: 'Maybe later',
                          fontSize: 18,
                          color: AppColors.locked,
                          onTap: () => Navigator.of(context).pop(false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (unlock == true && context.mounted && await showParentalGate(context) && context.mounted) {
    await pushScreen(context, PaywallScreen(reason: 'Unlock “$what” and everything else in Premium.'));
  }
}
