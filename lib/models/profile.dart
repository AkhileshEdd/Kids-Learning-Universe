import 'dart:math';

import '../core/utils.dart';
import 'grade.dart';

/// Per-skill learning statistics used for adaptive difficulty and reports.
class SkillStats {
  SkillStats({
    this.attempts = 0,
    this.firstTryCorrect = 0,
    this.sessions = 0,
    this.level = 0,
    this.lastPlayed,
  });

  int attempts;
  int firstTryCorrect;
  int sessions;

  /// Difficulty inside the child's grade: 0 (easy), 1 (medium), 2 (hard).
  int level;
  DateTime? lastPlayed;

  double get accuracy => attempts == 0 ? 0 : firstTryCorrect / attempts;

  /// 0..3 mastery stars shown to parents and kids.
  int get masteryStars {
    if (sessions == 0) return 0;
    if (level >= 2 && accuracy >= 0.8) return 3;
    if (level >= 1 || accuracy >= 0.75) return 2;
    return 1;
  }

  Map<String, dynamic> toJson() => {
        'a': attempts,
        'c': firstTryCorrect,
        's': sessions,
        'l': level,
        if (lastPlayed != null) 't': lastPlayed!.toIso8601String(),
      };

  factory SkillStats.fromJson(Map<String, dynamic> j) => SkillStats(
        attempts: j['a'] as int? ?? 0,
        firstTryCorrect: j['c'] as int? ?? 0,
        sessions: j['s'] as int? ?? 0,
        level: j['l'] as int? ?? 0,
        lastPlayed: j['t'] == null ? null : DateTime.tryParse(j['t'] as String),
      );
}

/// One entry in the activity history shown in the parent zone.
class ActivityLog {
  ActivityLog({
    required this.activityId,
    required this.when,
    required this.correct,
    required this.total,
    required this.stars,
    required this.seconds,
  });

  final String activityId;
  final DateTime when;
  final int correct;
  final int total;
  final int stars;
  final int seconds;

  Map<String, dynamic> toJson() => {
        'id': activityId,
        'w': when.toIso8601String(),
        'c': correct,
        'n': total,
        's': stars,
        'sec': seconds,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> j) => ActivityLog(
        activityId: j['id'] as String,
        when: DateTime.tryParse(j['w'] as String? ?? '') ?? DateTime.now(),
        correct: j['c'] as int? ?? 0,
        total: j['n'] as int? ?? 0,
        stars: j['s'] as int? ?? 0,
        seconds: j['sec'] as int? ?? 0,
      );
}

/// Today's Adventure: a short daily learning path.
class AdventureDay {
  AdventureDay({required this.day, required this.steps, Set<String>? done})
      : done = done ?? <String>{};

  final String day;

  /// Step ids: activity ids, or `book:<id>` for a story.
  final List<String> steps;
  final Set<String> done;

  bool get complete => steps.isNotEmpty && steps.every(done.contains);

  Map<String, dynamic> toJson() => {'d': day, 's': steps, 'x': done.toList()};

  factory AdventureDay.fromJson(Map<String, dynamic> j) => AdventureDay(
        day: j['d'] as String,
        steps: (j['s'] as List).cast<String>(),
        done: (j['x'] as List? ?? const []).cast<String>().toSet(),
      );
}

class ChildProfile {
  ChildProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.grade,
    this.stars = 0,
    Set<String>? stickers,
    Map<String, SkillStats>? skills,
    Map<String, int>? plays,
    Set<String>? booksRead,
    List<ActivityLog>? history,
    Map<String, int>? secondsByDay,
    this.adventure,
    this.adventuresCompleted = 0,
    DateTime? createdAt,
  })  : stickers = stickers ?? <String>{},
        skills = skills ?? <String, SkillStats>{},
        plays = plays ?? <String, int>{},
        booksRead = booksRead ?? <String>{},
        history = history ?? <ActivityLog>[],
        secondsByDay = secondsByDay ?? <String, int>{},
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String avatar;
  Grade grade;
  int stars;
  final Set<String> stickers;
  final Map<String, SkillStats> skills;

  /// How many times each activity was completed.
  final Map<String, int> plays;
  final Set<String> booksRead;
  final List<ActivityLog> history;

  /// Learning time per day (yyyy-mm-dd -> seconds).
  final Map<String, int> secondsByDay;
  AdventureDay? adventure;
  int adventuresCompleted;
  final DateTime createdAt;

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${Random().nextInt(1 << 20).toRadixString(36)}';

  SkillStats skill(String key) => skills.putIfAbsent(key, SkillStats.new);

  int get secondsToday => secondsByDay[dayKey()] ?? 0;

  int get totalActivities => plays.values.fold(0, (a, b) => a + b);

  int secondsInLastDays(int days) {
    final now = DateTime.now();
    var total = 0;
    for (var i = 0; i < days; i++) {
      total += secondsByDay[dayKey(now.subtract(Duration(days: i)))] ?? 0;
    }
    return total;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'grade': grade.name,
        'stars': stars,
        'stickers': stickers.toList(),
        'skills': skills.map((k, v) => MapEntry(k, v.toJson())),
        'plays': plays,
        'books': booksRead.toList(),
        'history': history.map((h) => h.toJson()).toList(),
        'time': secondsByDay,
        if (adventure != null) 'adventure': adventure!.toJson(),
        'advDone': adventuresCompleted,
        'created': createdAt.toIso8601String(),
      };

  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Explorer',
        avatar: j['avatar'] as String? ?? '🐻',
        grade: Grade.fromName(j['grade'] as String?),
        stars: j['stars'] as int? ?? 0,
        stickers: (j['stickers'] as List? ?? const []).cast<String>().toSet(),
        skills: (j['skills'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, SkillStats.fromJson(v as Map<String, dynamic>))),
        plays: (j['plays'] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, v as int)),
        booksRead: (j['books'] as List? ?? const []).cast<String>().toSet(),
        history: (j['history'] as List? ?? const [])
            .map((e) => ActivityLog.fromJson(e as Map<String, dynamic>))
            .toList(),
        secondsByDay: (j['time'] as Map<String, dynamic>? ?? const {}).map((k, v) => MapEntry(k, v as int)),
        adventure: j['adventure'] == null ? null : AdventureDay.fromJson(j['adventure'] as Map<String, dynamic>),
        adventuresCompleted: j['advDone'] as int? ?? 0,
        createdAt: DateTime.tryParse(j['created'] as String? ?? ''),
      );
}
