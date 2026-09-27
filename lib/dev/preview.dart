import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/activities.dart';
import '../content/books.dart';
import '../content/characters.dart';
import '../content/subjects.dart';
import '../models/grade.dart';
import '../premium/premium_service.dart';
import '../screens/adventure_screen.dart';
import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/parents/parent_zone_screen.dart';
import '../screens/parents/paywall_screen.dart';
import '../screens/profile_picker_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/reward_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/sticker_book_screen.dart';
import '../screens/story_reader_screen.dart';
import '../screens/subject_screen.dart';
import '../screens/games/abc_explorer_screen.dart';
import '../screens/games/bubble_pop_screen.dart';
import '../screens/games/coloring_screen.dart';
import '../screens/games/drawing_screen.dart';
import '../screens/games/memory_screen.dart';
import '../screens/games/tracing_screen.dart';
import '../screens/games/word_builder_screen.dart';
import '../state/app_state.dart';

/// Compile with `--dart-define=PREVIEW=true` to open any screen directly via
/// the URL, e.g. `?screen=quiz:count_objects&grade=kindergarten`. Used for
/// design reviews and screenshots; never enabled in store builds.
const kPreviewEnabled = bool.fromEnvironment('PREVIEW');

class PreviewLauncher extends StatefulWidget {
  const PreviewLauncher({super.key});

  @override
  State<PreviewLauncher> createState() => _PreviewLauncherState();
}

class _PreviewLauncherState extends State<PreviewLauncher> {
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  Future<void> _setup() async {
    final q = Uri.base.queryParameters;
    final state = context.read<AppState>();
    final premium = context.read<PremiumService>();
    final grade = Grade.values.firstWhere((g) => g.name == q['grade'], orElse: () => Grade.kindergarten);
    if (q['premium'] == '1' && !premium.isPremium && premium.products.isNotEmpty) {
      await premium.purchase(premium.products.first);
    }
    final target = q['screen'] ?? 'home';
    if (target != 'onboarding' && target != 'splash' && !state.hasProfiles) {
      final p = state.addProfile(name: q['name'] ?? 'Maya', avatar: '🦄', grade: grade);
      p.stars = 128;
      p.stickers.addAll(['🚀', '🪐', '🌙', '🐼', '🦁', '🍓', '🧁', '⭐']);
      p.booksRead.add('cosmo_trip');
      if (q['profiles'] == '2') state.addProfile(name: 'Leo', avatar: '🦖', grade: Grade.grade2);
      state.selectProfile(p);
    }
    final parts = target.split(':');
    final arg = parts.length > 1 ? parts[1] : '';
    final Widget screen = switch (parts.first) {
      'splash' => const SplashScreen(),
      'onboarding' => const OnboardingScreen(),
      'profiles' => const ProfilePickerScreen(),
      'subject' => SubjectScreen(subject: subjects[SubjectId.values.byName(arg)]!),
      'library' => const LibraryScreen(),
      'book' => StoryReaderScreen(book: bookById(arg)!),
      'stickers' => const StickerBookScreen(),
      'parents' => const ParentZoneScreen(),
      'paywall' => const PaywallScreen(),
      'adventure' => const AdventureScreen(),
      'reward' => RewardScreen(
          reward: const Reward(stars: 7, sticker: '🦄', levelUp: true),
          host: CharacterId.pip,
          correct: 5,
          total: 6,
        ),
      'activity' => _activityScreen(activityById(arg)!, grade),
      _ => const HomeScreen(),
    };
    if (mounted) setState(() => _screen = screen);
  }

  Widget _activityScreen(ActivityDef a, Grade g) => switch (a.kind) {
        ActivityKind.quiz => QuizScreen(activity: a, grade: g),
        ActivityKind.explorer => AbcExplorerScreen(activity: a),
        ActivityKind.tracing => TracingScreen(activity: a, grade: g),
        ActivityKind.memory => MemoryScreen(activity: a, grade: g),
        ActivityKind.wordBuilder => WordBuilderScreen(activity: a, grade: g),
        ActivityKind.bubblePop => BubblePopScreen(activity: a, grade: g),
        ActivityKind.drawing => DrawingScreen(activity: a),
        ActivityKind.coloring => ColoringScreen(activity: a),
      };

  @override
  Widget build(BuildContext context) {
    return _screen ?? const Scaffold(body: SizedBox());
  }
}
