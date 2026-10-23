import 'package:flutter_test/flutter_test.dart';
import 'package:vokabelina/data/curriculum.dart';
import 'package:vokabelina/data/grammar.dart';
import 'package:vokabelina/data/models.dart';
import 'package:vokabelina/data/vocab_bank.dart';

void main() {
  test('vocabulary bank: no duplicate ids, complete trilingual entries with pictures', () {
    final seen = <String, String>{};
    final dups = <String>[];
    for (final e in bankEntries) {
      final prev = seen[e.word.id];
      if (prev != null) dups.add('${e.word.de} (${e.unit} & $prev)');
      seen[e.word.id] = e.unit;
      expect(e.word.en, isNotEmpty, reason: e.word.de);
      expect(e.word.tr, isNotEmpty, reason: e.word.de);
      expect(e.word.emoji, isNotEmpty, reason: e.word.de);
      expect(levels, contains(e.word.level), reason: e.word.de);
      expect(RegExp(r'^[a-z0-9_]+$').hasMatch(e.word.id), isTrue, reason: e.word.id);
      if (e.word.article != null) expect(e.word.plural, isNotEmpty, reason: 'noun without plural column: ${e.word.de}');
    }
    expect(dups, isEmpty);
    expect(bankWords.length, greaterThanOrEqualTo(650));
  });

  test('every unit has words, an 8-line A/B dialogue and grammar for all three targets', () {
    expect(units.length, 29);
    for (final u in units) {
      expect(u.words.length, greaterThanOrEqualTo(18), reason: u.id);
      expect(u.phrases.length, 8, reason: u.id);
      for (final p in u.phrases) {
        expect([p.de, p.en, p.tr].every((s) => s.trim().isNotEmpty), isTrue, reason: p.id);
        expect(['A', 'B'], contains(p.speaker));
      }
      for (final t in targetLangs) {
        final g = grammarFor(t, u.id);
        expect(g, isNotNull, reason: '$t ${u.id}');
        expect(g!.examples, isNotEmpty);
        final langs = {'de': ['en', 'tr'], 'en': ['tr', 'de'], 'tr': ['en', 'de']}[t]!;
        for (final l in langs) {
          expect(g.title[l], isNotNull, reason: '$t ${u.id} title $l');
          expect(g.body[l], isNotNull, reason: '$t ${u.id} body $l');
        }
      }
      for (final k in ['en', 'tr', 'de']) {
        expect(u.title[k], isNotNull, reason: '${u.id} title $k');
        expect(u.canDo[k], isNotNull, reason: '${u.id} canDo $k');
        expect(u.writing[k], isNotNull, reason: '${u.id} writing $k');
      }
      expect(u.culture['en'], isNotNull);
      expect(u.culture['tr'], isNotNull);
    }
    // units are ordered and levels never go backwards
    for (var i = 1; i < units.length; i++) {
      expect(units[i].number, units[i - 1].number + 1);
      expect(levels.indexOf(units[i].level), greaterThanOrEqualTo(levels.indexOf(units[i - 1].level)));
    }
  });

  test('Word helpers', () {
    final w = bankWords['der_tisch']!;
    expect(w.article, 'der');
    expect(w.inLang('tr'), 'masa');
    expect(w.inLang('en'), 'table');
    expect(w.pluralForm, 'die Tische');
    expect(bankWords['gehen']!.article, isNull);
  });
}
