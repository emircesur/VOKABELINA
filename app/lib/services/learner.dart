import 'dart:math';

import '../data/models.dart';

/// Learner model: turns SRS state + chat memory into the "memory" payload the AI
/// tutor receives, and decides which words the tutor should practise next.
class Learner {
  Learner(this.words, this.cards, this.memory);

  final Map<String, Word> words;
  final Map<String, CardState> cards;
  final LearnerMemory memory;

  List<Word> get known => [
        for (final c in cards.values)
          if (c.isKnown && words[c.wordId] != null) words[c.wordId]!
      ];

  /// Thompson sampling over each started word's success rate: words we are
  /// *uncertain or weak* about get sampled low and are picked first. This is the
  /// explore/exploit policy that decides what the tutor weaves into the chat.
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

  /// Estimated CEFR-ish progress 0..1 inside the current level (for the UI ring).
  double levelProgress(String level) {
    final inLevel = words.values.where((w) => w.level == level).toList();
    if (inLevel.isEmpty) return 0;
    final knownCount = inLevel.where((w) => cards[w.id]?.isKnown ?? false).length;
    return knownCount / inLevel.length;
  }

  Map<String, dynamic> toPayload() => {
        'known': [for (final w in known.take(60)) w.de],
        'weak': [for (final w in pickWeak(6)) w.de],
        'mistakes': memory.topMistakes(),
        'facts': memory.facts.take(15).toList(),
      };

  /// Words from [text] that the learner already tracks (lemma match, case-insensitive).
  Set<String> trackedWordIdsIn(String text) {
    final tokens = RegExp(r'[A-Za-zÄÖÜäöüß]+').allMatches(text).map((m) => m.group(0)!.toLowerCase()).toSet();
    return {
      for (final c in cards.values)
        if (words[c.wordId] != null && (tokens.contains(words[c.wordId]!.lemma) || tokens.contains(words[c.wordId]!.de.toLowerCase()))) c.wordId
    };
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
