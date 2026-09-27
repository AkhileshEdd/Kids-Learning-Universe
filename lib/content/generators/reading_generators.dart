import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/grade.dart';
import '../../widgets/visuals.dart';
import '../quiz.dart';
import '../word_bank.dart';
import 'helpers.dart';

const _letters = 'abcdefghijklmnopqrstuvwxyz';

/// Letters children often mix up, used for harder distractors.
const _lookAlikes = {
  'b': 'dpq',
  'd': 'bpq',
  'p': 'qbd',
  'q': 'pdg',
  'm': 'nw',
  'n': 'mhu',
  'u': 'nv',
  'w': 'mv',
  'e': 'ca',
  'a': 'oe',
  'i': 'lj',
  'l': 'it',
  'h': 'nk',
  'g': 'qj',
};

List<String> _letterDistractors(GenContext ctx, String target, int count) {
  final picks = <String>{};
  final similar = _lookAlikes[target];
  if (similar != null && ctx.tier >= 4) {
    for (final c in similar.split('')) {
      if (picks.length < count - 1) picks.add(c);
    }
  }
  while (picks.length < count) {
    final c = ctx.rng.pick(_letters.split(''));
    if (c != target) picks.add(c);
  }
  return picks.toList();
}

String _say(String letter) => letter.toUpperCase();

/// Find the letter the narrator names.
QuizQuestion letterFind(GenContext ctx) {
  final upper = ctx.grade == Grade.preschool || ctx.level == 0;
  final target = ctx.rng.pick(_letters.split(''));
  final n = ctx.grade == Grade.preschool && ctx.level == 0 ? 2 : 3;
  String show(String l) => upper ? l.toUpperCase() : l;
  return QuizQuestion.shuffled<String>(
    rng: ctx.rng,
    prompt: 'Find the letter ${show(target)}',
    speech: 'Find the letter ${_say(target)}.',
    correct: target,
    wrong: _letterDistractors(ctx, target, n),
    toChoice: (l) => textChoice(show(l), speech: 'Letter ${_say(l)}'),
    key: 'find-$target',
    explanation: '${_say(target)} is for ${letterInfo(target).main.word}!',
  );
}

/// Match an uppercase letter with its lowercase partner.
QuizQuestion upperLower(GenContext ctx) {
  final target = ctx.rng.pick(_letters.split(''));
  final reverse = ctx.level == 2;
  final wrong = _letterDistractors(ctx, target, ctx.tier <= 2 ? 2 : 3);
  return QuizQuestion.shuffled<String>(
    rng: ctx.rng,
    prompt: reverse ? 'Which big letter matches?' : 'Which little letter matches?',
    speech: reverse
        ? 'This is a little ${_say(target)}. Find the big letter ${_say(target)}.'
        : 'This is a big ${_say(target)}. Find the little letter ${_say(target)}.',
    visual: (_) => BigTextCard(text: reverse ? target : target.toUpperCase(), size: 90),
    correct: target,
    wrong: wrong,
    toChoice: (l) => textChoice(reverse ? l.toUpperCase() : l, speech: 'Letter ${_say(l)}'),
    key: 'case-$target-$reverse',
  );
}

/// Which letter does the pictured word start with?
QuizQuestion firstSounds(GenContext ctx) {
  final letters = alphabet.where((l) => l.letter != 'x').toList();
  final info = ctx.rng.pick(letters);
  final word = ctx.rng.pick(info.words);
  final showUpper = ctx.grade == Grade.preschool;
  final wrong = _letterDistractors(ctx, info.letter, ctx.tier <= 3 ? 2 : 3);
  return QuizQuestion.shuffled<String>(
    rng: ctx.rng,
    prompt: 'What does ${word.word} start with?',
    speech: '${word.word}. What letter does ${word.word} start with?',
    visual: (_) => PictureCard(emoji: word.emoji, label: ctx.tier >= 6 ? null : word.word, size: 88),
    correct: info.letter,
    wrong: wrong,
    toChoice: (l) => textChoice(showUpper ? l.toUpperCase() : l, speech: 'Letter ${_say(l)}'),
    key: 'first-${word.word}',
    explanation: '${word.word} starts with ${_say(info.letter)}!',
  );
}

List<String> sightWordsFor(Grade grade) => switch (grade) {
      Grade.preschool => sightWordsPreK,
      Grade.kindergarten => [...sightWordsPreK, ...sightWordsK],
      Grade.grade1 => [...sightWordsK, ...sightWords1],
      Grade.grade2 => [...sightWords1, ...sightWords2],
    };

/// Tap the sight word the narrator says.
QuizQuestion sightWords(GenContext ctx) {
  final list = sightWordsFor(ctx.grade);
  final target = ctx.rng.pick(list);
  final count = ctx.level == 0 ? 2 : 3;
  // Harder levels prefer words that look similar (same first letter or length).
  final similar = list
      .where((w) => w != target && (w[0] == target[0] || (ctx.level == 2 && w.length == target.length)))
      .toList();
  final wrong = <String>{};
  if (ctx.level > 0 && similar.isNotEmpty) wrong.addAll(ctx.rng.sample(similar, 1));
  while (wrong.length < count) {
    final w = ctx.rng.pick(list);
    if (w != target) wrong.add(w);
  }
  return QuizQuestion.shuffled<String>(
    rng: ctx.rng,
    prompt: 'Find the word you hear',
    speech: 'Find the word: $target.',
    correct: target,
    wrong: wrong.toList(),
    toChoice: (w) => textChoice(w),
    key: 'sight-$target',
  );
}

/// Which picture rhymes with the target word?
QuizQuestion rhymeTime(GenContext ctx) {
  final group = ctx.rng.pick(rhymeGroups);
  final pair = ctx.rng.sample(group, 2);
  final target = pair[0];
  final answer = pair[1];
  final others = rhymeGroups.where((g) => g != group).toList();
  final wrong = ctx.rng.sample(others, ctx.level == 0 ? 2 : 3).map((g) => ctx.rng.pick(g)).toList();
  return QuizQuestion.shuffled<PicWord>(
    rng: ctx.rng,
    prompt: 'What rhymes with ${target.word}?',
    speech: 'Which word rhymes with ${target.word}?',
    visual: (_) => PictureCard(emoji: target.emoji, label: target.word, size: 80),
    correct: answer,
    wrong: wrong,
    toChoice: (w) => picChoice(w, showLabel: true),
    key: 'rhyme-${target.word}-${answer.word}',
    explanation: '${target.word}, ${answer.word}. They rhyme!',
  );
}

List<PicWord> readingWordsFor(GenContext ctx) {
  switch (ctx.grade) {
    case Grade.preschool:
    case Grade.kindergarten:
      return ctx.level < 2 ? cvcWords : [...cvcWords, ...shortWords];
    case Grade.grade1:
      return ctx.level == 0 ? cvcWords : shortWords;
    case Grade.grade2:
      return ctx.level == 0 ? shortWords : longWords;
  }
}

/// Read a word and pick the matching picture.
QuizQuestion readMatch(GenContext ctx) {
  final words = readingWordsFor(ctx);
  final target = ctx.rng.pick(words);
  final count = ctx.tier <= 3 ? 2 : 3;
  final similar = words.where((w) => w != target && w.word[0] == target.word[0]).toList();
  final wrong = <PicWord>{};
  if (ctx.level > 0 && similar.isNotEmpty) wrong.add(ctx.rng.pick(similar));
  while (wrong.length < count) {
    final w = ctx.rng.pick(words);
    if (w.word != target.word) wrong.add(w);
  }
  return QuizQuestion.shuffled<PicWord>(
    rng: ctx.rng,
    prompt: 'Read the word. Tap its picture!',
    speech: 'Read the word, then tap the picture that matches.',
    visual: (_) => BigTextCard(text: target.word, size: 64),
    correct: target,
    wrong: wrong.toList(),
    toChoice: (w) => picChoice(w),
    key: 'read-${target.word}',
    explanation: 'That says ${target.word}!',
  );
}

/// Fill in the missing letter of a word.
QuizQuestion missingLetter(GenContext ctx) {
  final words = ctx.grade == Grade.grade2 ? [...shortWords, ...longWords] : [...cvcWords, ...shortWords];
  final target = ctx.rng.pick(words.where((w) => !w.word.contains(' ') && !w.word.contains('-')).toList());
  final word = target.word;
  // Easier: hide a vowel in the middle. Harder: any letter.
  const vowels = 'aeiou';
  var indices = [for (var i = 0; i < word.length; i++) i];
  if (ctx.level == 0) {
    final v = indices.where((i) => vowels.contains(word[i])).toList();
    if (v.isNotEmpty) indices = v;
  }
  final hide = ctx.rng.pick(indices);
  final missing = word[hide];
  final display = [for (var i = 0; i < word.length; i++) i == hide ? '_' : word[i]].join(' ');
  final wrong = <String>{};
  final pool = vowels.contains(missing) ? vowels : 'bcdfghjklmnprstvwz';
  while (wrong.length < (ctx.level == 0 ? 2 : 3)) {
    final c = ctx.rng.pick(pool.split(''));
    if (c != missing) wrong.add(c);
  }
  return QuizQuestion.shuffled<String>(
    rng: ctx.rng,
    prompt: 'Which letter is missing?',
    speech: '$word. Which letter is missing?',
    visual: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmojiTextBig(target.emoji),
        const SizedBox(height: 8),
        BigTextCard(text: display, size: 48),
      ],
    ),
    correct: missing,
    wrong: wrong.toList(),
    toChoice: (l) => textChoice(l, speech: 'Letter ${_say(l)}'),
    key: 'missing-$word-$hide',
    explanation: '$word is spelled ${word.split('').map(_say).join(', ')}.',
  );
}

/// Find the opposite word.
QuizQuestion oppositesQuiz(GenContext ctx) {
  final pair = ctx.rng.pick(opposites);
  final flip = ctx.rng.nextBool();
  final target = flip ? pair.b : pair.a;
  final answer = flip ? pair.a : pair.b;
  final others = opposites.where((p) => p != pair).toList();
  final wrong = ctx.rng.sample(others, ctx.level == 0 ? 2 : 3).map((p) => ctx.rng.nextBool() ? p.a : p.b).toList();
  return QuizQuestion.shuffled<PicWord>(
    rng: ctx.rng,
    prompt: 'What is the opposite of ${target.word}?',
    visual: (_) => PictureCard(emoji: target.emoji, label: target.word, size: 80),
    correct: answer,
    wrong: wrong,
    toChoice: (w) => picChoice(w, showLabel: true),
    key: 'opp-${target.word}',
    explanation: 'The opposite of ${target.word} is ${answer.word}!',
  );
}

/// Read (or listen to) a short passage and answer a question.
QuizQuestion comprehension(GenContext ctx) {
  final gradeNum = ctx.grade == Grade.grade2 ? 2 : 1;
  final pool = passages.where((p) => ctx.grade == Grade.grade2 ? true : p.minGrade <= gradeNum).toList();
  final passage = ctx.rng.pick(pool);
  final q = ctx.rng.pick(passage.questions);
  final readAloud = ctx.grade != Grade.grade2 || ctx.level == 0;
  return QuizQuestion.shuffled<String>(
    rng: ctx.rng,
    prompt: q.question,
    speech: readAloud ? '${passage.text} ... ${q.question}' : q.question,
    visual: (_) => PassageCard(emoji: passage.emoji, text: passage.text),
    correct: q.answer,
    wrong: q.wrong,
    toChoice: (a) => textChoice(a),
    key: 'pass-${passages.indexOf(passage)}-${passage.questions.indexOf(q)}',
    promptIsReading: true,
  );
}

/// Large emoji without a card, used inside visuals.
class EmojiTextBig extends StatelessWidget {
  const EmojiTextBig(this.emoji, {super.key, this.size = 64});
  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => Text(emoji, style: KidText.emoji(size));
}
