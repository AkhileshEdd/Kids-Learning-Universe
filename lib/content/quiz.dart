import 'dart:math';

import 'package:flutter/widgets.dart';

import '../models/grade.dart';

/// Everything a question generator needs to adapt to the child.
class GenContext {
  GenContext({required this.grade, required this.level, required this.rng});

  final Grade grade;

  /// Difficulty inside the grade: 0 easy, 1 medium, 2 hard.
  final int level;
  final Random rng;

  /// Overall difficulty from 0 (youngest, easiest) to 11.
  int get tier => grade.index * 3 + level;
}

enum ChoiceLook {
  /// Big emoji with an optional caption.
  picture,

  /// Large letters, numbers or words.
  text,

  /// A custom widget (shapes, clocks, blocks...).
  custom,
}

class QuizChoice {
  const QuizChoice({
    this.label,
    this.emoji,
    this.builder,
    this.speech,
    this.readingFont = true,
    this.color,
  });

  final String? label;
  final String? emoji;
  final WidgetBuilder? builder;

  /// What the narrator says when the choice is tapped.
  final String? speech;

  /// Use the learner-friendly reading font for [label].
  final bool readingFont;
  final Color? color;

  ChoiceLook get look {
    if (builder != null) return ChoiceLook.custom;
    if (emoji != null) return ChoiceLook.picture;
    return ChoiceLook.text;
  }
}

class QuizQuestion {
  QuizQuestion({
    required this.prompt,
    String? speech,
    this.visual,
    required this.choices,
    required this.answer,
    String? key,
    this.explanation,
    this.promptIsReading = false,
  })  : speech = speech ?? prompt,
        key = key ?? prompt,
        assert(answer >= 0 && answer < choices.length);

  /// Text shown at the top of the screen.
  final String prompt;

  /// What the narrator reads out (defaults to [prompt]).
  final String speech;

  /// Optional picture area (objects to count, a clock, a passage...).
  final WidgetBuilder? visual;
  final List<QuizChoice> choices;
  final int answer;

  /// Used to avoid repeating the same question in one session.
  final String key;

  /// Said after a correct answer to reinforce the learning.
  final String? explanation;

  /// Show the prompt in the reading font (sentences to read).
  final bool promptIsReading;

  /// Builds a question from a correct option and distractors, shuffling them.
  static QuizQuestion shuffled<T>({
    required Random rng,
    required String prompt,
    String? speech,
    WidgetBuilder? visual,
    required T correct,
    required List<T> wrong,
    required QuizChoice Function(T option) toChoice,
    String? key,
    String? explanation,
    bool promptIsReading = false,
  }) {
    final options = <T>[correct, ...wrong]..shuffle(rng);
    return QuizQuestion(
      prompt: prompt,
      speech: speech,
      visual: visual,
      choices: options.map(toChoice).toList(),
      answer: options.indexOf(correct),
      key: key,
      explanation: explanation,
      promptIsReading: promptIsReading,
    );
  }
}

typedef QuizGenerator = QuizQuestion Function(GenContext ctx);
