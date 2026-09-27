import 'dart:math';

import '../../core/utils.dart';
import '../quiz.dart';
import '../word_bank.dart';

QuizChoice textChoice(String text, {bool reading = true, String? speech}) =>
    QuizChoice(label: text, readingFont: reading, speech: speech ?? text);

QuizChoice picChoice(PicWord w, {bool showLabel = false}) =>
    QuizChoice(emoji: w.emoji, label: showLabel ? w.word : null, speech: w.word);

/// Distinct numbers near [correct] within [minValue]..[maxValue].
List<int> nearbyNumbers(Random rng, int correct, int count, {int minValue = 0, int maxValue = 1000, int spread = 3}) {
  final pool = <int>{};
  var s = spread;
  var guard = 0;
  while (pool.length < count && guard < 200) {
    guard++;
    final candidate = correct + rng.range(-s, s);
    if (candidate != correct && candidate >= minValue && candidate <= maxValue) pool.add(candidate);
    if (guard % 20 == 0) s++;
  }
  // Fallback for very small ranges.
  var next = minValue;
  while (pool.length < count && next <= maxValue + count + 2) {
    if (next != correct) pool.add(next);
    next++;
  }
  return pool.take(count).toList();
}

String article(String word) => 'aeiou'.contains(word[0]) ? 'an' : 'a';
