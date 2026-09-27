import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/grade.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';
import '../quiz.dart';
import '../word_bank.dart';
import 'helpers.dart';

/// Countable objects (singular name, emoji).
const countables = <PicWord>[
  PicWord('apple', '🍎'), PicWord('star', '⭐'), PicWord('duck', '🦆'), PicWord('ball', '⚽'),
  PicWord('fish', '🐟'), PicWord('flower', '🌸'), PicWord('cookie', '🍪'), PicWord('car', '🚗'),
  PicWord('balloon', '🎈'), PicWord('butterfly', '🦋'), PicWord('cupcake', '🧁'), PicWord('frog', '🐸'),
  PicWord('rocket', '🚀'), PicWord('strawberry', '🍓'), PicWord('bee', '🐝'), PicWord('heart', '💖'),
];

QuizChoice _num(int n) => QuizChoice(label: '$n', readingFont: false, speech: numberWord(n));

List<int> _numberOptions(GenContext ctx, int correct, {int minValue = 0, int maxValue = 1000, int? count}) =>
    nearbyNumbers(ctx.rng, correct, count ?? (ctx.tier <= 1 ? 2 : 3),
        minValue: minValue, maxValue: maxValue, spread: max(2, correct ~/ 8));

/// Count the objects.
QuizQuestion countObjects(GenContext ctx) {
  final ranges = [
    [1, 4], [1, 6], [2, 8], // preschool
    [3, 10], [5, 12], [8, 15], // kindergarten
    [10, 18], [12, 20], [14, 20], // 1st
    [15, 20], [18, 25], [20, 30], // 2nd
  ];
  final r = ranges[ctx.tier];
  final n = ctx.rng.range(r[0], r[1]);
  final thing = ctx.rng.pick(countables);
  return QuizQuestion.shuffled<int>(
    rng: ctx.rng,
    prompt: 'How many ${pluralize(thing.word, 2)}?',
    speech: 'How many ${pluralize(thing.word, 2)} can you count? Tap them to count!',
    visual: (_) => EmojiGroup(emoji: thing.emoji, count: n, tapToCount: true, size: n > 15 ? 36 : 48),
    correct: n,
    wrong: _numberOptions(ctx, n, minValue: 1),
    toChoice: _num,
    key: 'count-$n-${thing.word}',
    explanation: 'There are ${numberWord(n)} ${pluralize(thing.word, n)}!',
  );
}

/// Find the number the narrator says.
QuizQuestion numberFind(GenContext ctx) {
  final maxes = [5, 7, 10, 10, 15, 20, 20, 50, 100, 100, 100, 100];
  final n = ctx.rng.range(ctx.tier <= 2 ? 1 : 0, maxes[ctx.tier]);
  final wrong = <int>{};
  // Mix digit swaps (12 vs 21) into harder levels.
  if (n >= 10 && n % 10 != 0 && ctx.tier >= 4) {
    final swapped = int.parse('$n'.split('').reversed.join());
    if (swapped != n) wrong.add(swapped);
  }
  wrong.addAll(_numberOptions(ctx, n, minValue: 0, maxValue: maxes[ctx.tier] + 5));
  return QuizQuestion.shuffled<int>(
    rng: ctx.rng,
    prompt: 'Find the number ${numberWord(n)}',
    speech: 'Find the number ${numberWord(n)}.',
    correct: n,
    wrong: wrong.take(ctx.tier <= 1 ? 2 : 3).toList(),
    toChoice: _num,
    key: 'numfind-$n',
  );
}

/// Compare groups or numbers.
QuizQuestion moreLess(GenContext ctx) {
  final rng = ctx.rng;
  if (ctx.tier <= 4) {
    final more = rng.nextBool() || ctx.tier <= 1;
    final maxN = ctx.tier <= 1 ? 5 : 9;
    final a = rng.range(1, maxN);
    var b = rng.range(1, maxN);
    while ((a - b).abs() < (ctx.tier <= 1 ? 2 : 1)) {
      b = rng.range(1, maxN);
    }
    final thing = rng.pick(countables);
    final correct = more ? max(a, b) : min(a, b);
    final word = more ? 'MORE' : 'FEWER';
    return QuizQuestion.shuffled<int>(
      rng: rng,
      prompt: 'Which group has $word?',
      speech: 'Which group has ${word.toLowerCase()} ${pluralize(thing.word, 2)}?',
      correct: correct,
      wrong: [correct == a ? b : a],
      toChoice: (n) => QuizChoice(
        builder: (_) => EmojiGroup(emoji: thing.emoji, count: n, size: 34, maxPerRow: 3),
        speech: numberWord(n),
      ),
      key: 'group-$a-$b-$more',
      explanation: '${numberWord(correct)} is ${more ? 'more' : 'fewer'}!',
    );
  }
  if (ctx.tier <= 6) {
    final maxN = ctx.tier == 5 ? 20 : 50;
    final nums = rng.sample(List.generate(maxN, (i) => i + 1), 3);
    final bigger = rng.nextBool();
    final correct = bigger ? nums.reduce(max) : nums.reduce(min);
    return QuizQuestion.shuffled<int>(
      rng: rng,
      prompt: bigger ? 'Which number is BIGGER?' : 'Which number is SMALLER?',
      speech: bigger ? 'Which number is the biggest?' : 'Which number is the smallest?',
      correct: correct,
      wrong: nums.where((n) => n != correct).toList(),
      toChoice: _num,
      key: 'cmp-${nums.join('-')}-$bigger',
    );
  }
  // Greater than / less than / equal symbols.
  final maxN = ctx.tier <= 8 ? 100 : 999;
  final a = rng.range(1, maxN);
  final b = rng.chance(0.2) ? a : rng.range(1, maxN);
  final sign = a > b ? '>' : (a < b ? '<' : '=');
  final names = {'>': 'is greater than', '<': 'is less than', '=': 'is equal to'};
  return QuizQuestion.shuffled<String>(
    rng: rng,
    prompt: 'Which sign makes it true?',
    speech: 'Which sign goes in the middle? $a ... $b.',
    visual: (_) => BigTextCard(text: '$a  ?  $b', size: 56, reading: false, color: AppColors.math),
    correct: sign,
    wrong: ['>', '<', '='].where((s) => s != sign).toList(),
    toChoice: (s) => QuizChoice(label: s, readingFont: false, speech: names[s]),
    key: 'sign-$a-$b',
    explanation: '$a ${names[sign]} $b.',
  );
}

class PictureEquation extends StatelessWidget {
  const PictureEquation({super.key, required this.a, required this.b, required this.emoji});
  final int a;
  final int b;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    Widget sign(String s) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(s, style: KidText.display(56, color: AppColors.math)),
        );
    Widget box(int n) => Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmojiGroup(emoji: emoji, count: n, size: 36, maxPerRow: 3),
              Text('$n', style: KidText.display(30, color: AppColors.math)),
            ],
          ),
        );
    return FittedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [box(a), sign('+'), box(b), sign('='), sign('?')],
      ),
    );
  }
}

/// Picture addition.
QuizQuestion addPictures(GenContext ctx) {
  final maxSum = ctx.tier <= 3 ? 5 : 10;
  final a = ctx.rng.range(1, maxSum - 1);
  final b = ctx.rng.range(1, maxSum - a);
  final thing = ctx.rng.pick(countables);
  final sum = a + b;
  return QuizQuestion.shuffled<int>(
    rng: ctx.rng,
    prompt: '$a + $b = ?',
    speech: '${numberWord(a)} ${pluralize(thing.word, a)} plus ${numberWord(b)} more. How many ${pluralize(thing.word, 2)} in all?',
    visual: (_) => PictureEquation(a: a, b: b, emoji: thing.emoji),
    correct: sum,
    wrong: _numberOptions(ctx, sum, minValue: 1, maxValue: maxSum + 2),
    toChoice: _num,
    key: 'addp-$a-$b',
    explanation: '$a plus $b equals $sum!',
  );
}

/// Picture subtraction ("take away").
QuizQuestion subtractPictures(GenContext ctx) {
  final maxTotal = ctx.tier <= 3 ? 5 : 10;
  final total = ctx.rng.range(2, maxTotal);
  final take = ctx.rng.range(1, total - 1);
  final thing = ctx.rng.pick(countables);
  final left = total - take;
  return QuizQuestion.shuffled<int>(
    rng: ctx.rng,
    prompt: '$total − $take = ?',
    speech: 'There are ${numberWord(total)} ${pluralize(thing.word, total)}. Take away ${numberWord(take)}. How many are left?',
    visual: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmojiGroup(emoji: thing.emoji, count: total, crossedOut: take, size: 40),
        const SizedBox(height: 6),
        Text('$total − $take = ?', style: KidText.display(40, color: AppColors.math)),
      ],
    ),
    correct: left,
    wrong: _numberOptions(ctx, left, minValue: 0, maxValue: maxTotal),
    toChoice: _num,
    key: 'subp-$total-$take',
    explanation: '$total take away $take is $left!',
  );
}

(int, int) _additionPair(GenContext ctx) {
  final rng = ctx.rng;
  switch (ctx.grade) {
    case Grade.preschool:
    case Grade.kindergarten:
      final a = rng.range(0, 5 + ctx.level * 2);
      return (a, rng.range(0, 10 - a));
    case Grade.grade1:
      if (ctx.level == 0) {
        final a = rng.range(1, 9);
        return (a, rng.range(0, 10 - a));
      }
      if (ctx.level == 1) return (rng.range(2, 9), rng.range(2, 9));
      final a = rng.range(10, 15);
      return (a, rng.range(1, 20 - a));
    case Grade.grade2:
      if (ctx.level == 0) {
        final a = rng.range(10, 89);
        return (a, rng.range(1, 9 - a % 10 < 1 ? 1 : 9 - a % 10));
      }
      if (ctx.level == 1) {
        // Two-digit, no regrouping.
        final a = rng.range(11, 78);
        final bt = rng.range(1, max(1, 9 - a ~/ 10));
        final bo = rng.range(0, 9 - a % 10);
        return (a, bt * 10 + bo);
      }
      final a = rng.range(15, 69);
      return (a, rng.range(11, 99 - a));
  }
}

/// Number addition.
QuizQuestion addition(GenContext ctx) {
  final (a, b) = _additionPair(ctx);
  final sum = a + b;
  return QuizQuestion.shuffled<int>(
    rng: ctx.rng,
    prompt: '$a + $b = ?',
    speech: 'What is ${numberWord(a)} plus ${numberWord(b)}?',
    visual: (_) => BigTextCard(text: '$a + $b = ?', size: 64, reading: false, color: AppColors.math),
    correct: sum,
    wrong: _numberOptions(ctx, sum, minValue: 0),
    toChoice: _num,
    key: 'add-$a-$b',
    explanation: '$a plus $b equals $sum.',
  );
}

/// Number subtraction.
QuizQuestion subtraction(GenContext ctx) {
  final rng = ctx.rng;
  int a, b;
  switch (ctx.grade) {
    case Grade.preschool:
    case Grade.kindergarten:
      a = rng.range(2, 6 + ctx.level * 2);
      b = rng.range(0, a);
    case Grade.grade1:
      a = ctx.level == 0 ? rng.range(3, 10) : rng.range(10, 20);
      b = ctx.level == 2 ? rng.range(2, 9) : rng.range(1, min(9, a));
      if (b > a) b = a;
    case Grade.grade2:
      if (ctx.level == 0) {
        a = rng.range(20, 99);
        b = rng.range(1, a % 10 == 0 ? 1 : a % 10);
      } else if (ctx.level == 1) {
        a = rng.range(30, 99);
        b = rng.range(1, a ~/ 10 - 1) * 10 + rng.range(0, a % 10);
      } else {
        a = rng.range(30, 99);
        b = rng.range(11, a - 5);
      }
  }
  final diff = a - b;
  return QuizQuestion.shuffled<int>(
    rng: rng,
    prompt: '$a − $b = ?',
    speech: 'What is ${numberWord(a)} minus ${numberWord(b)}?',
    visual: (_) => BigTextCard(text: '$a − $b = ?', size: 64, reading: false, color: AppColors.math),
    correct: diff,
    wrong: _numberOptions(ctx, diff, minValue: 0),
    toChoice: _num,
    key: 'sub-$a-$b',
    explanation: '$a minus $b equals $diff.',
  );
}

class NumberSequence extends StatelessWidget {
  const NumberSequence({super.key, required this.numbers, required this.blank});
  final List<int> numbers;
  final int blank;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < numbers.length; i++)
            Container(
              width: 76,
              height: 76,
              margin: const EdgeInsets.all(5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: i == blank ? AppColors.math.pastel : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: i == blank ? AppColors.math : const Color(0xFFD9E8F7), width: 3),
              ),
              child: Text(
                i == blank ? '?' : '${numbers[i]}',
                style: KidText.display(numbers[i] >= 100 ? 26 : 32, color: i == blank ? AppColors.math : AppColors.ink),
              ),
            ),
        ],
      ),
    );
  }
}

/// What number is missing from the sequence?
QuizQuestion missingNumber(GenContext ctx) {
  final rng = ctx.rng;
  int step;
  int start;
  switch (ctx.grade) {
    case Grade.preschool:
    case Grade.kindergarten:
      step = 1;
      start = rng.range(ctx.level == 0 ? 1 : 5, ctx.level == 2 ? 15 : 8);
    case Grade.grade1:
      step = [1, 1, 2, 5, 10, -1][rng.nextInt(ctx.level == 0 ? 2 : 6)];
      start = step == 10 ? rng.range(1, 5) * 10 : step == 5 ? rng.range(1, 10) * 5 : rng.range(10, 90);
    case Grade.grade2:
      step = [2, 5, 10, 10, 100, -10][rng.nextInt(ctx.level == 0 ? 3 : 6)];
      start = step == 100
          ? rng.range(1, 5) * 100
          : step == -10
              ? rng.range(10, 30) * 10
              : rng.range(ctx.level == 2 ? 100 : 10, ctx.level == 2 ? 400 : 60) ~/ step * step;
  }
  final numbers = List.generate(5, (i) => start + i * step);
  if (numbers.any((n) => n < 0)) return missingNumber(ctx);
  final blank = rng.range(1, 4);
  final answer = numbers[blank];
  final needed = ctx.tier <= 2 ? 2 : 3;
  final wrong = <int>{};
  if (step.abs() > 1) wrong.add(answer + (step > 0 ? 1 : -1));
  var spread = max(2, step.abs());
  var guard = 0;
  while (wrong.length < needed && guard++ < 200) {
    final c = answer + rng.range(-spread, spread);
    if (c != answer && c >= 0 && !numbers.contains(c)) wrong.add(c);
    if (guard % 10 == 0) spread += 2;
  }
  final stepWords = step.abs() == 1 ? '' : ' Count by ${numberWord(step.abs())}s!';
  return QuizQuestion.shuffled<int>(
    rng: rng,
    prompt: 'What number is missing?',
    speech: 'What number is missing?$stepWords',
    visual: (_) => NumberSequence(numbers: numbers, blank: blank),
    correct: answer,
    wrong: wrong.take(needed).toList(),
    toChoice: _num,
    key: 'seq-$start-$step-$blank',
  );
}

/// Tens and ones with base-ten blocks.
QuizQuestion placeValue(GenContext ctx) {
  final rng = ctx.rng;
  final useHundreds = ctx.grade == Grade.grade2 && ctx.level >= 1;
  final hundreds = useHundreds ? rng.range(1, 3) : 0;
  final tens = rng.range(1, ctx.tier <= 6 ? 5 : 9);
  final ones = rng.range(0, 9);
  final value = hundreds * 100 + tens * 10 + ones;
  final wrong = <int>{
    if (ones != tens && ones > 0) hundreds * 100 + ones * 10 + tens,
    value + 10,
    value - 10 > 0 ? value - 10 : value + 20,
    value + 1,
  }..remove(value);
  return QuizQuestion.shuffled<int>(
    rng: rng,
    prompt: 'What number do the blocks show?',
    speech: useHundreds
        ? 'Count the hundreds, tens and ones. What number is it?'
        : 'Each long block is ten. Each little block is one. What number is it?',
    visual: (_) => BaseTenBlocks(hundreds: hundreds, tens: tens, ones: ones),
    correct: value,
    wrong: (wrong.toList()..shuffle(rng)).take(3).toList(),
    toChoice: _num,
    key: 'pv-$value',
    explanation: useHundreds
        ? '$hundreds hundreds, $tens tens and $ones ones make $value.'
        : '$tens tens and $ones ones make $value.',
  );
}

/// Read an analog clock.
QuizQuestion tellTime(GenContext ctx) {
  final rng = ctx.rng;
  final List<int> minutes = switch (ctx.tier) {
    <= 6 => [0],
    7 => [0, 30],
    8 => [0, 30, 15, 45],
    9 => [0, 15, 30, 45],
    _ => List.generate(12, (i) => i * 5),
  };
  final hour = rng.range(1, 12);
  final minute = rng.pick(minutes);
  final answer = timeLabel(hour, minute);
  final wrong = <String>{};
  // A common mix-up: reading the hour hand as the next hour.
  if (minute >= 30) wrong.add(timeLabel(hour % 12 + 1, minute));
  final distractorMinutes = minutes.length > 1 ? minutes : const [0, 30];
  while (wrong.length < 3) {
    final h = rng.chance(0.5) ? hour : rng.range(1, 12);
    final label = timeLabel(h, rng.pick(distractorMinutes));
    if (label != answer) wrong.add(label);
  }
  return QuizQuestion.shuffled<String>(
    rng: rng,
    prompt: 'What time is it?',
    speech: 'Look at the clock. What time is it?',
    visual: (_) => ClockFace(hour: hour, minute: minute, size: 190),
    correct: answer,
    wrong: wrong.take(ctx.tier <= 6 ? 2 : 3).toList(),
    toChoice: (t) {
      final parts = t.split(':');
      return QuizChoice(label: t, readingFont: false, speech: timeSpeech(int.parse(parts[0]), int.parse(parts[1])));
    },
    key: 'time-$answer',
    explanation: 'It is ${timeSpeech(hour, minute)}.',
  );
}

class _Person {
  const _Person(this.name, this.pronoun);
  final String name;
  final String pronoun;
}

const _people = [
  _Person('Mia', 'she'), _Person('Leo', 'he'), _Person('Ava', 'she'), _Person('Sam', 'he'),
  _Person('Zoe', 'she'), _Person('Raj', 'he'), _Person('Aria', 'she'), _Person('Kai', 'he'),
];

/// Short story problems.
QuizQuestion wordProblem(GenContext ctx) {
  final rng = ctx.rng;
  final p1 = rng.pick(_people);
  var p2 = rng.pick(_people);
  while (p2 == p1) {
    p2 = rng.pick(_people);
  }
  final thing = rng.pick(countables);
  final maxN = ctx.grade == Grade.grade2 ? (ctx.level == 0 ? 20 : 60) : (ctx.level == 0 ? 10 : 20);
  final kind = rng.nextInt(ctx.tier >= 7 ? 3 : 2);
  late String text;
  late int answer;
  late String visualEmoji;
  if (kind == 0) {
    final a = rng.range(1, maxN ~/ 2);
    final b = rng.range(1, maxN - a);
    answer = a + b;
    text = '${p1.name} has $a ${pluralize(thing.word, a)}. ${p2.name} gives ${p1.pronoun == 'she' ? 'her' : 'him'} $b more. '
        'How many ${pluralize(thing.word, 2)} does ${p1.name} have now?';
    visualEmoji = thing.emoji;
  } else if (kind == 1) {
    final a = rng.range(3, maxN);
    final b = rng.range(1, a - 1);
    answer = a - b;
    text = '${p1.name} has $a ${pluralize(thing.word, a)}. ${p1.pronoun == 'she' ? 'She' : 'He'} gives $b to ${p2.name}. '
        'How many ${pluralize(thing.word, 2)} does ${p1.name} have left?';
    visualEmoji = thing.emoji;
  } else {
    final a = rng.range(5, maxN);
    final b = rng.range(1, a - 1);
    answer = a - b;
    text = '${p1.name} has $a ${pluralize(thing.word, a)}. ${p2.name} has $b ${pluralize(thing.word, b)}. '
        'How many more ${pluralize(thing.word, 2)} does ${p1.name} have than ${p2.name}?';
    visualEmoji = thing.emoji;
  }
  return QuizQuestion.shuffled<int>(
    rng: rng,
    prompt: 'Solve the story problem',
    speech: text,
    visual: (_) => PassageCard(emoji: visualEmoji, text: text),
    correct: answer,
    wrong: _numberOptions(ctx, answer, minValue: 0),
    toChoice: _num,
    key: 'wp-$text',
    explanation: 'The answer is $answer.',
  );
}

/// Ten frame used in counting explorer visuals.
class TenFrame extends StatelessWidget {
  const TenFrame({super.key, required this.count, this.emoji = '🔴'});
  final int count;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < 2; r++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var c = 0; c < 5; c++)
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.all(2),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: AppColors.math, width: 2), borderRadius: BorderRadius.circular(6)),
                    child: r * 5 + c < count ? EmojiText(emoji, size: 26) : null,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
