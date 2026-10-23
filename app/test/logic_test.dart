import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vokabelina/data/models.dart';
import 'package:vokabelina/data/seed_words.dart';
import 'package:vokabelina/services/learner.dart';
import 'package:vokabelina/services/srs.dart';
import 'package:vokabelina/services/streak.dart';

void main() {
  group('SRS', () {
    final t0 = DateTime(2026, 10, 22, 12);

    test('good ladder: 1d → 3d → ease-scaled', () {
      final c = CardState(wordId: 'a', due: t0);
      schedule(c, Grade.good, now: t0);
      expect(c.intervalDays, 1);
      schedule(c, Grade.good, now: t0);
      expect(c.intervalDays, 3);
      schedule(c, Grade.good, now: t0);
      expect(c.intervalDays, (3 * 2.5).round());
      expect(c.due, t0.add(Duration(days: c.intervalDays)));
    });

    test('again resets progress, lowers ease (floored at 1.3) and comes back in 10 minutes', () {
      final c = CardState(wordId: 'a', due: t0);
      schedule(c, Grade.good, now: t0);
      schedule(c, Grade.again, now: t0);
      expect(c.reps, 0);
      expect(c.lapses, 1);
      expect(c.due, t0.add(const Duration(minutes: 10)));
      for (var i = 0; i < 20; i++) {
        schedule(c, Grade.again, now: t0);
      }
      expect(c.ease, 1.3);
    });

    test('easy grows faster than good', () {
      final a = CardState(wordId: 'a')..reps = 2..intervalDays = 6;
      final b = CardState(wordId: 'b')..reps = 2..intervalDays = 6;
      schedule(a, Grade.good, now: t0);
      schedule(b, Grade.easy, now: t0);
      expect(b.intervalDays, greaterThan(a.intervalDays));
    });

    test('intervalLabel previews without mutating', () {
      final c = CardState(wordId: 'a');
      expect(intervalLabel(c, Grade.again), '10 min');
      expect(c.reps, 0);
    });
  });

  group('streak', () {
    test('consecutive days build a streak, gaps reset it', () {
      var p = const Profile();
      p = awardXp(p, 10, DateTime(2026, 10, 20, 9));
      expect((p.streak, p.todayXp), (1, 10));
      p = awardXp(p, 5, DateTime(2026, 10, 20, 18));
      expect((p.streak, p.todayXp, p.xp), (1, 15, 15));
      p = awardXp(p, 5, DateTime(2026, 10, 21, 8));
      expect((p.streak, p.todayXp), (2, 5));
      p = awardXp(p, 5, DateTime(2026, 10, 24, 8));
      expect(p.streak, 1);
    });
    test('liveStreak shows 0 after a missed day', () {
      final p = const Profile(streak: 7, lastActiveDay: '2026-10-20');
      expect(liveStreak(p, DateTime(2026, 10, 21, 8)), 7);
      expect(liveStreak(p, DateTime(2026, 10, 22, 8)), 0);
      expect(liveTodayXp(p.copyWith(todayXp: 30), DateTime(2026, 10, 22)), 0);
    });
  });

  group('seed words', () {
    test('are unique, complete and ids are slug-safe', () {
      final ids = seedWords.map((w) => w.id).toSet();
      expect(ids.length, seedWords.length);
      for (final w in seedWords) {
        expect(w.en, isNotEmpty, reason: w.de);
        expect(w.tr, isNotEmpty, reason: w.de);
        expect(levels, contains(w.level));
        expect(RegExp(r'^[a-z0-9_]+$').hasMatch(w.id), isTrue, reason: w.id);
      }
    });
    test('lemma strips the article', () {
      expect(const Word(id: 'x', de: 'der Tisch', en: '', tr: '').lemma, 'tisch');
      expect(const Word(id: 'x', de: 'gehen', en: '', tr: '').lemma, 'gehen');
    });
  });

  group('Learner', () {
    Map<String, Word> words() => {for (final w in seedWords) w.id: w};

    test('pickWeak prefers words with a poor record (Thompson sampling)', () {
      final cards = {
        'tisch': CardState(wordId: 'der_tisch')..successes = 30..failures = 1..reps = 1,
        'stuhl': CardState(wordId: 'der_stuhl')..successes = 1..failures = 12..reps = 1,
      };
      final l = Learner(words(), {for (final c in cards.values) c.wordId: c}, const LearnerMemory());
      var weakFirst = 0;
      for (var i = 0; i < 200; i++) {
        if (l.pickWeak(1, rng: Random(i)).first.id == 'der_stuhl') weakFirst++;
      }
      expect(weakFirst, greaterThan(190));
    });

    test('never-reviewed cards are not treated as weak', () {
      final l = Learner(words(), {'der_tisch': CardState(wordId: 'der_tisch')}, const LearnerMemory());
      expect(l.pickWeak(3), isEmpty);
    });

    test('payload carries known/weak/mistakes/facts', () {
      final cards = {
        'der_tisch': CardState(wordId: 'der_tisch')..reps = 4..intervalDays = 20..successes = 4,
        'der_stuhl': CardState(wordId: 'der_stuhl')..successes = 0..failures = 3..reps = 1,
      };
      final now = DateTime(2026, 10, 22);
      final mem = LearnerMemory(
        facts: [MemoryFact(text: 'likes football', firstSeen: now, lastSeen: now)],
        mistakes: {'de|dative': MistakePattern(lang: 'de', tag: 'dative', explanation: 'mit + Dativ', examples: ['mit der Bus → mit dem Bus'], count: 3, lastSeen: now)},
        interests: ['football'],
      );
      final l = Learner(words(), cards, mem, lang: 'de', now: now);
      final p = l.toPayload();
      expect(p['known'], ['der Tisch']);
      expect(p['weak'], ['der Stuhl']);
      expect(p['mistakes'], ['dative: mit + Dativ (e.g. mit der Bus → mit dem Bus)']);
      expect(p['facts'], ['likes football']);
      expect(p['interests'], ['football']);
      // the same deck seen by an English learner uses English words
      final en = Learner(words(), {for (final c in cards.values) c.wordId: c}, mem, lang: 'en', now: now);
      expect(en.toPayload()['known'], ['table']);
      expect(en.toPayload()['mistakes'], isEmpty);
    });

    test('trackedWordIdsIn matches lemmas and verbs case-insensitively', () {
      final cards = {for (final id in ['der_tisch', 'gehen', 'das_brot']) id: CardState(wordId: id)};
      final l = Learner(words(), cards, const LearnerMemory());
      expect(l.trackedWordIdsIn('Der TISCH ist groß und ich gehe'), {'der_tisch'});
      expect(l.trackedWordIdsIn('Wir gehen, mit Brot.'), {'gehen', 'das_brot'});
    });
  });
}

