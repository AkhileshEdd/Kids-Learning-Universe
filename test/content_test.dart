import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kids_learning_universe/content/activities.dart';
import 'package:kids_learning_universe/content/books.dart';
import 'package:kids_learning_universe/content/coloring_pages.dart';
import 'package:kids_learning_universe/content/quiz.dart';
import 'package:kids_learning_universe/content/stickers.dart';
import 'package:kids_learning_universe/content/tracing_glyphs.dart';
import 'package:kids_learning_universe/content/word_bank.dart';
import 'package:kids_learning_universe/core/utils.dart';
import 'package:kids_learning_universe/models/grade.dart';

String _choiceKey(QuizChoice c) {
  // Custom-drawn choices without a spoken name (pattern pieces, sizes) are
  // distinct by construction.
  if (c.builder != null && (c.speech ?? '').isEmpty) return 'custom:${identityHashCode(c)}';
  return '${c.label}|${c.emoji}|${c.speech}';
}

void main() {
  group('quiz generators', () {
    for (final activity in activities.where((a) => a.kind == ActivityKind.quiz)) {
      test('${activity.id} produces valid questions for every grade and level', () {
        for (final grade in Grade.values.where(activity.fitsGrade)) {
          for (var level = 0; level < 3; level++) {
            for (var seed = 0; seed < 80; seed++) {
              final ctx = GenContext(grade: grade, level: level, rng: Random(seed * 31 + level));
              final q = activity.generator!(ctx);
              final where = '${activity.id} ${grade.name} L$level seed $seed';
              expect(q.choices.length, inInclusiveRange(2, 4), reason: where);
              expect(q.answer, inInclusiveRange(0, q.choices.length - 1), reason: where);
              expect(q.prompt.trim(), isNotEmpty, reason: where);
              expect(q.speech.trim(), isNotEmpty, reason: where);
              final keys = q.choices.map(_choiceKey).toSet();
              expect(keys.length, q.choices.length, reason: 'duplicate choices in $where: ${q.choices.map(_choiceKey)}');
              for (final c in q.choices) {
                expect(c.label != null || c.emoji != null || c.builder != null, isTrue, reason: where);
              }
            }
          }
        }
      });
    }
  });

  test('activities have unique ids and a generator when needed', () {
    final ids = activities.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final a in activities) {
      if (a.kind == ActivityKind.quiz) expect(a.generator, isNotNull, reason: a.id);
      expect(a.minGrade.index <= a.maxGrade.index, isTrue, reason: a.id);
    }
  });

  test('every grade has free activities in each core subject', () {
    for (final grade in Grade.values) {
      for (final subject in {for (final a in activities) a.subject}) {
        final free = activitiesFor(subject, grade).where((a) => !a.premium);
        expect(free, isNotEmpty, reason: '${subject.name} ${grade.name}');
      }
    }
  });

  test('books have pages in English and Spanish', () {
    final ids = books.map((b) => b.id).toSet();
    expect(ids.length, books.length);
    for (final b in books) {
      expect(b.pages.length, greaterThanOrEqualTo(5), reason: b.id);
      for (final p in b.pages) {
        expect(p.en.trim(), isNotEmpty);
        expect(p.es.trim(), isNotEmpty);
        expect(p.scene.sprites, isNotEmpty, reason: '${b.id}: ${p.en}');
      }
    }
    expect(books.where((b) => !b.premium).length, greaterThanOrEqualTo(5));
  });

  test('sticker packs contain unique stickers', () {
    final all = [for (final p in stickerPacks) ...p.stickers];
    expect(all.toSet().length, all.length);
  });

  test('tracing glyphs have strokes with sample points inside the box', () {
    for (final set in [upperGlyphs(), lowerGlyphs(), digitGlyphs(), shapeGlyphs()]) {
      for (final g in set) {
        expect(g.strokes, isNotEmpty, reason: g.label);
        for (final s in g.strokes) {
          final pts = samplePath(s);
          expect(pts.length, greaterThanOrEqualTo(2), reason: g.label);
          for (final p in pts) {
            expect(p.dx, inInclusiveRange(-2, 102), reason: g.label);
            expect(p.dy, inInclusiveRange(-2, 102), reason: g.label);
          }
        }
      }
    }
    expect(upperGlyphs().length, 26);
    expect(lowerGlyphs().length, 26);
    expect(digitGlyphs().length, 10);
  });

  test('coloring pages build regions', () {
    for (final page in coloringPages) {
      final regions = page.build();
      expect(regions.length, greaterThanOrEqualTo(5), reason: page.id);
    }
  });

  test('alphabet covers every letter with pictures', () {
    expect(alphabet.map((l) => l.letter).join(), 'abcdefghijklmnopqrstuvwxyz');
    for (final l in alphabet) {
      expect(l.words, isNotEmpty);
    }
  });

  test('number words and plurals', () {
    expect(numberWord(0), 'zero');
    expect(numberWord(15), 'fifteen');
    expect(numberWord(42), 'forty-two');
    expect(numberWord(300), 'three hundred');
    expect(numberWord(718), 'seven hundred eighteen');
    expect(pluralize('fish', 2), 'fish');
    expect(pluralize('strawberry', 3), 'strawberries');
    expect(pluralize('box', 2), 'boxes');
    expect(pluralize('apple', 1), 'apple');
  });
}
