import 'dart:math';

import '../data/models.dart';
import '../data/vocab_bank.dart';

/// One question of the one-minute placement check: what does [word] mean?
class PlacementQuestion {
  const PlacementQuestion({required this.word, required this.prompt, required this.options, required this.answer});
  final Word word;

  /// The word in the target language.
  final String prompt;

  /// Meanings in the learner's language (one of them is [answer]).
  final List<String> options;
  final String answer;
  String get level => word.level;
}

const placementLevels = ['A1', 'A2', 'B1'];

/// Three questions per level (A1 → A2 → B1), getting harder as they go.
List<PlacementQuestion> buildPlacement({required String target, required String native, int perLevel = 3, int? seed}) {
  final r = Random(seed);
  final out = <PlacementQuestion>[];
  // skip cognates like "warm" = "warm": they test nothing
  final all = bankWords.values.where((w) => w.inLang(target).isNotEmpty && w.gloss(native).isNotEmpty && w.inLang(target).toLowerCase() != w.gloss(native).toLowerCase()).toList();
  for (final lvl in placementLevels) {
    final pool = all.where((w) => w.level == lvl).toList()..shuffle(r);
    final used = <String>{};
    for (final w in pool) {
      if (out.where((q) => q.level == lvl).length >= perLevel) break;
      final answer = w.gloss(native);
      if (!used.add(answer.toLowerCase())) continue;
      final distractors = (all.where((x) => x.gloss(native).toLowerCase() != answer.toLowerCase()).toList()..shuffle(r))
          .map((x) => x.gloss(native))
          .toSet()
          .take(3);
      out.add(PlacementQuestion(word: w, prompt: w.inLang(target), options: [answer, ...distractors]..shuffle(r), answer: answer));
    }
  }
  return out;
}

/// CEFR start level from the number of correct answers per level.
/// A level counts as "known" with 2 of 3 right; B1 also needs A2, A2 also needs A1.
String placementLevel(Map<String, int> correct) {
  final a1 = correct['A1'] ?? 0, a2 = correct['A2'] ?? 0, b1 = correct['B1'] ?? 0;
  if (a2 >= 2 && b1 >= 2) return 'B1';
  if (a1 >= 2 && a2 >= 2) return 'A2';
  return 'A1';
}
