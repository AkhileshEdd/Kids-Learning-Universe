import '../models/grade.dart';
import 'generators/math_generators.dart';
import 'generators/puzzle_generators.dart';
import 'generators/reading_generators.dart';
import 'quiz.dart';
import 'subjects.dart';

enum ActivityKind { quiz, explorer, tracing, memory, wordBuilder, bubblePop, drawing, coloring }

class ActivityDef {
  const ActivityDef({
    required this.id,
    required this.title,
    required this.subject,
    required this.emoji,
    required this.kind,
    required this.intro,
    this.minGrade = Grade.preschool,
    this.maxGrade = Grade.grade2,
    this.premium = false,
    this.generator,
    this.variant,
    this.skill,
  });

  final String id;
  final String title;
  final SubjectId subject;
  final String emoji;
  final ActivityKind kind;

  /// Spoken when the activity starts.
  final String intro;
  final Grade minGrade;
  final Grade maxGrade;
  final bool premium;
  final QuizGenerator? generator;

  /// Extra configuration for non-quiz games (e.g. which glyphs to trace).
  final String? variant;
  final String? skill;

  String get skillKey => skill ?? id;
  Subject get subjectInfo => subjects[subject]!;
  bool fitsGrade(Grade g) => g >= minGrade && g <= maxGrade;

  /// Whether this counts as "practice" in reports (drawing does not).
  bool get isScored => kind != ActivityKind.drawing && kind != ActivityKind.coloring && kind != ActivityKind.explorer;
}

const activities = <ActivityDef>[
  // ---------------------------------------------------------------- Reading
  ActivityDef(
    id: 'abc_explorer',
    title: 'ABC Explorer',
    subject: SubjectId.reading,
    emoji: '🔤',
    kind: ActivityKind.explorer,
    intro: "Let's meet the letters! Tap a letter to hear it.",
    maxGrade: Grade.grade1,
    variant: 'letters',
  ),
  ActivityDef(
    id: 'letter_find',
    title: 'Find the Letter',
    subject: SubjectId.reading,
    emoji: '🔍',
    kind: ActivityKind.quiz,
    intro: 'Listen carefully and find the letter!',
    maxGrade: Grade.kindergarten,
    generator: letterFind,
  ),
  ActivityDef(
    id: 'letter_pop',
    title: 'Letter Pop',
    subject: SubjectId.reading,
    emoji: '🫧',
    kind: ActivityKind.bubblePop,
    intro: 'Pop the bubbles with the right letter!',
    maxGrade: Grade.kindergarten,
    variant: 'letters',
    skill: 'letter_find',
  ),
  ActivityDef(
    id: 'trace_upper',
    title: 'Trace ABC',
    subject: SubjectId.reading,
    emoji: '✍️',
    kind: ActivityKind.tracing,
    intro: 'Trace the letter with your finger. Start at the green dot!',
    maxGrade: Grade.grade1,
    variant: 'upper',
  ),
  ActivityDef(
    id: 'trace_lower',
    title: 'Trace abc',
    subject: SubjectId.reading,
    emoji: '🖍️',
    kind: ActivityKind.tracing,
    intro: 'Trace the little letter. Start at the green dot!',
    minGrade: Grade.kindergarten,
    maxGrade: Grade.grade1,
    variant: 'lower',
    premium: true,
  ),
  ActivityDef(
    id: 'upper_lower',
    title: 'Big & Little',
    subject: SubjectId.reading,
    emoji: '🔠',
    kind: ActivityKind.quiz,
    intro: 'Every big letter has a little letter friend. Let’s match them!',
    minGrade: Grade.kindergarten,
    maxGrade: Grade.grade1,
    generator: upperLower,
  ),
  ActivityDef(
    id: 'first_sounds',
    title: 'First Sounds',
    subject: SubjectId.reading,
    emoji: '👂',
    kind: ActivityKind.quiz,
    intro: 'Say the word. What sound does it start with?',
    minGrade: Grade.kindergarten,
    maxGrade: Grade.grade1,
    generator: firstSounds,
  ),
  ActivityDef(
    id: 'sight_words',
    title: 'Sight Word Stars',
    subject: SubjectId.reading,
    emoji: '👀',
    kind: ActivityKind.quiz,
    intro: 'Listen to the word, then find it!',
    minGrade: Grade.kindergarten,
    generator: sightWords,
  ),
  ActivityDef(
    id: 'word_builder',
    title: 'Word Builder',
    subject: SubjectId.reading,
    emoji: '🧱',
    kind: ActivityKind.wordBuilder,
    intro: 'Build the word! Tap the letters in the right order.',
    minGrade: Grade.kindergarten,
  ),
  ActivityDef(
    id: 'read_match',
    title: 'Read & Match',
    subject: SubjectId.reading,
    emoji: '📖',
    kind: ActivityKind.quiz,
    intro: 'Read the word and find the matching picture!',
    minGrade: Grade.kindergarten,
    generator: readMatch,
  ),
  ActivityDef(
    id: 'rhyme_time',
    title: 'Rhyme Time',
    subject: SubjectId.reading,
    emoji: '🎵',
    kind: ActivityKind.quiz,
    intro: 'Words that rhyme sound the same at the end. Cat, hat! Let’s find rhymes!',
    minGrade: Grade.kindergarten,
    generator: rhymeTime,
    premium: true,
  ),
  ActivityDef(
    id: 'missing_letter',
    title: 'Missing Letter',
    subject: SubjectId.reading,
    emoji: '❓',
    kind: ActivityKind.quiz,
    intro: 'Oh no, a letter fell out! Can you find it?',
    minGrade: Grade.grade1,
    generator: missingLetter,
  ),
  ActivityDef(
    id: 'opposites',
    title: 'Opposites',
    subject: SubjectId.reading,
    emoji: '↔️',
    kind: ActivityKind.quiz,
    intro: 'Hot and cold are opposites. Let’s find more opposites!',
    minGrade: Grade.kindergarten,
    generator: oppositesQuiz,
    premium: true,
  ),
  ActivityDef(
    id: 'story_questions',
    title: 'Story Questions',
    subject: SubjectId.reading,
    emoji: '💭',
    kind: ActivityKind.quiz,
    intro: 'Read the little story, then answer the question.',
    minGrade: Grade.grade1,
    generator: comprehension,
    premium: true,
  ),

  // ---------------------------------------------------------------- Math
  ActivityDef(
    id: 'count_objects',
    title: 'Count It!',
    subject: SubjectId.math,
    emoji: '🍎',
    kind: ActivityKind.quiz,
    intro: 'Let’s count! Tap each one as you count.',
    maxGrade: Grade.grade1,
    generator: countObjects,
  ),
  ActivityDef(
    id: 'number_find',
    title: 'Find the Number',
    subject: SubjectId.math,
    emoji: '🔢',
    kind: ActivityKind.quiz,
    intro: 'Listen and find the number!',
    maxGrade: Grade.grade1,
    generator: numberFind,
  ),
  ActivityDef(
    id: 'number_pop',
    title: 'Number Pop',
    subject: SubjectId.math,
    emoji: '🎈',
    kind: ActivityKind.bubblePop,
    intro: 'Pop the bubbles with the right number!',
    maxGrade: Grade.grade1,
    variant: 'numbers',
    skill: 'number_find',
  ),
  ActivityDef(
    id: 'trace_numbers',
    title: 'Trace 123',
    subject: SubjectId.math,
    emoji: '✏️',
    kind: ActivityKind.tracing,
    intro: 'Trace the number. Start at the green dot!',
    maxGrade: Grade.kindergarten,
    variant: 'digits',
  ),
  ActivityDef(
    id: 'more_less',
    title: 'More or Less',
    subject: SubjectId.math,
    emoji: '⚖️',
    kind: ActivityKind.quiz,
    intro: 'Which is more? Which is less? Let’s compare!',
    generator: moreLess,
  ),
  ActivityDef(
    id: 'add_pictures',
    title: 'Adding Apples',
    subject: SubjectId.math,
    emoji: '➕',
    kind: ActivityKind.quiz,
    intro: 'Put the groups together. How many in all?',
    maxGrade: Grade.grade1,
    generator: addPictures,
  ),
  ActivityDef(
    id: 'take_away',
    title: 'Take Away',
    subject: SubjectId.math,
    emoji: '➖',
    kind: ActivityKind.quiz,
    intro: 'Some go away. How many are left?',
    minGrade: Grade.kindergarten,
    maxGrade: Grade.grade1,
    generator: subtractPictures,
    premium: true,
  ),
  ActivityDef(
    id: 'addition',
    title: 'Addition Blast',
    subject: SubjectId.math,
    emoji: '🚀',
    kind: ActivityKind.quiz,
    intro: 'Blast off with addition!',
    minGrade: Grade.kindergarten,
    generator: addition,
  ),
  ActivityDef(
    id: 'subtraction',
    title: 'Subtraction Splash',
    subject: SubjectId.math,
    emoji: '💦',
    kind: ActivityKind.quiz,
    intro: 'Let’s subtract! Take away and find what is left.',
    minGrade: Grade.grade1,
    generator: subtraction,
  ),
  ActivityDef(
    id: 'missing_number',
    title: 'What’s Missing?',
    subject: SubjectId.math,
    emoji: '🧮',
    kind: ActivityKind.quiz,
    intro: 'Numbers go in order. Which one is missing?',
    minGrade: Grade.kindergarten,
    generator: missingNumber,
  ),
  ActivityDef(
    id: 'place_value',
    title: 'Tens & Ones',
    subject: SubjectId.math,
    emoji: '🧊',
    kind: ActivityKind.quiz,
    intro: 'Long blocks are tens. Little blocks are ones. Let’s build numbers!',
    minGrade: Grade.grade1,
    generator: placeValue,
    premium: true,
  ),
  ActivityDef(
    id: 'tell_time',
    title: 'Clock Time',
    subject: SubjectId.math,
    emoji: '⏰',
    kind: ActivityKind.quiz,
    intro: 'The short hand shows the hour. The long hand shows the minutes. What time is it?',
    minGrade: Grade.grade1,
    generator: tellTime,
    premium: true,
  ),
  ActivityDef(
    id: 'word_problems',
    title: 'Story Problems',
    subject: SubjectId.math,
    emoji: '📝',
    kind: ActivityKind.quiz,
    intro: 'Listen to the story and solve the problem!',
    minGrade: Grade.grade1,
    generator: wordProblem,
    premium: true,
  ),

  // ---------------------------------------------------------------- Thinking
  ActivityDef(
    id: 'colors',
    title: 'Color Fun',
    subject: SubjectId.puzzles,
    emoji: '🌈',
    kind: ActivityKind.quiz,
    intro: 'Colors are everywhere! Let’s find them.',
    maxGrade: Grade.kindergarten,
    generator: colorsQuiz,
  ),
  ActivityDef(
    id: 'shapes',
    title: 'Shape Safari',
    subject: SubjectId.puzzles,
    emoji: '🔺',
    kind: ActivityKind.quiz,
    intro: 'Let’s go on a shape hunt!',
    generator: shapesQuiz,
  ),
  ActivityDef(
    id: 'patterns',
    title: 'Pattern Train',
    subject: SubjectId.puzzles,
    emoji: '🚂',
    kind: ActivityKind.quiz,
    intro: 'Patterns repeat again and again. What comes next?',
    generator: patternsQuiz,
  ),
  ActivityDef(
    id: 'memory',
    title: 'Memory Match',
    subject: SubjectId.puzzles,
    emoji: '🃏',
    kind: ActivityKind.memory,
    intro: 'Flip two cards. Can you find the matching pairs?',
  ),
  ActivityDef(
    id: 'odd_one_out',
    title: 'Odd One Out',
    subject: SubjectId.puzzles,
    emoji: '🤔',
    kind: ActivityKind.quiz,
    intro: 'One of these is different. Which one does not belong?',
    maxGrade: Grade.grade1,
    generator: oddOneOut,
  ),
  ActivityDef(
    id: 'big_small',
    title: 'Big & Small',
    subject: SubjectId.puzzles,
    emoji: '🐘',
    kind: ActivityKind.quiz,
    intro: 'Some things are big and some are small!',
    maxGrade: Grade.kindergarten,
    generator: sizeSort,
  ),
  ActivityDef(
    id: 'feelings',
    title: 'Feelings',
    subject: SubjectId.puzzles,
    emoji: '😊',
    kind: ActivityKind.quiz,
    intro: 'Everyone has feelings. Let’s learn about them!',
    maxGrade: Grade.grade1,
    generator: feelingsQuiz,
  ),
  ActivityDef(
    id: 'think_sort',
    title: 'Think & Sort',
    subject: SubjectId.puzzles,
    emoji: '💡',
    kind: ActivityKind.quiz,
    intro: 'Put on your thinking cap!',
    maxGrade: Grade.grade1,
    generator: thinkSort,
    premium: true,
  ),

  // ---------------------------------------------------------------- Art
  ActivityDef(
    id: 'drawing',
    title: 'Magic Drawing',
    subject: SubjectId.art,
    emoji: '🖌️',
    kind: ActivityKind.drawing,
    intro: 'Draw anything you like! Try the rainbow brush.',
  ),
  ActivityDef(
    id: 'coloring',
    title: 'Coloring Book',
    subject: SubjectId.art,
    emoji: '🖍️',
    kind: ActivityKind.coloring,
    intro: 'Pick a color and tap to fill the picture!',
  ),
  ActivityDef(
    id: 'art_trace_shapes',
    title: 'Trace Shapes',
    subject: SubjectId.art,
    emoji: '⭐',
    kind: ActivityKind.tracing,
    intro: 'Trace the shape with your finger!',
    maxGrade: Grade.kindergarten,
    variant: 'shapes',
  ),
];

ActivityDef? activityById(String id) {
  for (final a in activities) {
    if (a.id == id) return a;
  }
  return null;
}

List<ActivityDef> activitiesFor(SubjectId subject, Grade grade) =>
    activities.where((a) => a.subject == subject && a.fitsGrade(grade)).toList();
