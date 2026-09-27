import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/activities.dart';
import '../content/books.dart';
import '../content/stickers.dart';
import '../content/subjects.dart';
import '../core/utils.dart';
import '../models/grade.dart';
import '../models/profile.dart';
import '../models/settings.dart';

/// What a child earned for finishing something.
class Reward {
  const Reward({required this.stars, this.sticker, this.levelUp = false, this.adventureComplete = false});

  final int stars;
  final String? sticker;
  final bool levelUp;
  final bool adventureComplete;
}

class PremiumLimits {
  PremiumLimits._();
  static const freeProfiles = 1;
  static const premiumProfiles = 5;
}

/// All persistent app data: child profiles, progress and settings.
class AppState extends ChangeNotifier {
  AppState(this._prefs);

  final SharedPreferences _prefs;
  static const _storageKey = 'klu_data_v1';

  final List<ChildProfile> profiles = [];
  String? _activeId;
  AppSettings settings = AppSettings();

  /// Extra minutes a grown-up granted today after the daily limit.
  int _bonusMinutes = 0;
  String _bonusDay = '';
  Timer? _saveTimer;
  final _random = Random();

  ChildProfile? get active {
    for (final p in profiles) {
      if (p.id == _activeId) return p;
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  bool get hasProfiles => profiles.isNotEmpty;

  Future<void> load() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      profiles
        ..clear()
        ..addAll((data['profiles'] as List? ?? const [])
            .map((e) => ChildProfile.fromJson(e as Map<String, dynamic>)));
      _activeId = data['active'] as String?;
      settings = AppSettings.fromJson(data['settings'] as Map<String, dynamic>? ?? const {});
      _bonusDay = data['bonusDay'] as String? ?? '';
      _bonusMinutes = data['bonus'] as int? ?? 0;
    } catch (e) {
      debugPrint('Could not load saved data: $e');
    }
  }

  void _save() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), saveNow);
  }

  Future<void> saveNow() async {
    _saveTimer?.cancel();
    final data = {
      'profiles': profiles.map((p) => p.toJson()).toList(),
      'active': _activeId,
      'settings': settings.toJson(),
      'bonusDay': _bonusDay,
      'bonus': _bonusMinutes,
    };
    await _prefs.setString(_storageKey, jsonEncode(data));
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  // ------------------------------------------------------------- Profiles

  int maxProfiles(bool premium) => premium ? PremiumLimits.premiumProfiles : PremiumLimits.freeProfiles;

  ChildProfile addProfile({required String name, required String avatar, required Grade grade}) {
    final p = ChildProfile(id: ChildProfile.newId(), name: name.trim().isEmpty ? 'Explorer' : name.trim(), avatar: avatar, grade: grade);
    profiles.add(p);
    _activeId = p.id;
    _changed();
    return p;
  }

  void updateProfile(ChildProfile p, {String? name, String? avatar, Grade? grade}) {
    if (name != null && name.trim().isNotEmpty) p.name = name.trim();
    if (avatar != null) p.avatar = avatar;
    if (grade != null && grade != p.grade) {
      p.grade = grade;
      p.adventure = null;
    }
    _changed();
  }

  void deleteProfile(ChildProfile p) {
    profiles.remove(p);
    if (_activeId == p.id) _activeId = profiles.isEmpty ? null : profiles.first.id;
    _changed();
  }

  void selectProfile(ChildProfile p) {
    _activeId = p.id;
    _changed();
  }

  // ------------------------------------------------------------- Settings

  void updateSettings(void Function(AppSettings s) change) {
    change(settings);
    _changed();
  }

  // ------------------------------------------------------------- Progress

  /// Difficulty level (0..2) for a skill for the active child.
  int levelFor(String skillKey) => active?.skills[skillKey]?.level ?? 0;

  List<String> _stickerPool(bool premium) => [
        for (final pack in stickerPacks)
          if (!pack.premium || premium) ...pack.stickers,
      ];

  String? _awardSticker(ChildProfile p, bool premium) {
    final remaining = _stickerPool(premium).where((s) => !p.stickers.contains(s)).toList();
    if (remaining.isEmpty) return null;
    final s = remaining[_random.nextInt(remaining.length)];
    p.stickers.add(s);
    return s;
  }

  /// Records a finished activity and returns the reward.
  Reward recordActivity({
    required ActivityDef activity,
    required int firstTryCorrect,
    required int total,
    required int seconds,
    required bool premium,
  }) {
    final p = active;
    if (p == null) return const Reward(stars: 0);
    var levelUp = false;
    if (activity.isScored && total > 0) {
      final stats = p.skill(activity.skillKey);
      stats
        ..attempts += total
        ..firstTryCorrect += firstTryCorrect
        ..sessions += 1
        ..lastPlayed = DateTime.now();
      final accuracy = firstTryCorrect / total;
      if (accuracy >= 0.85 && stats.level < 2) {
        stats.level++;
        levelUp = true;
      } else if (accuracy < 0.5 && stats.level > 0) {
        stats.level--;
      }
    }
    final stars = activity.isScored ? firstTryCorrect + (total > 0 && firstTryCorrect == total ? 2 : 0) : 3;
    p.stars += stars;
    p.plays[activity.id] = (p.plays[activity.id] ?? 0) + 1;
    p.history.insert(
      0,
      ActivityLog(
        activityId: activity.id,
        when: DateTime.now(),
        correct: firstTryCorrect,
        total: total,
        stars: stars,
        seconds: seconds,
      ),
    );
    if (p.history.length > 60) p.history.removeRange(60, p.history.length);
    final sticker = _awardSticker(p, premium);
    final adventureDone = _markAdventure(p, activity.id);
    _changed();
    return Reward(stars: stars, sticker: sticker, levelUp: levelUp, adventureComplete: adventureDone);
  }

  Reward recordBook(Book book, {required bool premium}) {
    final p = active;
    if (p == null) return const Reward(stars: 0);
    final firstTime = p.booksRead.add(book.id);
    final stars = firstTime ? 5 : 2;
    p.stars += stars;
    p.history.insert(
      0,
      ActivityLog(activityId: 'book:${book.id}', when: DateTime.now(), correct: 0, total: 0, stars: stars, seconds: 0),
    );
    if (p.history.length > 60) p.history.removeRange(60, p.history.length);
    final sticker = _awardSticker(p, premium);
    final adventureDone = _markAdventure(p, 'book:${book.id}');
    _changed();
    return Reward(stars: stars, sticker: sticker, adventureComplete: adventureDone);
  }

  // ------------------------------------------------------------- Adventure

  /// Today's learning path (built once per day per child).
  AdventureDay adventureFor(ChildProfile p, {required bool premium}) {
    final today = dayKey();
    final current = p.adventure;
    if (current != null && current.day == today && current.steps.isNotEmpty) return current;
    final rng = Random(today.hashCode ^ p.id.hashCode);
    String pickActivity(SubjectId subject) {
      final options = activitiesFor(subject, p.grade)
          .where((a) => a.isScored && (premium || !a.premium))
          .toList()
        ..sort((a, b) => (p.plays[a.id] ?? 0).compareTo(p.plays[b.id] ?? 0));
      if (options.isEmpty) return activitiesFor(subject, p.grade).first.id;
      final top = options.take(3).toList();
      return top[rng.nextInt(top.length)].id;
    }

    final bookOptions = books.where((b) => b.fitsGrade(p.grade) && (premium || !b.premium)).toList()
      ..sort((a, b) => (p.booksRead.contains(a.id) ? 1 : 0).compareTo(p.booksRead.contains(b.id) ? 1 : 0));
    final steps = <String>[
      pickActivity(SubjectId.reading),
      pickActivity(SubjectId.math),
      pickActivity(SubjectId.puzzles),
      if (bookOptions.isNotEmpty) 'book:${bookOptions[rng.nextInt(min(2, bookOptions.length))].id}',
    ];
    final day = AdventureDay(day: today, steps: steps);
    p.adventure = day;
    _save();
    return day;
  }

  bool _markAdventure(ChildProfile p, String stepId) {
    final adv = p.adventure;
    if (adv == null || adv.day != dayKey() || !adv.steps.contains(stepId) || adv.done.contains(stepId)) {
      return false;
    }
    adv.done.add(stepId);
    if (adv.complete) {
      p.adventuresCompleted++;
      p.stars += 10;
      return true;
    }
    return false;
  }

  // ------------------------------------------------------------- Screen time

  void addLearningSeconds(int seconds) {
    final p = active;
    if (p == null) return;
    final key = dayKey();
    p.secondsByDay[key] = (p.secondsByDay[key] ?? 0) + seconds;
    // Keep ~2 months of history.
    if (p.secondsByDay.length > 62) {
      final keys = p.secondsByDay.keys.toList()..sort();
      for (final k in keys.take(p.secondsByDay.length - 62)) {
        p.secondsByDay.remove(k);
      }
    }
    final wasLimited = limitReached;
    _save();
    if (limitReached != wasLimited || limitReached) notifyListeners();
  }

  int get _bonusToday => _bonusDay == dayKey() ? _bonusMinutes : 0;

  bool get limitReached {
    final p = active;
    if (p == null || settings.dailyLimitMinutes <= 0) return false;
    return p.secondsToday >= (settings.dailyLimitMinutes + _bonusToday) * 60;
  }

  void grantBonusMinutes(int minutes) {
    final today = dayKey();
    if (_bonusDay != today) {
      _bonusDay = today;
      _bonusMinutes = 0;
    }
    final p = active;
    // Make sure the bonus is counted from now.
    final usedMinutes = (p?.secondsToday ?? 0) ~/ 60;
    final base = max(settings.dailyLimitMinutes + _bonusMinutes, usedMinutes);
    _bonusMinutes = base - settings.dailyLimitMinutes + minutes;
    _changed();
  }

  /// Wipes everything (used from the grown-ups area).
  Future<void> resetAll() async {
    profiles.clear();
    _activeId = null;
    settings = AppSettings();
    await _prefs.remove(_storageKey);
    notifyListeners();
  }
}
