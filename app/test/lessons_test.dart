import 'package:flutter_test/flutter_test.dart';
import 'package:vokabelina/data/curriculum.dart';
import 'package:vokabelina/data/models.dart';
import 'package:vokabelina/data/vocab_bank.dart';
import 'package:vokabelina/services/lessons.dart';

void main() {
  group('grading', () {
    test('typed answers: exact, case, punctuation', () {
      expect(gradeTyped('der Tisch', 'der Tisch', 'de').verdict, Verdict.correct);
      expect(gradeTyped('  DER tisch! ', 'der Tisch', 'de').verdict, Verdict.correct);
      expect(gradeTyped('der Stuhl', 'der Tisch', 'de').verdict, Verdict.wrong);
    });
    test('German nouns: missing article is "almost", wrong article is wrong', () {
      final a = gradeTyped('Tisch', 'der Tisch', 'de');
      expect((a.verdict, a.note), (Verdict.almost, 'article'));
      final b = gradeTyped('die Tisch', 'der Tisch', 'de');
      expect((b.verdict, b.note), (Verdict.wrong, 'wrongArticle'));
    });
    test('special letters and typos are tolerated with a note', () {
      expect(gradeTyped('die Strasse', 'die Straße', 'de').note, 'accents');
      expect(gradeTyped('Tschuss', 'Tschüss', 'de').note, 'accents');
      expect(gradeTyped('kopru', 'köprü', 'tr').note, 'accents');
      expect(gradeTyped('IYI', 'iyi', 'tr').verdict, Verdict.almost); // dotless I folds to i
      expect(gradeTyped('İyi', 'iyi', 'tr').verdict, Verdict.correct); // Turkish casing
      expect(gradeTyped('der Kühlschrnak', 'der Kühlschrank', 'de').note, 'typo');
    });
    test('any listed alternative is accepted, parentheses ignored', () {
      expect(gradeTyped('hello', 'good day / hello', 'en').verdict, Verdict.correct);
      expect(gradeTyped('arkadaş', 'arkadaş (erkek) / erkek arkadaş', 'tr').verdict, Verdict.correct);
    });
    test('sentences ignore punctuation', () {
      expect(gradeSentence('Ich heiße Lena und du', 'Ich heiße Lena. Und du?', 'de').verdict, Verdict.correct);
      expect(gradeSentence('Lena heiße ich', 'Ich heiße Lena.', 'de').verdict, Verdict.wrong);
    });
    test('similarity for speech', () {
      expect(similarity('ich heisse lena', 'Ich heiße Lena.', 'de'), greaterThan(0.9));
      expect(similarity('hallo', 'Ich heiße Lena.', 'de'), lessThan(0.5));
    });
    test('stars', () {
      expect(starsFor(10, 10), 3);
      expect(starsFor(8, 10), 2);
      expect(starsFor(5, 10), 1);
    });
  });

  test('tokenize strips punctuation and quotes', () {
    expect(tokenize('„Hänsel und Gretel“ ist super!'), ['Hänsel', 'und', 'Gretel', 'ist', 'super']);
  });

  group('lesson plans', () {
    test('every unit: word chunks, dialogue, grammar, review, 2 AI lessons; every word appears once', () {
      for (final u in units) {
        final ls = lessonsFor(u);
        final kinds = ls.map((l) => l.kind).toList();
        expect(kinds.where((k) => k == LessonKind.words), isNotEmpty);
        expect(kinds.sublist(kinds.length - 5), [LessonKind.dialogue, LessonKind.grammar, LessonKind.review, LessonKind.speak, LessonKind.write]);
        final ids = [for (final l in ls.where((l) => l.kind == LessonKind.words)) ...l.wordIds];
        expect(ids, u.wordIds);
        for (final l in ls.where((l) => l.kind == LessonKind.words)) {
          expect(l.wordIds.length, inInclusiveRange(3, 9), reason: l.id);
        }
      }
    });

    test('exercises build for every lesson in all three target languages', () {
      for (final target in targetLangs) {
        final native = target == 'tr' ? 'en' : 'tr';
        for (final u in units) {
          for (final l in lessonsFor(u).where((l) => !l.isAi)) {
            final ex = ExerciseBuilder(target: target, native: native, seed: 42).build(l);
            expect(ex, isNotEmpty, reason: '$target ${l.id}');
            for (final e in ex) {
              switch (e) {
                case PictureChoice(:final word, :final options):
                  expect(options.map((o) => o.id), contains(word.id));
                  expect(options.map((o) => o.emoji).toSet().length, options.length, reason: 'duplicate pictures in ${l.id}');
                case MeaningChoice(:final word, :final options):
                  expect(options.map((o) => o.id), contains(word.id));
                  expect(options.map((o) => o.inLang(target)).toSet().length, options.length);
                case ArticleChoice(:final word):
                  expect(target, 'de');
                  expect(word.article, isNotNull);
                case WordOrder(:final answer, :final tiles):
                  // all answer tokens are available as tiles
                  final pool = [...tiles];
                  for (final t in tokenize(answer)) {
                    expect(pool.remove(t), isTrue, reason: '$t missing in $tiles ($answer)');
                  }
                case Cloze(:final answer, :final options, :final before, :final after):
                  expect(options, contains(answer));
                  expect(options.toSet().length, options.length);
                  expect('$before$answer$after'.trim(), isNotEmpty);
                default:
              }
            }
          }
        }
      }
    });

    test('practice works on any words', () {
      final ws = bankWords.values.take(6).toList();
      final ex = ExerciseBuilder(target: 'en', native: 'de', seed: 1).practice(ws);
      expect(ex.whereType<MatchPairs>(), hasLength(1));
      expect(ex.length, 7);
    });
  });
}
