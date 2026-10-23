import 'dart:math';

import '../data/curriculum.dart';
import '../data/grammar.dart';
import '../data/models.dart';
import '../data/vocab_bank.dart';

// ------------------------------------------------------------------ lessons

enum LessonKind { words, dialogue, grammar, review, speak, write }

class LessonSpec {
  const LessonSpec({required this.id, required this.unitId, required this.kind, this.part = 0, this.wordIds = const []});
  final String id;
  final String unitId;
  final LessonKind kind;

  /// 1-based part number for multi-part word lessons.
  final int part;
  final List<String> wordIds;

  /// AI lessons are bonus: they need the server and don't block progress.
  bool get isAi => kind == LessonKind.speak || kind == LessonKind.write;
  bool get required => !isAi;

  Unit get unit => unitsById[unitId]!;

  @override
  bool operator ==(Object other) => other is LessonSpec && other.id == id;
  @override
  int get hashCode => id.hashCode;
}

final _lessonCache = <String, List<LessonSpec>>{};

/// Busuu-style unit: vocabulary in small chunks → dialogue → grammar → review,
/// plus AI speaking (role-play) and AI-corrected writing.
List<LessonSpec> lessonsFor(Unit u, {int chunk = 7}) => _lessonCache.putIfAbsent('${u.id}/$chunk', () => _buildLessons(u, chunk));

List<LessonSpec> _buildLessons(Unit u, int chunk) {
  final ids = u.wordIds;
  final parts = <List<String>>[];
  for (var i = 0; i < ids.length; i += chunk) {
    parts.add(ids.sublist(i, min(i + chunk, ids.length)));
  }
  // avoid a tiny tail lesson
  if (parts.length > 1 && parts.last.length < 3) {
    final tail = parts.removeLast();
    parts.last = [...parts.last, ...tail];
  }
  return [
    for (var i = 0; i < parts.length; i++) LessonSpec(id: '${u.id}_w${i + 1}', unitId: u.id, kind: LessonKind.words, part: i + 1, wordIds: parts[i]),
    LessonSpec(id: '${u.id}_dialog', unitId: u.id, kind: LessonKind.dialogue),
    LessonSpec(id: '${u.id}_grammar', unitId: u.id, kind: LessonKind.grammar),
    LessonSpec(id: '${u.id}_review', unitId: u.id, kind: LessonKind.review, wordIds: ids),
    LessonSpec(id: '${u.id}_speak', unitId: u.id, kind: LessonKind.speak),
    LessonSpec(id: '${u.id}_write', unitId: u.id, kind: LessonKind.write),
  ];
}

// ---------------------------------------------------------------- exercises

sealed class Exercise {
  const Exercise();

  /// Whether the exercise is graded (counts toward the score).
  bool get graded => true;
}

/// New word presentation (picture card).
class IntroCard extends Exercise {
  const IntroCard(this.word);
  final Word word;
  @override
  bool get graded => false;
}

/// "Which picture is `word`?"
class PictureChoice extends Exercise {
  const PictureChoice(this.word, this.options);
  final Word word;
  final List<Word> options;
}

/// Target word → choose meaning (or [reverse]: meaning → choose target word).
class MeaningChoice extends Exercise {
  const MeaningChoice(this.word, this.options, {this.reverse = false});
  final Word word;
  final List<Word> options;
  final bool reverse;
}

/// Hear the word → choose it.
class ListenChoice extends Exercise {
  const ListenChoice(this.word, this.options);
  final Word word;
  final List<Word> options;
}

/// See picture + meaning → type the target word.
class TypeAnswer extends Exercise {
  const TypeAnswer(this.word);
  final Word word;
}

/// der / die / das
class ArticleChoice extends Exercise {
  const ArticleChoice(this.word);
  final Word word;
}

/// Tap matching pairs (target ↔ meaning).
class MatchPairs extends Exercise {
  const MatchPairs(this.words);
  final List<Word> words;
}

/// Read and listen to the unit dialogue.
class DialogueRead extends Exercise {
  const DialogueRead(this.phrases);
  final List<Phrase> phrases;
  @override
  bool get graded => false;
}

/// Build the target sentence from tiles.
class WordOrder extends Exercise {
  const WordOrder({required this.answer, required this.prompt, required this.tiles, this.phrase});
  final String answer;

  /// Meaning shown to the learner ('' = listen only).
  final String prompt;
  final List<String> tiles;
  final Phrase? phrase;
}

/// Meaning → choose the right target sentence.
class PhraseChoice extends Exercise {
  const PhraseChoice(this.phrase, this.options, {this.listen = false});
  final Phrase phrase;
  final List<Phrase> options;

  /// Audio only (listening comprehension) → choose the meaning.
  final bool listen;
}

/// Sentence with one gap.
class Cloze extends Exercise {
  const Cloze({required this.before, required this.after, required this.answer, required this.options, this.translation = ''});
  final String before;
  final String after;
  final String answer;
  final List<String> options;
  final String translation;
}

class GrammarCard extends Exercise {
  const GrammarCard(this.point);
  final GrammarPoint point;
  @override
  bool get graded => false;
}

/// Say the sentence (speech recognition; skippable).
class Speak extends Exercise {
  const Speak(this.text, this.translation);
  final String text;
  final String translation;
}

class ExerciseBuilder {
  ExerciseBuilder({required this.target, required this.native, int seed = 0}) : rng = Random(seed);

  final String target;
  final String native;
  final Random rng;

  List<Exercise> build(LessonSpec spec) => switch (spec.kind) {
        LessonKind.words => _words([for (final id in spec.wordIds) bankWords[id]!], spec.unit),
        LessonKind.dialogue => _dialogue(spec.unit),
        LessonKind.grammar => _grammar(spec.unit),
        LessonKind.review => _review(spec.unit),
        _ => const [],
      };

  // --- words: present each card, check right away, then mixed recall
  List<Exercise> _words(List<Word> ws, Unit u) {
    final out = <Exercise>[];
    for (var i = 0; i < ws.length; i++) {
      out.add(IntroCard(ws[i]));
      out.add(i.isEven ? PictureChoice(ws[i], _options(ws[i], u, picture: true)) : MeaningChoice(ws[i], _options(ws[i], u)));
    }
    if (ws.length >= 3) out.add(MatchPairs((ws.toList()..shuffle(rng)).take(5).toList()));
    for (final w in ws.toList()..shuffle(rng)) {
      out.add(_recall(w, u));
    }
    return out;
  }

  Exercise _recall(Word w, Unit u) {
    final r = rng.nextInt(4);
    if (target == 'de' && w.article != null && r == 0) return ArticleChoice(w);
    if (r == 1) return ListenChoice(w, _options(w, u));
    if (r == 2) return MeaningChoice(w, _options(w, u), reverse: true);
    return TypeAnswer(w);
  }

  // --- dialogue: read along, then comprehension + production
  List<Exercise> _dialogue(Unit u) {
    final ps = u.phrases;
    if (ps.isEmpty) return const [];
    final out = <Exercise>[DialogueRead(ps)];
    final order = ps.toList()..shuffle(rng);
    for (var i = 0; i < order.length; i++) {
      final p = order[i];
      switch (i % 4) {
        case 0:
          out.add(PhraseChoice(p, _phraseOptions(p, u)));
        case 1:
          out.add(_wordOrder(p, u));
        case 2:
          out.add(PhraseChoice(p, _phraseOptions(p, u), listen: true));
        default:
          final c = _cloze(p.inLang(target), p.inLang(native), u);
          if (c != null) out.add(c);
      }
    }
    out.add(Speak(order.first.inLang(target), order.first.inLang(native)));
    return out;
  }

  // --- grammar: card, then gap-fills on the examples and sentence building
  List<Exercise> _grammar(Unit u) {
    final g = grammarFor(target, u.id);
    final out = <Exercise>[if (g != null) GrammarCard(g)];
    for (final ex in g?.examples ?? const <String>[]) {
      final c = _cloze(ex, '', u);
      if (c != null) out.add(c);
    }
    final ps = u.phrases.toList()..shuffle(rng);
    for (final p in ps.take(3)) {
      out.add(_wordOrder(p, u));
    }
    if (ps.length > 3) out.add(Speak(ps[3].inLang(target), ps[3].inLang(native)));
    return out;
  }

  // --- unit review: everything mixed
  List<Exercise> _review(Unit u) {
    final ws = u.words.toList()..shuffle(rng);
    final ps = u.phrases.toList()..shuffle(rng);
    final out = <Exercise>[MatchPairs(ws.take(5).toList())];
    for (final w in ws.skip(5).take(7)) {
      out.add(_recall(w, u));
    }
    for (final p in ps.take(3)) {
      out.add(rng.nextBool() ? _wordOrder(p, u) : PhraseChoice(p, _phraseOptions(p, u), listen: rng.nextBool()));
    }
    return out..shuffle(rng);
  }

  /// Practice session over arbitrary words (weak words, due cards).
  List<Exercise> practice(List<Word> ws) {
    final u = units.first;
    final out = <Exercise>[if (ws.length >= 3) MatchPairs(ws.take(5).toList())];
    for (final w in ws) {
      out.add(_recall(w, unitsById[w.topic] ?? u));
    }
    return out;
  }

  // --- helpers

  List<Word> _options(Word w, Unit u, {bool picture = false, int n = 4}) {
    String key(Word x) => picture ? x.emoji : '${x.inLang(target)}|${x.gloss(native)}';
    final used = {key(w)};
    final pool = [
      ...u.words.where((x) => x.id != w.id),
      ...bankWords.values.where((x) => x.level == w.level && x.topic != u.id),
    ];
    final sameKind = pool.where((x) => (x.article != null) == (w.article != null)).toList()..shuffle(rng);
    final rest = pool.toList()..shuffle(rng);
    final out = [w];
    for (final x in [...sameKind, ...rest]) {
      if (out.length >= n) break;
      final k = key(x);
      // options must look different in both languages
      if (used.contains(k) || out.any((o) => o.inLang(target) == x.inLang(target) || o.gloss(native) == x.gloss(native))) continue;
      used.add(k);
      out.add(x);
    }
    return out..shuffle(rng);
  }

  List<Phrase> _phraseOptions(Phrase p, Unit u) {
    final others = u.phrases.where((x) => x.id != p.id).toList()..shuffle(rng);
    return ([p, ...others.take(2)])..shuffle(rng);
  }

  WordOrder _wordOrder(Phrase p, Unit u) {
    final answer = p.inLang(target);
    final tokens = tokenize(answer);
    final distractors = <String>{};
    for (final o in (u.phrases.toList()..shuffle(rng))) {
      for (final t in tokenize(o.inLang(target))) {
        if (!tokens.map(_fold).contains(_fold(t))) distractors.add(t);
        if (distractors.length >= 2) break;
      }
      if (distractors.length >= 2) break;
    }
    return WordOrder(answer: answer, prompt: p.inLang(native), tiles: [...tokens, ...distractors]..shuffle(rng), phrase: p);
  }

  /// Blanks one content word (prefers unit vocabulary).
  Cloze? _cloze(String sentence, String translation, Unit u) {
    final tokens = tokenize(sentence);
    if (tokens.length < 3) return null;
    final vocab = {for (final w in u.words) _fold(Word(id: '', de: w.inLang(target), en: '', tr: '').lemma)};
    var idx = -1;
    final candidates = [for (var i = 0; i < tokens.length; i++) if (tokens[i].length > 2) i];
    for (final i in candidates) {
      if (vocab.contains(_fold(tokens[i]))) {
        idx = i;
        break;
      }
    }
    if (idx < 0) {
      if (candidates.isEmpty) return null;
      idx = candidates[rng.nextInt(candidates.length)];
    }
    final answer = tokens[idx];
    final pool = <String>{};
    for (final w in (u.words.toList()..shuffle(rng))) {
      final f = w.inLang(target).split(' ').last;
      if (_fold(f) != _fold(answer) && !f.contains(' ')) pool.add(f);
      if (pool.length >= 3) break;
    }
    final full = sentence.trim();
    final pos = _tokenOffset(full, tokens, idx);
    return Cloze(
      before: full.substring(0, pos),
      after: full.substring(pos + answer.length),
      answer: answer,
      options: [answer, ...pool]..shuffle(rng),
      translation: translation,
    );
  }

  int _tokenOffset(String s, List<String> tokens, int idx) {
    var from = 0;
    for (var i = 0; i <= idx; i++) {
      final at = s.indexOf(tokens[i], from);
      if (i == idx) return at < 0 ? 0 : at;
      from = at + tokens[i].length;
    }
    return 0;
  }
}

/// Splits a sentence into word tiles without surrounding punctuation.
List<String> tokenize(String s) => [
      for (final t in s.split(RegExp(r'\s+')))
        if (t.replaceAll(RegExp(r'''^[„“"'«»(¿¡]+|[.,!?;:…“”"'»)]+$'''), '').isNotEmpty)
          t.replaceAll(RegExp(r'''^[„“"'«»(¿¡]+|[.,!?;:…“”"'»)]+$'''), '')
    ];

// ---------------------------------------------------------------- grading

enum Verdict { correct, almost, wrong }

class AnswerGrade {
  const AnswerGrade(this.verdict, {this.note = '', this.expected = ''});
  final Verdict verdict;

  /// Why it's "almost" (typo, accents, missing article …) — UI translates the code.
  final String note;
  final String expected;
  bool get passed => verdict != Verdict.wrong;
}

String _lowerTr(String s, String lang) => lang == 'tr' ? s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase() : s.toLowerCase();

/// Lowercases and strips punctuation / extra spaces.
String normalizeAnswer(String s, String lang) => _lowerTr(s, lang)
    .replaceAll(RegExp(r'''[.,!?;:…„“”"'«»()¿¡’\-]'''), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Also folds special letters, so "Strasse" ≈ "Straße", "kopru" ≈ "köprü".
String _fold(String s) => s
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ç', 'c')
    .replaceAll('â', 'a')
    .replaceAll('î', 'i')
    .replaceAll('é', 'e');

String _foldLoose(String s) => _fold(s).replaceAll('ae', 'a').replaceAll('oe', 'o').replaceAll('ue', 'u');

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)].reduce(min);
    }
    prev = cur;
  }
  return prev[b.length];
}

/// Accepted alternatives of a gloss: "good day / hello" → [good day, hello]; drops "(male)".
List<String> alternatives(String s) => [
      for (final p in s.split(RegExp(r'\s*[/;,]\s*')))
        if (p.replaceAll(RegExp(r'\(.*?\)'), '').trim().isNotEmpty) p.replaceAll(RegExp(r'\(.*?\)'), '').trim()
    ];

/// Grades a typed answer against the expected target-language form.
AnswerGrade gradeTyped(String input, String expected, String lang) {
  final inp = normalizeAnswer(input, lang);
  if (inp.isEmpty) return AnswerGrade(Verdict.wrong, expected: expected);
  for (final alt in alternatives(expected)) {
    final exp = normalizeAnswer(alt, lang);
    if (inp == exp) return AnswerGrade(Verdict.correct, expected: expected);
    // German nouns: the article matters
    if (lang == 'de') {
      final m = RegExp(r'^(der|die|das) (.+)$').firstMatch(exp);
      if (m != null) {
        final bare = m.group(2)!;
        if (inp == bare || _fold(inp) == _fold(bare)) return AnswerGrade(Verdict.almost, note: 'article', expected: expected);
        final im = RegExp(r'^(der|die|das) (.+)$').firstMatch(inp);
        if (im != null && im.group(1) != m.group(1) && _fold(im.group(2)!) == _fold(bare)) {
          return AnswerGrade(Verdict.wrong, note: 'wrongArticle', expected: expected);
        }
      }
    }
    if (_fold(inp) == _fold(exp) || _foldLoose(inp) == _foldLoose(exp)) return AnswerGrade(Verdict.almost, note: 'accents', expected: expected);
    if (exp.length >= 5 && levenshtein(_fold(inp), _fold(exp)) <= (exp.length >= 10 ? 2 : 1)) {
      return AnswerGrade(Verdict.almost, note: 'typo', expected: expected);
    }
  }
  return AnswerGrade(Verdict.wrong, expected: expected);
}

/// Word-order / sentence answers: punctuation and case don't matter.
AnswerGrade gradeSentence(String input, String expected, String lang) {
  final a = normalizeAnswer(input, lang), b = normalizeAnswer(expected, lang);
  if (a == b) return AnswerGrade(Verdict.correct, expected: expected);
  if (_fold(a) == _fold(b)) return AnswerGrade(Verdict.almost, note: 'accents', expected: expected);
  return AnswerGrade(Verdict.wrong, expected: expected);
}

/// 0..1 similarity for speech recognition results.
double similarity(String a, String b, String lang) {
  final x = _fold(normalizeAnswer(a, lang)), y = _fold(normalizeAnswer(b, lang));
  if (x.isEmpty && y.isEmpty) return 1;
  final d = levenshtein(x, y);
  return 1 - d / max(x.length, y.length);
}

int starsFor(int correct, int total) {
  if (total == 0) return 3;
  final p = correct / total;
  return p >= 0.9 ? 3 : (p >= 0.7 ? 2 : 1);
}
