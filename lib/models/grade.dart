/// Learning levels covered by the app, from preschool to 2nd grade.
enum Grade {
  preschool('Preschool', 'Pre-K', 'Ages 2–4', '🧸'),
  kindergarten('Kindergarten', 'K', 'Ages 4–6', '🎒'),
  grade1('1st Grade', '1st', 'Ages 6–7', '✏️'),
  grade2('2nd Grade', '2nd', 'Ages 7–8', '🚀');

  const Grade(this.label, this.short, this.ages, this.emoji);

  final String label;
  final String short;
  final String ages;
  final String emoji;

  bool operator >=(Grade other) => index >= other.index;
  bool operator <=(Grade other) => index <= other.index;

  /// Number of rounds in a quiz-style activity.
  int get rounds => const [5, 6, 7, 8][index];

  static Grade fromName(String? name) =>
      Grade.values.firstWhere((g) => g.name == name, orElse: () => Grade.kindergarten);
}
