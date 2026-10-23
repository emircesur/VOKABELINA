import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/curriculum.dart';
import '../../data/models.dart';
import '../../data/personas.dart';
import '../../services/lessons.dart';
import '../../services/speech.dart';
import '../../services/tts.dart';
import '../../widgets/anim.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../../widgets/picture_card.dart';
import 'grammar_sheet.dart';

/// What the lesson needs to know about an answer.
class Answer {
  const Answer(this.grade, {this.ok = const {}, this.bad = const {}, this.prompt = '', this.given = ''});
  final AnswerGrade grade;

  /// Word ids answered correctly / wrongly (feeds the SRS and the learner model).
  final Set<String> ok;
  final Set<String> bad;

  /// For the AI judge: what was asked and what the learner typed.
  final String prompt;
  final String given;
}

class ExerciseCtx {
  const ExerciseCtx({required this.target, required this.native, required this.persona, required this.onAnswer, required this.onContinue, required this.answered});
  final String target;
  final String native;
  final String persona;
  final void Function(Answer) onAnswer;
  final VoidCallback onContinue;

  /// True once the current exercise has been answered (inputs lock).
  final bool answered;
}

Widget exerciseView(Exercise e, ExerciseCtx c) => switch (e) {
      IntroCard() => IntroCardView(e, c),
      PictureChoice() => PictureChoiceView(e, c),
      MeaningChoice() => MeaningChoiceView(e, c),
      ListenChoice() => ListenChoiceView(e, c),
      TypeAnswer() => TypeAnswerView(e, c),
      ArticleChoice() => ArticleChoiceView(e, c),
      MatchPairs() => MatchPairsView(e, c),
      DialogueRead() => DialogueReadView(e, c),
      WordOrder() => WordOrderView(e, c),
      PhraseChoice() => PhraseChoiceView(e, c),
      Cloze() => ClozeView(e, c),
      GrammarCard() => GrammarCardView(e, c),
      Speak() => SpeakView(e, c),
    };

Widget _title(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
    );

class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({required this.text, required this.lang, this.big = false});
  final String text;
  final String lang;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Material(
        color: cs.secondary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => speak(text, lang),
          child: Padding(padding: EdgeInsets.all(big ? 22 : 10), child: Icon(Icons.volume_up_rounded, color: Colors.white, size: big ? 44 : 24)),
        ),
      ),
      const SizedBox(width: 8),
      IconButton.filledTonal(tooltip: 'slow', onPressed: () => speak(text, lang, 0.22), icon: const Icon(Icons.slow_motion_video)),
    ]);
  }
}

/// Plays [text] once when the exercise appears.
mixin _AutoSpeak<T extends StatefulWidget> on State<T> {
  void autoSpeak(String text, String lang) => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) speak(text, lang);
      });
}

/// A tappable answer option that colours itself after the answer.
class _Option extends StatelessWidget {
  const _Option({required this.child, required this.onTap, this.state = 0, this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14), this.expand = false});
  final Widget child;

  /// Full-width row option (meaning / sentence choices).
  final bool expand;
  final VoidCallback? onTap;

  /// 0 neutral, 1 correct, 2 wrong (chosen), 3 dimmed
  final int state;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = switch (state) { 1 => Brand.green, 2 => Brand.red, _ => cs.outlineVariant };
    final bg = switch (state) { 1 => Brand.green.withValues(alpha: 0.14), 2 => Brand.red.withValues(alpha: 0.12), _ => Colors.transparent };
    final option = AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: state == 3 ? 0.45 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: border, width: 2)),
        child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: option) : option;
  }
}

int _optState(bool answered, bool isCorrect, bool isChosen) {
  if (!answered) return 0;
  if (isCorrect) return 1;
  if (isChosen) return 2;
  return 3;
}

void _haptic(bool ok) => ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();

// ----------------------------------------------------------------- intro

class IntroCardView extends ConsumerStatefulWidget {
  const IntroCardView(this.e, this.c, {super.key});
  final IntroCard e;
  final ExerciseCtx c;
  @override
  ConsumerState<IntroCardView> createState() => _IntroCardViewState();
}

class _IntroCardViewState extends ConsumerState<IntroCardView> with _AutoSpeak {
  bool flipped = false;

  @override
  void initState() {
    super.initState();
    autoSpeak(widget.e.word.inLang(widget.c.target), widget.c.target);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.e.word, t = widget.c.target, n = widget.c.native;
    Widget face(bool back) => Card(
          child: SizedBox(
            width: double.infinity,
            height: 300,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              PopIn(child: PictureTile(word: w, size: 130, showGender: t == 'de')),
              const SizedBox(height: 16),
              if (!back) ...[
                TargetWordText(word: w, lang: t, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                if (t == 'de' && w.pluralForm != null) Text('${ref.t('plural', 'çoğul', 'Plural')}: ${w.pluralForm}', style: TextStyle(color: Theme.of(context).hintColor)),
                const SizedBox(height: 8),
                Text(ref.t('tap to flip', 'çevirmek için dokun', 'zum Umdrehen tippen'), style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
              ] else ...[
                Text(w.gloss(n), textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
                if (t == 'de' && w.example.isNotEmpty)
                  Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 0), child: Text('„${w.example}“', textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic))),
              ],
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('✨ ${ref.t('New word', 'Yeni kelime', 'Neues Wort')}'),
      GestureDetector(onTap: () => setState(() => flipped = !flipped), child: FlipCard(flipped: flipped, front: face(false), back: face(true))),
      const SizedBox(height: 14),
      Center(child: _SpeakerButton(text: w.inLang(t), lang: t)),
      if (!flipped) Padding(padding: const EdgeInsets.only(top: 10), child: Center(child: Text(w.gloss(n), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)))),
    ]);
  }
}

// ------------------------------------------------------- picture choice

class PictureChoiceView extends ConsumerStatefulWidget {
  const PictureChoiceView(this.e, this.c, {super.key});
  final PictureChoice e;
  final ExerciseCtx c;
  @override
  ConsumerState<PictureChoiceView> createState() => _PictureChoiceViewState();
}

class _PictureChoiceViewState extends ConsumerState<PictureChoiceView> with _AutoSpeak {
  String? chosen;

  @override
  void initState() {
    super.initState();
    autoSpeak(widget.e.word.inLang(widget.c.target), widget.c.target);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e, t = widget.c.target;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(ref.t('Which picture?', 'Hangi resim?', 'Welches Bild?')),
      Row(children: [
        _SpeakerButton(text: e.word.inLang(t), lang: t),
        const SizedBox(width: 12),
        Expanded(child: TargetWordText(word: e.word, lang: t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
      ]),
      const SizedBox(height: 18),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: [
          for (final (i, o) in e.options.indexed)
            SlideFadeIn(
              index: i,
              child: _Option(
                state: _optState(widget.c.answered, o.id == e.word.id, o.id == chosen),
                padding: const EdgeInsets.all(8),
                onTap: widget.c.answered
                    ? null
                    : () {
                        setState(() => chosen = o.id);
                        final ok = o.id == e.word.id;
                        _haptic(ok);
                        widget.c.onAnswer(Answer(AnswerGrade(ok ? Verdict.correct : Verdict.wrong, expected: e.word.inLang(t)), ok: ok ? {e.word.id} : {}, bad: ok ? {} : {e.word.id}));
                      },
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  PictureTile(word: o, size: 86),
                  if (widget.c.answered) Padding(padding: const EdgeInsets.only(top: 4), child: Text(o.inLang(t), style: const TextStyle(fontSize: 12), textAlign: TextAlign.center)),
                ]),
              ),
            ),
        ],
      ),
    ]);
  }
}

// ------------------------------------------------------- meaning choice

class MeaningChoiceView extends ConsumerStatefulWidget {
  const MeaningChoiceView(this.e, this.c, {super.key});
  final MeaningChoice e;
  final ExerciseCtx c;
  @override
  ConsumerState<MeaningChoiceView> createState() => _MeaningChoiceViewState();
}

class _MeaningChoiceViewState extends ConsumerState<MeaningChoiceView> with _AutoSpeak {
  String? chosen;

  @override
  void initState() {
    super.initState();
    if (!widget.e.reverse) autoSpeak(widget.e.word.inLang(widget.c.target), widget.c.target);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e, t = widget.c.target, n = widget.c.native;
    String label(Word w) => e.reverse ? w.inLang(t) : w.gloss(n);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(e.reverse ? ref.t('How do you say…', 'Nasıl denir…', 'Wie sagt man…') : ref.t('What does it mean?', 'Ne demek?', 'Was bedeutet das?')),
      Row(children: [
        PictureTile(word: e.word, size: 64),
        const SizedBox(width: 14),
        Expanded(
          child: e.reverse
              ? Text(e.word.gloss(n), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))
              : TargetWordText(word: e.word, lang: t, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ),
        if (!e.reverse) IconButton(onPressed: () => speak(e.word.inLang(t), t), icon: const Icon(Icons.volume_up)),
      ]),
      const SizedBox(height: 18),
      for (final (i, o) in e.options.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SlideFadeIn(
            index: i,
            child: _Option(
              expand: true,
              state: _optState(widget.c.answered, o.id == e.word.id, o.id == chosen),
              onTap: widget.c.answered
                  ? null
                  : () {
                      setState(() => chosen = o.id);
                      final ok = o.id == e.word.id;
                      _haptic(ok);
                      if (e.reverse && ok) speak(o.inLang(t), t);
                      widget.c.onAnswer(Answer(AnswerGrade(ok ? Verdict.correct : Verdict.wrong, expected: label(e.word)), ok: ok ? {e.word.id} : {}, bad: ok ? {} : {e.word.id}));
                    },
              child: Text(label(o), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
    ]);
  }
}

// -------------------------------------------------------- listen choice

class ListenChoiceView extends ConsumerStatefulWidget {
  const ListenChoiceView(this.e, this.c, {super.key});
  final ListenChoice e;
  final ExerciseCtx c;
  @override
  ConsumerState<ListenChoiceView> createState() => _ListenChoiceViewState();
}

class _ListenChoiceViewState extends ConsumerState<ListenChoiceView> with _AutoSpeak {
  String? chosen;

  @override
  void initState() {
    super.initState();
    autoSpeak(widget.e.word.inLang(widget.c.target), widget.c.target);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e, t = widget.c.target;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(ref.t('What do you hear?', 'Ne duyuyorsun?', 'Was hörst du?')),
      Center(child: Pulse(child: _SpeakerButton(text: e.word.inLang(t), lang: t, big: true))),
      const SizedBox(height: 22),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final o in e.options)
          _Option(
            state: _optState(widget.c.answered, o.id == e.word.id, o.id == chosen),
            onTap: widget.c.answered
                ? null
                : () {
                    setState(() => chosen = o.id);
                    final ok = o.id == e.word.id;
                    _haptic(ok);
                    widget.c.onAnswer(Answer(AnswerGrade(ok ? Verdict.correct : Verdict.wrong, expected: e.word.inLang(t)), ok: ok ? {e.word.id} : {}, bad: ok ? {} : {e.word.id}));
                  },
            child: Text(o.inLang(t), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
      ]),
    ]);
  }
}

// ----------------------------------------------------------- typing

const _specialKeys = {
  'de': ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü'],
  'tr': ['ç', 'ğ', 'ı', 'İ', 'ö', 'ş', 'ü'],
  'en': <String>[],
};

class TypeAnswerView extends ConsumerStatefulWidget {
  const TypeAnswerView(this.e, this.c, {super.key});
  final TypeAnswer e;
  final ExerciseCtx c;
  @override
  ConsumerState<TypeAnswerView> createState() => _TypeAnswerViewState();
}

class _TypeAnswerViewState extends ConsumerState<TypeAnswerView> {
  final _ctl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _check() {
    if (widget.c.answered || _ctl.text.trim().isEmpty) return;
    final w = widget.e.word, t = widget.c.target;
    final g = gradeTyped(_ctl.text, w.inLang(t), t);
    _haptic(g.passed);
    if (g.passed) speak(w.inLang(t), t);
    widget.c.onAnswer(Answer(g, ok: g.passed ? {w.id} : {}, bad: g.passed ? {} : {w.id}, prompt: w.gloss(widget.c.native), given: _ctl.text.trim()));
  }

  void _insert(String ch) {
    final sel = _ctl.selection;
    final text = _ctl.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _ctl.value = TextEditingValue(text: text.replaceRange(start, end, ch), selection: TextSelection.collapsed(offset: start + ch.length));
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.e.word, t = widget.c.target;
    final hint = t == 'de' && w.article != null ? ref.t('with article: der/die/das …', 'artikeliyle: der/die/das …', 'mit Artikel: der/die/das …') : ref.t('Type in ${langNames[t]!['en']}', '${langNames[t]!['tr']} yaz', 'Auf ${langNames[t]!['de']} schreiben');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(ref.t('Write it in ${langNames[t]!['en']}', '${langNames[t]!['tr']} yaz', 'Schreib es auf ${langNames[t]!['de']}')),
      Row(children: [
        PopIn(child: PictureTile(word: w, size: 76)),
        const SizedBox(width: 14),
        Expanded(child: Text(w.gloss(widget.c.native), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
      ]),
      const SizedBox(height: 18),
      TextField(
        controller: _ctl,
        focusNode: _focus,
        enabled: !widget.c.answered,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _check(),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        decoration: InputDecoration(hintText: hint),
      ),
      if ((_specialKeys[t] ?? const []).isNotEmpty && !widget.c.answered)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(spacing: 6, children: [
            for (final k in _specialKeys[t]!) ActionChip(label: Text(k, style: const TextStyle(fontSize: 16)), onPressed: () => _insert(k), visualDensity: VisualDensity.compact),
          ]),
        ),
      const SizedBox(height: 16),
      if (!widget.c.answered)
        ListenableBuilder(
          listenable: _ctl,
          builder: (_, _) => ChunkyButton(label: ref.t('Check', 'Kontrol et', 'Prüfen'), onPressed: _ctl.text.trim().isEmpty ? null : _check),
        ),
    ]);
  }
}

// ----------------------------------------------------------- articles

class ArticleChoiceView extends ConsumerStatefulWidget {
  const ArticleChoiceView(this.e, this.c, {super.key});
  final ArticleChoice e;
  final ExerciseCtx c;
  @override
  ConsumerState<ArticleChoiceView> createState() => _ArticleChoiceViewState();
}

class _ArticleChoiceViewState extends ConsumerState<ArticleChoiceView> {
  String? chosen;

  @override
  Widget build(BuildContext context) {
    final w = widget.e.word;
    final art = w.article!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(ref.t('der, die or das?', 'der, die mi das mı?', 'der, die oder das?')),
      Center(child: PopIn(child: PictureTile(word: w, size: 120))),
      const SizedBox(height: 12),
      Center(child: Text(w.lemma.isEmpty ? w.de : w.de.substring(art.length + 1), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
      Center(child: Text(w.gloss(widget.c.native), style: TextStyle(color: Theme.of(context).hintColor))),
      const SizedBox(height: 22),
      Row(children: [
        for (final a in ['der', 'die', 'das'])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: widget.c.answered && a != art && a != chosen ? 0.4 : 1,
                child: ChunkyButton(
                  label: a,
                  color: articleColor(a),
                  onPressed: widget.c.answered
                      ? null
                      : () {
                          setState(() => chosen = a);
                          final ok = a == art;
                          _haptic(ok);
                          speak(w.de, 'de');
                          widget.c.onAnswer(Answer(AnswerGrade(ok ? Verdict.correct : Verdict.wrong, expected: w.de), ok: ok ? {w.id} : {}, bad: ok ? {} : {w.id}));
                        },
                ),
              ),
            ),
          ),
      ]),
    ]);
  }
}

// --------------------------------------------------------------- match

class MatchPairsView extends ConsumerStatefulWidget {
  const MatchPairsView(this.e, this.c, {super.key});
  final MatchPairs e;
  final ExerciseCtx c;
  @override
  ConsumerState<MatchPairsView> createState() => _MatchPairsViewState();
}

class _MatchPairsViewState extends ConsumerState<MatchPairsView> {
  late final List<Word> left = widget.e.words.toList()..shuffle();
  late final List<Word> right = widget.e.words.toList()..shuffle();
  final matched = <String>{};
  final missed = <String>{};
  String? selL, selR;
  int shake = 0;
  String? wrongL, wrongR;

  void _try() {
    if (selL == null || selR == null) return;
    final t = widget.c.target;
    if (selL == selR) {
      HapticFeedback.selectionClick();
      speak(left.firstWhere((w) => w.id == selL).inLang(t), t);
      setState(() {
        matched.add(selL!);
        selL = selR = null;
      });
      if (matched.length == widget.e.words.length) {
        final errors = missed.length;
        final v = errors == 0 ? Verdict.correct : (errors <= 1 ? Verdict.almost : Verdict.wrong);
        widget.c.onAnswer(Answer(AnswerGrade(v, note: errors == 0 ? '' : 'pairs'), ok: {for (final w in widget.e.words) if (!missed.contains(w.id)) w.id}, bad: missed));
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        missed
          ..add(selL!)
          ..add(selR!);
        wrongL = selL;
        wrongR = selR;
        shake++;
        selL = selR = null;
      });
      Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => wrongL = wrongR = null);
      });
    }
  }

  Widget _tile(Word w, bool isLeft) {
    final done = matched.contains(w.id);
    final sel = isLeft ? selL == w.id : selR == w.id;
    final wrong = isLeft ? wrongL == w.id : wrongR == w.id;
    final cs = Theme.of(context).colorScheme;
    final t = widget.c.target;
    final tile = AnimatedScale(
      duration: const Duration(milliseconds: 250),
      scale: done ? 0.9 : (sel ? 1.04 : 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: done ? 0.25 : 1,
        child: Material(
          color: wrong ? Brand.red.withValues(alpha: 0.15) : (sel ? cs.primary.withValues(alpha: 0.14) : Colors.transparent),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), side: BorderSide(color: wrong ? Brand.red : (sel ? cs.primary : cs.outlineVariant), width: 2)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: done || widget.c.answered
                ? null
                : () {
                    setState(() => isLeft ? selL = w.id : selR = w.id);
                    if (isLeft) speak(w.inLang(t), t);
                    _try();
                  },
            child: Container(
              height: 58,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(isLeft ? w.inLang(t) : w.gloss(widget.c.native),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: wrong ? Shake(trigger: shake, child: tile) : tile);
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(ref.t('Match the pairs', 'Eşleştir', 'Finde die Paare')),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(children: [for (final w in left) _tile(w, true)])),
        const SizedBox(width: 12),
        Expanded(child: Column(children: [for (final w in right) _tile(w, false)])),
      ]),
    ]);
  }
}

// ------------------------------------------------------------ dialogue

class DialogueReadView extends ConsumerStatefulWidget {
  const DialogueReadView(this.e, this.c, {super.key});
  final DialogueRead e;
  final ExerciseCtx c;
  @override
  ConsumerState<DialogueReadView> createState() => _DialogueReadViewState();
}

class _DialogueReadViewState extends ConsumerState<DialogueReadView> {
  bool translations = false;
  int shown = 1;

  @override
  Widget build(BuildContext context) {
    final t = widget.c.target, n = widget.c.native;
    final ps = widget.e.phrases;
    final cs = Theme.of(context).colorScheme;
    final persona = personaOf(widget.c.persona);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _title('💬 ${ref.t('Dialogue', 'Diyalog', 'Dialog')}')),
        FilterChip(label: Text(ref.t('Translation', 'Çeviri', 'Übersetzung')), selected: translations, onSelected: (v) => setState(() => translations = v)),
      ]),
      for (final (i, p) in ps.take(shown).indexed)
        SlideFadeIn(
          key: ValueKey(p.id),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: p.speaker == 'A' ? MainAxisAlignment.start : MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (p.speaker == 'A') Mascot(personaId: persona.id, mood: i == shown - 1 ? 'talking' : 'idle', size: 40),
                Flexible(
                  child: GestureDetector(
                    onTap: () => speak(p.inLang(t), t),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: p.speaker == 'A' ? cs.surfaceContainerHighest.withValues(alpha: 0.7) : cs.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.inLang(t), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
                        if (translations) Text(p.inLang(n), style: TextStyle(color: cs.secondary, fontStyle: FontStyle.italic)),
                      ]),
                    ),
                  ),
                ),
                if (p.speaker == 'B') const CircleAvatar(radius: 18, child: Text('🙂')),
              ],
            ),
          ),
        ),
      const SizedBox(height: 8),
      if (shown < ps.length)
        ChunkyButton(
          compact: true,
          color: cs.secondary,
          icon: Icons.play_arrow,
          label: ref.t('Next line', 'Sonraki satır', 'Nächste Zeile'),
          onPressed: () {
            speak(ps[shown].inLang(t), t);
            setState(() => shown++);
          },
        )
      else
        ChunkyButton(label: ref.t('Continue', 'Devam', 'Weiter'), onPressed: widget.c.onContinue),
    ]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => speak(widget.e.phrases.first.inLang(widget.c.target), widget.c.target));
  }
}

// ---------------------------------------------------------- word order

class WordOrderView extends ConsumerStatefulWidget {
  const WordOrderView(this.e, this.c, {super.key});
  final WordOrder e;
  final ExerciseCtx c;
  @override
  ConsumerState<WordOrderView> createState() => _WordOrderViewState();
}

class _WordOrderViewState extends ConsumerState<WordOrderView> {
  final picked = <int>[];

  @override
  Widget build(BuildContext context) {
    final e = widget.e, t = widget.c.target;
    final cs = Theme.of(context).colorScheme;
    Widget tile(int i, {required bool inAnswer}) => Material(
          color: cs.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant, width: 2)),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.c.answered
                ? null
                : () => setState(() {
                      if (inAnswer) {
                        picked.remove(i);
                      } else {
                        picked.add(i);
                        speak(e.tiles[i], t);
                      }
                    }),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Text(e.tiles[i], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(ref.t('Build the sentence', 'Cümleyi kur', 'Bilde den Satz')),
      if (e.prompt.isNotEmpty)
        MascotSays(text: e.prompt, mood: 'talking', size: 64)
      else
        _SpeakerButton(text: e.answer, lang: t),
      const SizedBox(height: 14),
      Container(
        constraints: const BoxConstraints(minHeight: 64),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cs.outlineVariant, width: 2))),
        child: Wrap(spacing: 8, runSpacing: 8, children: [for (final i in picked) PopIn(key: ValueKey('a$i'), child: tile(i, inAnswer: true))]),
      ),
      const SizedBox(height: 18),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
        for (var i = 0; i < e.tiles.length; i++)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: picked.contains(i) ? 0 : 1,
            child: IgnorePointer(ignoring: picked.contains(i), child: tile(i, inAnswer: false)),
          ),
      ]),
      const SizedBox(height: 18),
      if (!widget.c.answered)
        ChunkyButton(
          label: ref.t('Check', 'Kontrol et', 'Prüfen'),
          onPressed: picked.isEmpty
              ? null
              : () {
                  final given = [for (final i in picked) e.tiles[i]].join(' ');
                  final g = gradeSentence(given, e.answer, t);
                  _haptic(g.passed);
                  if (g.passed) speak(e.answer, t);
                  widget.c.onAnswer(Answer(g, prompt: e.prompt, given: given));
                },
        ),
    ]);
  }
}

// -------------------------------------------------------- phrase choice

class PhraseChoiceView extends ConsumerStatefulWidget {
  const PhraseChoiceView(this.e, this.c, {super.key});
  final PhraseChoice e;
  final ExerciseCtx c;
  @override
  ConsumerState<PhraseChoiceView> createState() => _PhraseChoiceViewState();
}

class _PhraseChoiceViewState extends ConsumerState<PhraseChoiceView> with _AutoSpeak {
  String? chosen;

  @override
  void initState() {
    super.initState();
    if (widget.e.listen) autoSpeak(widget.e.phrase.inLang(widget.c.target), widget.c.target);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e, t = widget.c.target, n = widget.c.native;
    String label(Phrase p) => e.listen ? p.inLang(n) : p.inLang(t);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(e.listen ? ref.t('What does it mean?', 'Ne demek?', 'Was bedeutet das?') : ref.t('Choose the right sentence', 'Doğru cümleyi seç', 'Wähle den richtigen Satz')),
      if (e.listen)
        Center(child: Pulse(child: _SpeakerButton(text: e.phrase.inLang(t), lang: t, big: true)))
      else
        MascotSays(text: e.phrase.inLang(n), mood: 'talking', size: 64),
      const SizedBox(height: 18),
      for (final (i, o) in e.options.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SlideFadeIn(
            index: i,
            child: _Option(
              expand: true,
              state: _optState(widget.c.answered, o.id == e.phrase.id, o.id == chosen),
              onTap: widget.c.answered
                  ? null
                  : () {
                      setState(() => chosen = o.id);
                      final ok = o.id == e.phrase.id;
                      _haptic(ok);
                      if (!e.listen) speak(o.inLang(t), t);
                      widget.c.onAnswer(Answer(AnswerGrade(ok ? Verdict.correct : Verdict.wrong, expected: label(e.phrase))));
                    },
              child: Text(label(o), style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
    ]);
  }
}

// ---------------------------------------------------------------- cloze

class ClozeView extends ConsumerStatefulWidget {
  const ClozeView(this.e, this.c, {super.key});
  final Cloze e;
  final ExerciseCtx c;
  @override
  ConsumerState<ClozeView> createState() => _ClozeViewState();
}

class _ClozeViewState extends ConsumerState<ClozeView> {
  String? chosen;

  @override
  Widget build(BuildContext context) {
    final e = widget.e, t = widget.c.target;
    final cs = Theme.of(context).colorScheme;
    final fill = chosen ?? '_____';
    final color = chosen == null ? cs.primary : (chosen == e.answer ? Brand.green : Brand.red);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title(ref.t('Fill the gap', 'Boşluğu doldur', 'Fülle die Lücke')),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: e.before),
                TextSpan(text: fill, style: TextStyle(color: color, fontWeight: FontWeight.w900, decoration: TextDecoration.underline)),
                TextSpan(text: e.after),
              ]),
              style: const TextStyle(fontSize: 21, height: 1.4, fontWeight: FontWeight.w600),
            ),
            if (e.translation.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(e.translation, style: TextStyle(color: cs.secondary, fontStyle: FontStyle.italic))),
          ]),
        ),
      ),
      const SizedBox(height: 18),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final o in e.options)
          _Option(
            state: _optState(widget.c.answered, o == e.answer, o == chosen),
            onTap: widget.c.answered
                ? null
                : () {
                    setState(() => chosen = o);
                    final ok = o == e.answer;
                    _haptic(ok);
                    speak('${e.before}${e.answer}${e.after}', t);
                    widget.c.onAnswer(Answer(AnswerGrade(ok ? Verdict.correct : Verdict.wrong, expected: '${e.before}${e.answer}${e.after}')));
                  },
            child: Text(o, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          ),
      ]),
    ]);
  }
}

// -------------------------------------------------------------- grammar

class GrammarCardView extends ConsumerWidget {
  const GrammarCardView(this.e, this.c, {super.key});
  final GrammarCard e;
  final ExerciseCtx c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = e.point;
    final lang = ref.uiLang;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('📐 ${g.titleIn(lang)}'),
      SpeechBubble(child: Text(g.bodyIn(lang), style: const TextStyle(fontSize: 16, height: 1.45))),
      const SizedBox(height: 12),
      for (final (i, ex) in g.examples.indexed)
        SlideFadeIn(
          index: i,
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.volume_up),
              title: Text(ex, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              onTap: () => speak(ex, c.target),
            ),
          ),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () => showGrammarSheet(context, topic: g.titleIn('en')),
        icon: const Icon(Icons.auto_awesome),
        label: Text(ref.t('Explain more (AI)', 'Daha fazla açıkla (AI)', 'Mehr erklären (KI)')),
      ),
      const SizedBox(height: 14),
      ChunkyButton(label: ref.t('Got it!', 'Anladım!', 'Verstanden!'), onPressed: c.onContinue),
    ]);
  }
}

// ---------------------------------------------------------------- speak

class SpeakView extends ConsumerStatefulWidget {
  const SpeakView(this.e, this.c, {super.key});
  final Speak e;
  final ExerciseCtx c;
  @override
  ConsumerState<SpeakView> createState() => _SpeakViewState();
}

class _SpeakViewState extends ConsumerState<SpeakView> {
  bool listening = false;
  bool? available;
  String heard = '';

  @override
  void initState() {
    super.initState();
    speechService.available.then((v) {
      if (mounted) setState(() => available = v);
    });
  }

  Future<void> _listen() async {
    final t = widget.c.target;
    setState(() {
      listening = true;
      heard = '';
    });
    await speechService.listen(t, (text, done) {
      if (!mounted) return;
      setState(() => heard = text);
      if (done) _finish();
    });
  }

  void _finish() {
    if (widget.c.answered) return;
    setState(() => listening = false);
    final s = similarity(heard, widget.e.text, widget.c.target);
    final v = s >= 0.8 ? Verdict.correct : (s >= 0.55 ? Verdict.almost : Verdict.wrong);
    _haptic(v != Verdict.wrong);
    widget.c.onAnswer(Answer(AnswerGrade(v, note: v == Verdict.almost ? 'pronunciation' : '', expected: widget.e.text), given: heard));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.e, t = widget.c.target;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _title('🎙️ ${ref.t('Say it out loud', 'Sesli söyle', 'Sprich laut')}'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(e.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              IconButton(onPressed: () => speak(e.text, t), icon: const Icon(Icons.volume_up)),
            ]),
            Text(e.translation, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ]),
        ),
      ),
      const SizedBox(height: 20),
      Center(
        child: available == false
            ? Text(ref.t('Speech recognition is not available on this device.', 'Bu cihazda konuşma tanıma yok.', 'Spracherkennung ist auf diesem Gerät nicht verfügbar.'), textAlign: TextAlign.center)
            : Pulse(
                enabled: listening,
                scale: 0.12,
                child: FloatingActionButton.large(
                  heroTag: null,
                  backgroundColor: listening ? Brand.red : Theme.of(context).colorScheme.primary,
                  onPressed: widget.c.answered || available != true
                      ? null
                      : () async {
                          if (listening) {
                            await speechService.stop();
                            _finish();
                          } else {
                            await _listen();
                          }
                        },
                  child: Icon(listening ? Icons.stop : Icons.mic, color: Colors.white, size: 40),
                ),
              ),
      ),
      if (heard.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14), child: Center(child: Text('“$heard”', style: const TextStyle(fontSize: 17, fontStyle: FontStyle.italic)))),
      const SizedBox(height: 14),
      if (!widget.c.answered) Center(child: TextButton(onPressed: widget.c.onContinue, child: Text(ref.t("Can't speak now", 'Şimdi konuşamam', 'Kann gerade nicht sprechen')))),
    ]);
  }
}
