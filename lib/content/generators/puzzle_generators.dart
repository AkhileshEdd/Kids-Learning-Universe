import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/grade.dart';
import '../../widgets/common.dart';
import '../../widgets/visuals.dart';
import '../quiz.dart';
import '../word_bank.dart';
import 'helpers.dart';

const _basicShapes = [
  ShapeKind.circle, ShapeKind.square, ShapeKind.triangle, ShapeKind.rectangle, ShapeKind.star, ShapeKind.heart,
];
const _moreShapes = [ShapeKind.oval, ShapeKind.diamond];
const _polygons = [
  ShapeKind.triangle, ShapeKind.square, ShapeKind.pentagon, ShapeKind.hexagon, ShapeKind.octagon,
];

class _Solid {
  const _Solid(this.name, this.examples);
  final String name;
  final List<PicWord> examples;
}

const _solids = [
  _Solid('sphere', [PicWord('ball', '⚽'), PicWord('globe', '🌍'), PicWord('basketball', '🏀')]),
  _Solid('cube', [PicWord('dice', '🎲'), PicWord('ice cube', '🧊'), PicWord('gift box', '🎁')]),
  _Solid('cylinder', [PicWord('can', '🥫'), PicWord('drum', '🥁'), PicWord('candle', '🕯️')]),
  _Solid('cone', [PicWord('ice cream cone', '🍦'), PicWord('party hat', '🥳')]),
];

/// Recognise and describe shapes.
QuizQuestion shapesQuiz(GenContext ctx) {
  final rng = ctx.rng;
  Color colorFor(int i) => AppColors.playful[(i * 3 + rng.nextInt(2)) % AppColors.playful.length];

  // 2nd grade: counting sides, and 3D shapes.
  if (ctx.tier >= 8 && rng.chance(0.5)) {
    if (rng.nextBool()) {
      final solid = rng.pick(_solids);
      final example = rng.pick(solid.examples);
      final wrong = _solids.where((s) => s != solid).map((s) => rng.pick(s.examples)).toList();
      return QuizQuestion.shuffled<PicWord>(
        rng: rng,
        prompt: 'Which is shaped like a ${solid.name}?',
        correct: example,
        wrong: rng.sample(wrong, 3),
        toChoice: (w) => picChoice(w, showLabel: true),
        key: 'solid-${example.word}',
        explanation: '${article(example.word) == 'an' ? 'An' : 'A'} ${example.word} is shaped like a ${solid.name}.',
      );
    }
    final shape = rng.pick(_polygons);
    return QuizQuestion.shuffled<int>(
      rng: rng,
      prompt: 'How many sides does a ${shape.label} have?',
      visual: (_) => ShapeView(kind: shape, color: colorFor(shape.index), size: 170),
      correct: shape.sides,
      wrong: _polygons.map((s) => s.sides).where((n) => n != shape.sides).toSet().take(3).toList(),
      toChoice: (n) => QuizChoice(label: '$n', readingFont: false, speech: numberWord(n)),
      key: 'sides-${shape.name}',
      explanation: '${article(shape.label) == 'an' ? 'An' : 'A'} ${shape.label} has ${numberWord(shape.sides)} sides.',
    );
  }

  // 1st grade: "which shape has N sides?"
  if (ctx.tier >= 6 && rng.chance(0.4)) {
    final shape = rng.pick(_polygons);
    final others = _polygons.where((s) => s != shape).toList();
    return QuizQuestion.shuffled<ShapeKind>(
      rng: rng,
      prompt: 'Which shape has ${shape.sides} sides?',
      speech: 'Which shape has ${numberWord(shape.sides)} sides?',
      correct: shape,
      wrong: rng.sample(others, 3),
      toChoice: (s) => QuizChoice(
        builder: (_) => ShapeView(kind: s, color: colorFor(s.index), size: 92),
        speech: s.label,
      ),
      key: 'nsides-${shape.name}',
      explanation: 'The ${shape.label} has ${numberWord(shape.sides)} sides!',
    );
  }

  final pool = <ShapeKind>[
    ..._basicShapes,
    if (ctx.tier >= 3) ..._moreShapes,
    if (ctx.tier >= 6) ...[ShapeKind.pentagon, ShapeKind.hexagon, ShapeKind.octagon, ShapeKind.trapezoid],
  ];
  final target = rng.pick(pool);
  final wrongPool = pool.where((s) {
    if (s == target) return false;
    // Squares are rectangles, so never make them compete.
    if ({s, target}.containsAll({ShapeKind.square, ShapeKind.rectangle})) return false;
    if ({s, target}.containsAll({ShapeKind.circle, ShapeKind.oval}) && ctx.tier < 3) return false;
    return true;
  }).toList();
  final count = ctx.tier <= 1 ? 2 : 3;
  return QuizQuestion.shuffled<ShapeKind>(
    rng: rng,
    prompt: 'Tap the ${target.label}!',
    speech: 'Can you find the ${target.label}?',
    correct: target,
    wrong: rng.sample(wrongPool, count),
    toChoice: (s) => QuizChoice(
      builder: (_) => ShapeView(kind: s, color: colorFor(s.index), size: 92, showFace: ctx.grade == Grade.preschool),
      speech: s.label,
    ),
    key: 'shape-${target.name}',
    explanation: 'That is a ${target.label}!',
  );
}

/// Name the colors.
QuizQuestion colorsQuiz(GenContext ctx) {
  final rng = ctx.rng;
  final pool = [...basicColors, if (ctx.tier >= 1) ...moreColors];
  final target = rng.pick(pool);
  final count = ctx.tier == 0 ? 2 : 3;
  final useObjects = ctx.tier >= 2 && rng.nextBool();
  if (useObjects) {
    // "What color is the banana?" with real-world objects.
    const things = [
      ('banana', '🍌', 'yellow'), ('strawberry', '🍓', 'red'), ('frog', '🐸', 'green'),
      ('carrot', '🥕', 'orange'), ('grapes', '🍇', 'purple'), ('whale', '🐳', 'blue'),
      ('pig', '🐷', 'pink'), ('teddy bear', '🧸', 'brown'), ('snowman', '⛄', 'white'),
      ('leaf', '🍃', 'green'), ('sun', '🌞', 'yellow'), ('tomato', '🍅', 'red'),
    ];
    final thing = rng.pick(things);
    final answer = pool.firstWhere((c) => c.name == thing.$3, orElse: () => basicColors.first);
    final wrong = rng.sample(pool.where((c) => c.name != answer.name).toList(), count);
    return QuizQuestion.shuffled<NamedColor>(
      rng: rng,
      prompt: 'What color is the ${thing.$1}?',
      visual: (_) => PictureCard(emoji: thing.$2, size: 90),
      correct: answer,
      wrong: wrong,
      toChoice: (c) => QuizChoice(builder: (_) => _ColorBlob(c), speech: c.name),
      key: 'thingcolor-${thing.$1}',
      explanation: 'The ${thing.$1} is ${answer.name}!',
    );
  }
  final wrong = rng.sample(pool.where((c) => c.name != target.name).toList(), count);
  return QuizQuestion.shuffled<NamedColor>(
    rng: rng,
    prompt: 'Tap the ${target.name} balloon!',
    speech: 'Pop the ${target.name} balloon!',
    correct: target,
    wrong: wrong,
    toChoice: (c) => QuizChoice(builder: (_) => BalloonView(color: c.color, size: 92), speech: c.name),
    key: 'color-${target.name}',
    explanation: 'Yes, that one is ${target.name}!',
  );
}

class _ColorBlob extends StatelessWidget {
  const _ColorBlob(this.c);
  final NamedColor c;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShapeView(kind: ShapeKind.circle, color: c.color, size: 70),
        Text(c.name, style: KidText.display(18)),
      ],
    );
  }
}

/// A pattern element: either an emoji or a colored shape.
class _Unit {
  const _Unit.emoji(this.emoji) : shape = null, color = null;
  const _Unit.shape(this.shape, this.color) : emoji = null;
  final String? emoji;
  final ShapeKind? shape;
  final Color? color;

  String get id => emoji ?? '${shape!.name}-${color!.toARGB32()}';
  String get speech => emoji != null ? '' : shape!.label;

  Widget build(double size) =>
      emoji != null ? EmojiText(emoji!, size: size) : ShapeView(kind: shape!, color: color!, size: size * 1.1);
}

const _patternThemes = [
  ['🍎', '🍌', '🍇', '🍓'],
  ['🐶', '🐱', '🐰', '🐻'],
  ['⭐', '🌙', '☀️', '☁️'],
  ['🚗', '🚌', '🚲', '🚀'],
  ['🌸', '🍀', '🌻', '🍁'],
  ['🔴', '🔵', '🟡', '🟢'],
];

/// What comes next in the pattern?
QuizQuestion patternsQuiz(GenContext ctx) {
  final rng = ctx.rng;
  final templates = <String>[
    'AB',
    if (ctx.tier >= 2) 'AAB',
    if (ctx.tier >= 3) 'ABB',
    if (ctx.tier >= 4) 'ABC',
    if (ctx.tier >= 6) 'AABB',
    if (ctx.tier >= 7) 'ABCD',
    if (ctx.tier >= 8) 'ABAC',
  ];
  final template = rng.pick(templates);
  final letters = template.split('').toSet().toList();
  late List<_Unit> units;
  if (rng.nextBool()) {
    final theme = rng.pick(_patternThemes);
    units = rng.sample(theme, letters.length).map(_Unit.emoji).toList();
  } else {
    final shapes = rng.sample(_basicShapes, letters.length);
    final colors = rng.sample(AppColors.playful, letters.length);
    units = [for (var i = 0; i < letters.length; i++) _Unit.shape(shapes[i], colors[i])];
  }
  final shownLength = template.length * 2 + (ctx.tier >= 6 ? rng.nextInt(template.length) : 0);
  _Unit at(int i) => units[letters.indexOf(template[i % template.length])];
  final shown = [for (var i = 0; i < shownLength; i++) at(i)];
  final answer = at(shownLength);
  final wrong = units.where((u) => u.id != answer.id).toList();
  if (wrong.length < 2) {
    // Add an extra unit so there are at least three choices.
    final theme = _patternThemes.firstWhere((t) => !t.contains(units.first.emoji), orElse: () => _patternThemes.last);
    wrong.add(_Unit.emoji(theme.first));
  }
  final size = shownLength > 8 ? 34.0 : 44.0;
  return QuizQuestion.shuffled<_Unit>(
    rng: rng,
    prompt: 'What comes next?',
    speech: 'Look at the pattern. What comes next?',
    visual: (_) => PatternRow(items: [for (final u in shown) u.build(size)], size: size),
    correct: answer,
    wrong: rng.sample(wrong, ctx.tier <= 1 ? 1 : 2),
    toChoice: (u) => QuizChoice(builder: (_) => u.build(64), speech: u.speech),
    key: 'pattern-$template-${shown.map((u) => u.id).join()}',
  );
}

/// Which one does not belong?
QuizQuestion oddOneOut(GenContext ctx) {
  final rng = ctx.rng;
  final pair = rng.sample(categories, 2);
  final main = pair[0];
  final odd = pair[1];
  final sameCount = ctx.tier <= 1 ? 2 : 3;
  final same = rng.sample(main.items, sameCount);
  final oddItem = rng.pick(odd.items);
  // Avoid pictures that belong to both groups (e.g. an emoji reused).
  if (main.items.any((i) => i.emoji == oddItem.emoji)) return oddOneOut(ctx);
  return QuizQuestion.shuffled<PicWord>(
    rng: rng,
    prompt: 'Which one does not belong?',
    speech: "Which one doesn't belong with the others?",
    correct: oddItem,
    wrong: same,
    toChoice: (w) => picChoice(w, showLabel: ctx.tier >= 3),
    key: 'odd-${oddItem.word}-${main.name}',
    explanation: 'The others are all ${main.name}!',
  );
}

/// Biggest / smallest.
QuizQuestion sizeSort(GenContext ctx) {
  final rng = ctx.rng;
  final thing = rng.pick(const ['🐘', '🍎', '🐻', '⭐', '🎈', '🐟', '🌳', '🚗', '🐢', '🍩']);
  final biggest = rng.nextBool();
  final count = ctx.tier <= 1 ? 3 : 4;
  final sizes = [for (var i = 0; i < count; i++) 34.0 + i * (60.0 / (count - 1))];
  final target = biggest ? sizes.last : sizes.first;
  return QuizQuestion.shuffled<double>(
    rng: rng,
    prompt: biggest ? 'Tap the BIGGEST one!' : 'Tap the SMALLEST one!',
    speech: biggest ? 'Which one is the biggest?' : 'Which one is the smallest?',
    correct: target,
    wrong: sizes.where((s) => s != target).toList(),
    toChoice: (s) => QuizChoice(
      builder: (_) => SizedBox(height: 100, child: Center(child: EmojiText(thing, size: s))),
      speech: s == sizes.last ? 'big' : (s == sizes.first ? 'small' : ''),
    ),
    key: 'size-$thing-$biggest',
    explanation: biggest ? 'That is the biggest!' : 'That is the smallest!',
  );
}

/// Recognise feelings.
QuizQuestion feelingsQuiz(GenContext ctx) {
  final rng = ctx.rng;
  if (ctx.tier >= 2 && rng.chance(0.6)) {
    final story = rng.pick(feelingStories);
    final answer = feelings.firstWhere((f) => f.name == story.feeling);
    final wrong = rng.sample(feelings.where((f) => f.name != story.feeling).toList(), 2);
    return QuizQuestion.shuffled<Feeling>(
      rng: rng,
      prompt: story.text,
      speech: '${story.text} How would you feel?',
      visual: (_) => PictureCard(emoji: story.emoji, size: 80),
      correct: answer,
      wrong: wrong,
      toChoice: (f) => QuizChoice(emoji: f.emoji, label: f.name, speech: f.name),
      key: 'story-${story.text}',
      explanation: 'Feeling ${answer.name} is okay. Everyone has feelings!',
      promptIsReading: true,
    );
  }
  final target = rng.pick(feelings);
  final wrong = rng.sample(feelings.where((f) => f != target).toList(), ctx.tier == 0 ? 1 : 2);
  return QuizQuestion.shuffled<Feeling>(
    rng: rng,
    prompt: 'Which face looks ${target.name}?',
    correct: target,
    wrong: wrong,
    toChoice: (f) => QuizChoice(emoji: f.emoji, speech: f.name),
    key: 'face-${target.name}',
    explanation: 'That face looks ${target.name}!',
  );
}

/// "Which one can fly?" style thinking questions.
QuizQuestion thinkSort(GenContext ctx) {
  final rng = ctx.rng;
  final q = rng.pick(thinkQuestions);
  final answer = rng.pick(q.yes);
  final wrong = rng.sample(q.no, ctx.tier <= 1 ? 1 : 2);
  return QuizQuestion.shuffled<PicWord>(
    rng: rng,
    prompt: q.question,
    correct: answer,
    wrong: wrong,
    toChoice: (w) => picChoice(w, showLabel: ctx.tier >= 3),
    key: 'think-${q.question}-${answer.word}',
    explanation: '${answer.word[0].toUpperCase()}${answer.word.substring(1)}! Good thinking!',
  );
}
