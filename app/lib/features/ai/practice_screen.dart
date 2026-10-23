import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../data/models.dart';
import '../../services/api.dart';
import '../../services/lessons.dart';
import '../../state/providers.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../lesson/lesson_screen.dart';

/// "Smart practice": the learner model picks weak and due words (Thompson
/// sampling), the AI writes personalised gap-fills around them and the
/// learner's recurring mistakes. Works offline with local exercises only.
class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});
  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  List<Exercise>? exercises;
  bool aiUsed = false;
  String? note;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    final p = ref.read(profileProvider);
    final learner = ref.read(learnerProvider);
    final deck = ref.read(deckProvider);
    final now = ref.read(clockProvider)();
    final weak = learner.pickWeak(6);
    final due = [for (final c in deck.due(now, p.targetLang).take(8)) deck.words[c.wordId]].whereType<Word>();
    final words = {for (final w in [...weak, ...due]) w.id: w}.values.take(8).toList();
    final local = ExerciseBuilder(target: p.targetLang, native: p.nativeLang, seed: now.millisecondsSinceEpoch).practice(words);

    var ai = <Exercise>[];
    try {
      final items = await ref.read(apiProvider).practice(
            profile: p,
            words: [for (final w in words) w.inLang(p.targetLang)],
            mistakes: [for (final m in ref.read(memoryProvider).topMistakes(p.targetLang, now, 4)) '${m.tag}: ${m.explanation}'],
            interests: ref.read(memoryProvider).interests,
          );
      ai = [
        for (final it in items)
          if (it.sentence.contains('___') && it.options.contains(it.answer))
            Cloze(
              before: it.sentence.substring(0, it.sentence.indexOf('___')),
              after: it.sentence.substring(it.sentence.indexOf('___') + 3),
              answer: it.answer,
              options: it.options,
              translation: it.translation,
            )
      ];
      aiUsed = ai.isNotEmpty;
    } on ApiException catch (e) {
      note = e.noProvider || e.code == 'not_configured'
          ? ref.t('Offline practice (connect the AI server for personalised sentences).', 'Çevrimdışı alıştırma (kişisel cümleler için yapay zekâ sunucusunu bağla).',
              'Offline-Übung (verbinde den KI-Server für persönliche Sätze).')
          : null;
    }
    if (!mounted) return;
    final all = [...local, ...ai]..shuffle();
    setState(() => exercises = all);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final ex = exercises;
    if (ex == null) {
      return Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Mascot(personaId: p.persona, mood: 'thinking', size: 140),
            Text(ref.t('Preparing your personal practice…', 'Kişisel alıştırman hazırlanıyor…', 'Dein persönliches Training wird vorbereitet…')),
          ]),
        ),
      );
    }
    if (ex.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            MascotSays(text: ref.t('Do a few lessons first — then I know what to practise with you!', 'Önce birkaç ders yap — sonra seninle ne çalışacağımızı bilirim!',
                'Mach zuerst ein paar Lektionen – dann weiß ich, was wir üben!'), mood: 'thinking'),
            const SizedBox(height: 20),
            ChunkyButton(label: ref.t('Back', 'Geri', 'Zurück'), onPressed: () => context.pop()),
          ]),
        ),
      );
    }
    return Column(children: [
      if (note != null || aiUsed)
        Material(
          color: (aiUsed ? const Color(0xFF7B4FB8) : Colors.grey).withValues(alpha: 0.14),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(aiUsed ? '✨ ${ref.t('Includes AI sentences made for you', 'Sana özel AI cümleleri içerir', 'Enthält KI-Sätze nur für dich')}' : note!,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ),
      Expanded(child: LessonScreen(exercises: ex)),
    ]);
  }
}
