import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/curriculum.dart';
import '../../data/models.dart';
import '../../services/api.dart';
import '../../services/lessons.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../../widgets/picture_card.dart';
import 'exercise_views.dart';

LessonSpec? findLesson(String id) {
  final u = unitsById[id.split('_').first];
  if (u == null) return null;
  for (final l in lessonsFor(u)) {
    if (l.id == id) return l;
  }
  return null;
}

const _praise = {
  'de': ['Super!', 'Richtig!', 'Toll!', 'Genau!', 'Prima!', 'Klasse!'],
  'en': ['Great!', 'Correct!', 'Nice!', 'Exactly!', 'Well done!', 'Brilliant!'],
  'tr': ['Harika!', 'Doğru!', 'Süper!', 'Aynen!', 'Aferin!', 'Mükemmel!'],
};

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, this.lessonId, this.exercises, this.title});

  /// A course lesson…
  final String? lessonId;

  /// …or a free practice session.
  final List<Exercise>? exercises;
  final String? title;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late final LessonSpec? spec = widget.lessonId == null ? null : findLesson(widget.lessonId!);
  late List<Exercise> queue;
  int index = 0;
  int graded = 0;
  int correct = 0;
  int combo = 0;
  int bestCombo = 0;
  bool replaying = false;
  final mistakes = <Exercise>[];
  final outcomes = <String, ({int ok, int bad})>{};
  Answer? answer;
  int shake = 0;
  bool finished = false;
  int xpEarned = 0;
  int stars = 0;
  bool judging = false;
  String? judgeNote;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider);
    queue = widget.exercises ??
        (spec == null ? <Exercise>[] : ExerciseBuilder(target: p.targetLang, native: p.nativeLang, seed: DateTime.now().millisecondsSinceEpoch).build(spec!));
  }

  bool get _answered => answer != null;

  void _onAnswer(Answer a) {
    if (_answered) return;
    final passed = a.grade.passed;
    setState(() {
      answer = a;
      judgeNote = null;
      if (!replaying) {
        graded++;
        if (passed) correct++;
      }
      combo = passed ? combo + 1 : 0;
      bestCombo = max(bestCombo, combo);
      if (!passed) {
        shake++;
        final e = queue[index];
        if (!replaying && e is! MatchPairs && e is! Speak) mistakes.add(e);
      }
    });
    for (final id in a.ok) {
      final o = outcomes[id] ?? (ok: 0, bad: 0);
      outcomes[id] = (ok: o.ok + 1, bad: o.bad);
    }
    for (final id in a.bad) {
      final o = outcomes[id] ?? (ok: 0, bad: 0);
      outcomes[id] = (ok: o.ok, bad: o.bad + 1);
    }
  }

  void _next() {
    setState(() {
      answer = null;
      judgeNote = null;
      index++;
      if (index >= queue.length && mistakes.isNotEmpty && !replaying) {
        // one more round with the exercises that went wrong
        replaying = true;
        queue = [...queue, ...mistakes..shuffle(_rng)];
        mistakes.clear();
      }
      if (index >= queue.length) _finish();
    });
  }

  void _finish() {
    finished = true;
    final p = ref.read(profileProvider);
    stars = starsFor(correct, graded);
    if (spec != null) ref.read(progressProvider.notifier).complete(spec!.id, correct: correct, total: graded, lang: p.targetLang);
    if (outcomes.isNotEmpty) ref.read(deckProvider.notifier).learnFromLesson(outcomes);
    xpEarned = 10 + correct + (stars == 3 ? 5 : 0) + (bestCombo >= 5 ? 3 : 0);
    ref.read(profileProvider.notifier).addXp(xpEarned);
  }

  Future<void> _judge() async {
    final a = answer!;
    setState(() => judging = true);
    try {
      final r = await ref.read(apiProvider).judge(profile: ref.read(profileProvider), prompt: a.prompt, expected: a.grade.expected, answer: a.given);
      if (!mounted) return;
      setState(() {
        judgeNote = r.explanation;
        if (r.accepted) {
          answer = Answer(AnswerGrade(Verdict.correct, note: 'ai', expected: a.grade.expected), ok: a.bad, prompt: a.prompt, given: a.given);
          if (!replaying) correct++;
          if (mistakes.isNotEmpty) mistakes.removeLast();
          for (final id in a.bad) {
            final o = outcomes[id]!;
            outcomes[id] = (ok: o.ok + 1, bad: max(0, o.bad - 1));
          }
          combo = 1;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => judgeNote = e.noProvider || e.code == 'not_configured' ? ref.t('AI judge needs the server.', 'AI hakem için sunucu gerekli.', 'Der KI-Schiedsrichter braucht den Server.') : e.message);
    } finally {
      if (mounted) setState(() => judging = false);
    }
  }

  Future<bool> _confirmQuit() async {
    if (finished || index == 0) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.t('Quit the lesson?', 'Dersten çıkılsın mı?', 'Lektion beenden?')),
        content: Text(ref.t('Your progress in this lesson will be lost.', 'Bu dersteki ilerlemen kaybolacak.', 'Dein Fortschritt in dieser Lektion geht verloren.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.t('Keep learning', 'Devam et', 'Weiterlernen'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ref.t('Quit', 'Çık', 'Beenden'))),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    if (queue.isEmpty) {
      return Scaffold(appBar: AppBar(), body: Center(child: Text(ref.t('Nothing to practise yet.', 'Henüz çalışılacak bir şey yok.', 'Noch nichts zu üben.'))));
    }
    return PopScope(
      canPop: finished || index == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmQuit() && context.mounted) context.pop();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: finished ? _summary(p) : _lesson(p),
            ),
          ),
        ),
      ),
    );
  }

  Widget _lesson(Profile p) {
    final e = queue[min(index, queue.length - 1)];
    final progress = index / queue.length;
    final mood = answer == null ? 'idle' : (answer!.grade.passed ? (combo >= 3 ? 'cheer' : 'happy') : 'sad');
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
        child: Row(children: [
          IconButton(
            tooltip: ref.t('Close', 'Kapat', 'Schließen'),
            icon: const Icon(Icons.close),
            onPressed: () async {
              if (await _confirmQuit() && mounted) context.pop();
            },
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 14, borderRadius: BorderRadius.circular(10), color: replaying ? Brand.gold : Brand.green),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: combo >= 2
                ? Text('🔥$combo', key: ValueKey(combo), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Brand.red))
                : Mascot(key: const ValueKey('m'), personaId: p.persona, mood: mood, size: 40),
          ),
        ]),
      ),
      if (replaying)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('🔁 ${ref.t("Let's fix your mistakes", 'Hadi hatalarını düzeltelim', 'Jetzt korrigieren wir die Fehler')}', style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.gold)),
        ),
      Expanded(
        child: Shake(
          trigger: shake,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(a), child: c)),
            child: SingleChildScrollView(
              key: ValueKey('ex$index'),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: exerciseView(
                e,
                ExerciseCtx(target: p.targetLang, native: p.nativeLang, persona: p.persona, onAnswer: _onAnswer, onContinue: _next, answered: _answered),
              ),
            ),
          ),
        ),
      ),
      AnimatedSize(duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic, child: answer == null ? const SizedBox(width: double.infinity) : _feedback(p)),
      if (answer == null && e is IntroCard)
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 16), child: ChunkyButton(label: ref.t('Continue', 'Devam', 'Weiter'), onPressed: _next)),
    ]);
  }

  String _noteText(String note) => switch (note) {
        'article' => ref.t("Don't forget the article!", 'Artikeli unutma!', 'Vergiss den Artikel nicht!'),
        'wrongArticle' => ref.t('Wrong article.', 'Yanlış artikel.', 'Falscher Artikel.'),
        'accents' => ref.t('Watch the special letters.', 'Özel harflere dikkat.', 'Achte auf die Sonderzeichen.'),
        'typo' => ref.t('Small typo.', 'Küçük bir yazım hatası.', 'Kleiner Tippfehler.'),
        'pairs' => ref.t('A few mix-ups.', 'Birkaç karışıklık oldu.', 'Ein paar Verwechslungen.'),
        'pronunciation' => ref.t('Almost — keep practising your pronunciation.', 'Neredeyse — telaffuz çalışmaya devam.', 'Fast — übe weiter die Aussprache.'),
        'ai' => ref.t('The AI accepted your answer.', 'Yapay zekâ cevabını kabul etti.', 'Die KI hat deine Antwort akzeptiert.'),
        _ => '',
      };

  Widget _feedback(Profile p) {
    final a = answer!;
    final v = a.grade.verdict;
    final color = switch (v) { Verdict.correct => Brand.green, Verdict.almost => Brand.gold, Verdict.wrong => Brand.red };
    final title = switch (v) {
      Verdict.correct => (_praise[p.targetLang] ?? _praise['de']!)[(index + correct) % 6],
      Verdict.almost => ref.t('Almost!', 'Neredeyse!', 'Fast!'),
      Verdict.wrong => ref.t('Not quite', 'Tam değil', 'Nicht ganz'),
    };
    final canJudge = v == Verdict.wrong && a.given.isNotEmpty && a.grade.expected.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), border: Border(top: BorderSide(color: color, width: 2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          PopIn(child: Icon(v == Verdict.wrong ? Icons.cancel : Icons.check_circle, color: color, size: 30)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color))),
        ]),
        if (a.grade.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(_noteText(a.grade.note))),
        if (v != Verdict.correct && a.grade.expected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${ref.t('Correct answer', 'Doğru cevap', 'Richtige Antwort')}: '),
              TextSpan(text: a.grade.expected, style: const TextStyle(fontWeight: FontWeight.w900)),
            ])),
          ),
        if (judgeNote != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('🤖 $judgeNote', style: const TextStyle(fontStyle: FontStyle.italic))),
        const SizedBox(height: 12),
        Row(children: [
          if (canJudge && judgeNote == null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton(
                onPressed: judging ? null : _judge,
                child: judging ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text('🤖 ${ref.t("I think I'm right", 'Bence doğru', 'Ich glaube, das stimmt')}'),
              ),
            ),
          Expanded(child: ChunkyButton(label: ref.t('Continue', 'Devam', 'Weiter'), color: color, onPressed: _next)),
        ]),
      ]),
    );
  }

  Widget _summary(Profile p) {
    final pct = graded == 0 ? 100 : (correct * 100 / graded).round();
    final words = [for (final id in outcomes.keys) ref.read(deckProvider).words[id]].whereType<Word>().toList();
    return Confetti(
      play: stars >= 2,
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const SizedBox(height: 12),
        Center(child: PopIn(child: Mascot(personaId: p.persona, mood: stars == 3 ? 'love' : 'cheer', size: 170))),
        const SizedBox(height: 8),
        Text(
          stars == 3 ? ref.t('Perfect lesson!', 'Kusursuz ders!', 'Perfekte Lektion!') : ref.t('Lesson complete!', 'Ders tamamlandı!', 'Lektion geschafft!'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 3; i++)
            PopIn(
              delay: Duration(milliseconds: 250 + i * 220),
              child: Icon(Icons.star_rounded, size: 58, color: i < stars ? const Color(0xFFF2C14E) : Colors.grey.withValues(alpha: 0.3)),
            ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _statCard('⭐', CountUp(value: xpEarned, prefix: '+', suffix: ' XP', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), 'XP')),
          const SizedBox(width: 10),
          Expanded(child: _statCard('🎯', CountUp(value: pct, suffix: '%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), ref.t('accuracy', 'doğruluk', 'Genauigkeit'))),
          const SizedBox(width: 10),
          Expanded(child: _statCard('🔥', Text('$bestCombo', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), ref.t('best combo', 'en iyi seri', 'beste Serie'))),
        ]),
        if (words.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(ref.t('Words practised', 'Çalışılan kelimeler', 'Geübte Wörter'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (i, w) in words.indexed)
              SlideFadeIn(
                index: i,
                child: Chip(
                  avatar: Text(w.emoji),
                  label: Text(w.inLang(p.targetLang)),
                  side: BorderSide(color: (outcomes[w.id]?.bad ?? 0) > 0 ? Brand.gold : Brand.green),
                ),
              ),
          ]),
        ],
        const SizedBox(height: 26),
        ChunkyButton(label: ref.t('Continue', 'Devam', 'Weiter'), onPressed: () => context.pop()),
      ]),
    );
  }

  Widget _statCard(String icon, Widget value, String label) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [Text(icon, style: const TextStyle(fontSize: 22)), value, Text(label, style: const TextStyle(fontSize: 12))]),
        ),
      );
}

/// Shown on the unit page: the unit's picture cards.
class UnitWordGrid extends ConsumerWidget {
  const UnitWordGrid({super.key, required this.unit, required this.onOpen});
  final Unit unit;
  final void Function(Word) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final deck = ref.watch(deckProvider);
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.82,
      children: [
        for (final (i, w) in unit.words.indexed)
          SlideFadeIn(
            index: i,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onOpen(w),
              child: Column(children: [
                Stack(children: [
                  PictureTile(word: w, size: 78, showGender: p.targetLang == 'de'),
                  if (deck.has(p.targetLang, w.id)) const Positioned(right: 2, top: 2, child: Icon(Icons.check_circle, size: 18, color: Brand.green)),
                ]),
                const SizedBox(height: 4),
                Text(w.inLang(p.targetLang), maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              ]),
            ),
          ),
      ],
    );
  }
}

/// Helper used by screens that only need a speech bubble with a mascot.
Widget mascotLine(String text, {String mood = 'happy'}) => MascotSays(text: text, mood: mood, size: 80);
