import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_universe/app.dart';
import 'package:kids_learning_universe/content/activities.dart';
import 'package:kids_learning_universe/core/sound.dart';
import 'package:kids_learning_universe/core/speech.dart';
import 'package:kids_learning_universe/models/grade.dart';
import 'package:kids_learning_universe/premium/premium_service.dart';
import 'package:kids_learning_universe/screens/home_screen.dart';
import 'package:kids_learning_universe/screens/quiz_screen.dart';
import 'package:kids_learning_universe/state/app_state.dart';
import 'package:kids_learning_universe/widgets/bubbly_button.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(AppState, PremiumService)> _services() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final state = AppState(prefs);
  final premium = PremiumService(TestPurchaseBackend(prefs), prefs);
  return (state, premium);
}

Widget _wrap(AppState state, PremiumService premium, Widget child) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: premium),
        Provider.value(value: SpeechService()),
        Provider.value(value: SoundService()),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('first launch shows the welcome screen', (tester) async {
    tester.view.physicalSize = const Size(1830, 824);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (state, premium) = await _services();
    await tester.pumpWidget(KidsLearningUniverseApp(appState: state, premium: premium, speech: SpeechService(), sound: SoundService()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text("Let's get started"), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('home screen greets the child and shows the planets', (tester) async {
    tester.view.physicalSize = const Size(1830, 824);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (state, premium) = await _services();
    state.addProfile(name: 'Maya', avatar: '🦄', grade: Grade.kindergarten);
    await tester.pumpWidget(_wrap(state, premium, const HomeScreen()));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text("Today's Adventure"), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Math'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('every quiz activity renders its first question', (tester) async {
    tester.view.physicalSize = const Size(1830, 824);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (state, premium) = await _services();
    state.addProfile(name: 'Maya', avatar: '🦄', grade: Grade.grade1);
    for (final a in activities.where((a) => a.kind == ActivityKind.quiz)) {
      final grade = Grade.values.firstWhere(a.fitsGrade);
      await tester.pumpWidget(_wrap(state, premium, QuizScreen(activity: a, grade: grade)));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull, reason: a.id);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('a child can play a whole quiz and reach the reward screen', (tester) async {
    tester.view.physicalSize = const Size(1830, 824);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final (state, premium) = await _services();
    state.addProfile(name: 'Maya', avatar: '🦄', grade: Grade.preschool);
    final activity = activityById('colors')!;
    await tester.pumpWidget(_wrap(state, premium, QuizScreen(activity: activity, grade: Grade.preschool)));
    await tester.pump(const Duration(milliseconds: 800));

    for (var round = 0; round < Grade.preschool.rounds; round++) {
      final choices = find.descendant(of: find.byType(Wrap), matching: find.byType(BubblyButton));
      expect(choices, findsWidgets, reason: 'round $round');
      // Tapping every card: wrong ones are marked, the right one solves it.
      for (final element in choices.evaluate().toList()) {
        await tester.tap(find.byWidget(element.widget), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));
      }
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
    }
    expect(find.text('Great job!'), findsOneWidget);
    expect(state.active!.plays['colors'], 1);
    expect(state.active!.stickers, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });
}
