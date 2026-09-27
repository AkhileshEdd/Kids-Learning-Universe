import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_universe/content/activities.dart';
import 'package:kids_learning_universe/content/books.dart';
import 'package:kids_learning_universe/models/grade.dart';
import 'package:kids_learning_universe/premium/premium_service.dart';
import 'package:kids_learning_universe/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('profiles persist across reloads', () async {
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(prefs);
    state.addProfile(name: 'Maya', avatar: '🦄', grade: Grade.grade1);
    await state.saveNow();

    final reloaded = AppState(prefs);
    await reloaded.load();
    expect(reloaded.profiles.single.name, 'Maya');
    expect(reloaded.active!.grade, Grade.grade1);
  });

  test('finishing an activity awards stars, a sticker and levels up', () async {
    final state = AppState(await SharedPreferences.getInstance());
    state.addProfile(name: 'Leo', avatar: '🦖', grade: Grade.kindergarten);
    final activity = activityById('count_objects')!;
    final reward = state.recordActivity(activity: activity, firstTryCorrect: 6, total: 6, seconds: 60, premium: false);
    expect(reward.stars, 8); // 6 + perfect bonus
    expect(reward.sticker, isNotNull);
    expect(reward.levelUp, isTrue);
    expect(state.levelFor(activity.skillKey), 1);

    final low = state.recordActivity(activity: activity, firstTryCorrect: 1, total: 6, seconds: 60, premium: false);
    expect(low.levelUp, isFalse);
    expect(state.levelFor(activity.skillKey), 0);
  });

  test('free children only collect free stickers', () async {
    final state = AppState(await SharedPreferences.getInstance());
    state.addProfile(name: 'Ava', avatar: '🐼', grade: Grade.preschool);
    final activity = activityById('colors')!;
    for (var i = 0; i < 50; i++) {
      state.recordActivity(activity: activity, firstTryCorrect: 3, total: 5, seconds: 30, premium: false);
    }
    expect(state.active!.stickers.length, 36); // three free packs of 12
  });

  test('daily adventure has reading, math, thinking and a book', () async {
    final state = AppState(await SharedPreferences.getInstance());
    final p = state.addProfile(name: 'Sam', avatar: '🐸', grade: Grade.grade2);
    final adv = state.adventureFor(p, premium: false);
    expect(adv.steps.length, 4);
    for (final step in adv.steps.take(3)) {
      final a = activityById(step)!;
      expect(a.fitsGrade(Grade.grade2), isTrue);
      expect(a.premium, isFalse);
    }
    expect(adv.steps.last.startsWith('book:'), isTrue);
    final book = bookById(adv.steps.last.substring(5))!;
    expect(book.premium, isFalse);

    // Completing every step finishes the adventure with a bonus.
    Reward? last;
    for (final step in adv.steps.take(3)) {
      last = state.recordActivity(activity: activityById(step)!, firstTryCorrect: 3, total: 8, seconds: 10, premium: false);
    }
    expect(last!.adventureComplete, isFalse);
    final done = state.recordBook(book, premium: false);
    expect(done.adventureComplete, isTrue);
    expect(p.adventuresCompleted, 1);
  });

  test('screen-time limit and grown-up bonus', () async {
    final state = AppState(await SharedPreferences.getInstance());
    state.addProfile(name: 'Kai', avatar: '🐝', grade: Grade.grade1);
    state.updateSettings((s) => s.dailyLimitMinutes = 15);
    expect(state.limitReached, isFalse);
    state.addLearningSeconds(15 * 60);
    expect(state.limitReached, isTrue);
    state.grantBonusMinutes(15);
    expect(state.limitReached, isFalse);
  });

  test('test purchase backend unlocks and resets premium', () async {
    final prefs = await SharedPreferences.getInstance();
    final premium = PremiumService(TestPurchaseBackend(prefs), prefs);
    await premium.init();
    expect(premium.isPremium, isFalse);
    expect(premium.products.map((p) => p.id), containsAll(<String>[PremiumProductIds.monthly, PremiumProductIds.yearly]));
    final outcome = await premium.purchase(premium.products.first);
    expect(outcome, PurchaseOutcome.success);
    expect(premium.isPremium, isTrue);
    await premium.resetTestPurchase();
    expect(premium.isPremium, isFalse);
    expect(await premium.restore(), isFalse);
  });
}
