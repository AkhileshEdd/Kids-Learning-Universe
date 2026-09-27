import 'dart:math';

/// yyyy-mm-dd key for the given day (local time).
String dayKey([DateTime? date]) {
  final d = date ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

extension RandomPick on Random {
  T pick<T>(List<T> items) => items[nextInt(items.length)];

  /// Picks [count] distinct items (or all of them if there are fewer).
  List<T> sample<T>(List<T> items, int count) {
    final copy = List<T>.of(items)..shuffle(this);
    return copy.take(min(count, copy.length)).toList();
  }

  /// Random int in [minValue, maxValue] (inclusive).
  int range(int minValue, int maxValue) => minValue + nextInt(maxValue - minValue + 1);

  bool chance(double probability) => nextDouble() < probability;
}

extension ListShuffled<T> on List<T> {
  List<T> shuffledWith(Random rng) => List<T>.of(this)..shuffle(rng);
}

const _ones = [
  'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
  'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
];
const _tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];

/// Spells out a number (0-999) in English words.
String numberWord(int n) {
  if (n < 20) return _ones[n];
  if (n < 100) {
    final t = _tens[n ~/ 10];
    return n % 10 == 0 ? t : '$t-${_ones[n % 10]}';
  }
  final h = '${_ones[n ~/ 100]} hundred';
  return n % 100 == 0 ? h : '$h ${numberWord(n % 100)}';
}

/// "1st", "2nd", ...
String ordinal(int n) {
  if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

const _irregularPlurals = {
  'fish': 'fish',
  'sheep': 'sheep',
  'mouse': 'mice',
  'child': 'children',
  'goose': 'geese',
  'leaf': 'leaves',
  'strawberry': 'strawberries',
};

String pluralize(String word, int count) {
  if (count == 1) return word;
  final irregular = _irregularPlurals[word];
  if (irregular != null) return irregular;
  if (word.endsWith('y') && word.length > 1 && !'aeiou'.contains(word[word.length - 2])) {
    return '${word.substring(0, word.length - 1)}ies';
  }
  if (word.endsWith('s') || word.endsWith('sh') || word.endsWith('ch') || word.endsWith('x')) {
    return '${word}es';
  }
  return '${word}s';
}
