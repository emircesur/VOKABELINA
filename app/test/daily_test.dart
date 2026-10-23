import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vokabelina/data/models.dart';
import 'package:vokabelina/services/placement.dart';
import 'package:vokabelina/services/quests.dart';
import 'package:vokabelina/state/providers.dart';

void main() {
  group('placement', () {
    test('three questions per level, in order, answer among the options', () {
      for (final (target, native) in [('de', 'tr'), ('en', 'de'), ('tr', 'en')]) {
        final qs = buildPlacement(target: target, native: native, seed: 3);
        expect(qs.map((q) => q.level), ['A1', 'A1', 'A1', 'A2', 'A2', 'A2', 'B1', 'B1', 'B1']);
        for (final q in qs) {
          expect(q.options, contains(q.answer));
          expect(q.options.toSet(), hasLength(4));
          expect(q.prompt.toLowerCase(), isNot(q.answer.toLowerCase()), reason: 'cognates are skipped');
        }
      }
    });

    test('scoring: two of three per level, stacked', () {
      expect(placementLevel({}), 'A1');
      expect(placementLevel({'A1': 3, 'A2': 1, 'B1': 3}), 'A1');
      expect(placementLevel({'A1': 2, 'A2': 2}), 'A2');
      expect(placementLevel({'A1': 3, 'A2': 3, 'B1': 1}), 'A2');
      expect(placementLevel({'A1': 1, 'A2': 2, 'B1': 2}), 'B1');
      expect(placementLevel({'A1': 3, 'A2': 3, 'B1': 3}), 'B1');
    });
  });

  group('daily quests', () {
    test('same three quests all day, daily goal first, distinct metrics', () {
      final a = questsFor('2026-10-23', 50);
      expect([for (final q in a) q.id], [for (final q in questsFor('2026-10-23', 50)) q.id]);
      expect(a, hasLength(3));
      expect(a.first.metric, Metric.xp);
      expect(a.first.target, 50);
      expect(a.map((q) => q.metric).toSet(), hasLength(3));
      final week = {for (var d = 1; d <= 14; d++) questsFor('2026-11-${d.toString().padLeft(2, '0')}', 50).map((q) => q.id).join()};
      expect(week.length, greaterThan(3), reason: 'quests vary from day to day');
    });

    test('word of the day is stable and near the level', () {
      final w = wordOfTheDay('2026-10-23', 'A2');
      expect(wordOfTheDay('2026-10-23', 'A2').id, w.id);
      expect(['A1', 'A2'], contains(w.level));
      expect(w.emoji, isNotEmpty);
    });

    test('counters reset each day; claim pays once and only when done', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var now = DateTime(2026, 10, 23, 9);
      final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), clockProvider.overrideWithValue(() => now)]);
      addTearDown(c.dispose);
      c.read(profileProvider.notifier).set(const Profile(onboarded: true));
      final d = c.read(dailyProvider.notifier);
      const q = Quest('t', Metric.reviews, 3, '🃏', 'x', 'x', 'x');

      d.bump(Metric.reviews, 2);
      expect(d.progress(q), 2);
      expect(d.claim(q), isFalse);
      d.bump(Metric.reviews);
      expect(d.progress(q), 3);
      final xp = c.read(profileProvider).xp;
      expect(d.claim(q), isTrue);
      expect(d.claim(q), isFalse);
      expect(c.read(profileProvider).xp, xp + q.reward);
      expect(prefs.getString('daily'), contains('"reviews":3'));

      now = DateTime(2026, 10, 24, 9);
      expect(d.progress(q), 0);
      d.bump(Metric.reviews, 5);
      expect(c.read(dailyProvider).day, '2026-10-24');
      expect(c.read(dailyProvider).claimed, isEmpty);
    });
  });
}
