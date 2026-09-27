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
}
