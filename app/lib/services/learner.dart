import 'dart:math';

import '../data/models.dart';

/// Learner model for one target language: turns SRS state + long-term memory
/// into the "memory" payload the AI receives, and decides which words the tutor
/// should practise next.
class Learner {
  Learner(this.words, this.cards, this.memory, {this.lang = 'de', DateTime? now}) : now = now ?? DateTime.now();

  final Map<String, Word> words;

  /// Cards of [lang] keyed by word id.
  final Map<String, CardState> cards;
  final LearnerMemory memory;
  final String lang;
  final DateTime now;

  List<Word> get known => [
        for (final c in cards.values)
          if (c.isKnown && words[c.wordId] != null) words[c.wordId]!
      ];

  /// Thompson sampling over each started word's success rate: words we are
  /// *uncertain or weak* about get sampled low and are picked first. This is the
  /// explore/exploit policy that decides what the tutor and practice sessions use.
  List<Word> pickWeak(int n, {Random? rng}) {
    final r = rng ?? Random();
    final scored = <(double, Word)>[];
    for (final c in cards.values) {
      final w = words[c.wordId];
      if (w == null || c.successes + c.failures == 0) continue;
      // well-known words with a clean record need no extra practice
      if (c.isKnown && c.failures * 3 <= c.successes) continue;
      scored.add((_betaSample(c.successes + 1, c.failures + 1, r), w));
    }
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    return [for (final s in scored.take(n)) s.$2];
  }

  /// Share of [level] catalogue words that are known (0..1).
  double levelProgress(String level) {
    final inLevel = words.values.where((w) => w.level == level && !w.custom).toList();
    if (inLevel.isEmpty) return 0;
    final knownCount = inLevel.where((w) => cards[w.id]?.isKnown ?? false).length;
    return knownCount / inLevel.length;
  }

  /// What the AI gets about the learner (compact, ranked, language-specific).
  Map<String, dynamic> toPayload() => {
        'known': [for (final w in known.take(60)) w.inLang(lang)],
        'weak': [for (final w in pickWeak(6)) w.inLang(lang)],
        'mistakes': [
          for (final m in memory.topMistakes(lang, now, 6)) m.examples.isEmpty ? '${m.tag}: ${m.explanation}' : '${m.tag}: ${m.explanation} (e.g. ${m.examples.first})'
        ],
        'facts': [for (final f in (memory.facts.toList()..sort((a, b) => b.lastSeen.compareTo(a.lastSeen))).take(15)) f.text],
        'interests': memory.interests.take(8).toList(),
        'goals': memory.goals.take(5).toList(),
        if (memory.summary.isNotEmpty) 'summary': memory.summary,
        if (memory.focus.isNotEmpty) 'focus': memory.focus.take(4).toList(),
      };

  /// Words in [text] that the learner tracks in [lang] (case-insensitive).
  Set<String> trackedWordIdsIn(String text) {
    final tokens = RegExp(r'[\p{L}]+', unicode: true).allMatches(text).map((m) => m.group(0)!.toLowerCase()).toSet();
    final lower = text.toLowerCase();
    final out = <String>{};
    for (final c in cards.values) {
      final w = words[c.wordId];
      if (w == null) continue;
      if (lang == 'de') {
        if (tokens.contains(w.lemma) || tokens.contains(w.de.toLowerCase())) out.add(c.wordId);
      } else {
        for (final alt in w.inLang(lang).toLowerCase().split(RegExp(r'\s*/\s*'))) {
          final a = alt.replaceAll(RegExp(r'\(.*?\)'), '').trim();
          if (a.isEmpty) continue;
          if (a.contains(' ') ? lower.contains(a) : tokens.contains(a)) {
            out.add(c.wordId);
            break;
          }
        }
      }
    }
    return out;
  }
}

// ---- Beta sampling (Gamma via Marsaglia-Tsang) ----

double _betaSample(int a, int b, Random r) {
  final x = _gamma(a.toDouble(), r);
  final y = _gamma(b.toDouble(), r);
  return x / (x + y);
}

double _gamma(double k, Random r) {
  if (k < 1) return _gamma(k + 1, r) * pow(r.nextDouble(), 1 / k);
  final d = k - 1 / 3;
  final c = 1 / sqrt(9 * d);
  while (true) {
    double x, v;
    do {
      x = _normal(r);
      v = 1 + c * x;
    } while (v <= 0);
    v = v * v * v;
    final u = r.nextDouble();
    if (u < 1 - 0.0331 * x * x * x * x || log(u) < 0.5 * x * x + d * (1 - v + log(v))) return d * v;
  }
}

double _normal(Random r) {
  final u1 = 1 - r.nextDouble();
  final u2 = r.nextDouble();
  return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
}
