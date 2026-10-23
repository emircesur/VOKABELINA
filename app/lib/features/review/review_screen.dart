import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/srs.dart';
import '../../services/tts.dart';
import '../../services/quests.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../../widgets/picture_card.dart';

/// Spaced-repetition session with flip-able picture cards. Words with some
/// history are sometimes shown in reverse (meaning → target) to train recall.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final List<String> queue;
  late final String lang;
  int index = 0;
  bool revealed = false;
  int correct = 0;
  int xp = 0;
  String mood = 'idle';

  @override
  void initState() {
    super.initState();
    lang = ref.read(profileProvider).targetLang;
    final deck = ref.read(deckProvider);
    final now = ref.read(clockProvider)();
    final due = deck.due(now, lang).map((c) => c.wordId).toList();
    final all = deck.forLang(lang).values.toList()..sort((a, b) => a.due.compareTo(b.due));
    queue = (due.isNotEmpty ? due : all.map((c) => c.wordId).toList()).take(20).toList();
  }

  bool _reverse(CardState c) => c.reps >= 2 && c.wordId.hashCode.isEven;

  void _grade(Grade g) {
    ref.read(deckProvider.notifier).review(queue[index], g, lang: lang);
    ref.read(dailyProvider.notifier).bump(Metric.reviews);
    xp += switch (g) { Grade.again => 1, Grade.hard => 2, Grade.good => 3, Grade.easy => 4 };
    if (g != Grade.again) correct++;
    setState(() {
      mood = g == Grade.again ? 'sad' : (g == Grade.easy ? 'cheer' : 'happy');
      revealed = false;
      index++;
    });
    if (index >= queue.length) ref.read(profileProvider.notifier).addXp(xp + 5);
  }

  void _reveal(Word w) {
    setState(() => revealed = true);
    speak(w.inLang(lang), lang);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final deck = ref.watch(deckProvider);
    final done = index >= queue.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.t('Review', 'Tekrar', 'Wiederholung')),
        actions: [if (!done) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${index + 1} / ${queue.length}', style: const TextStyle(fontWeight: FontWeight.w800))))],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: queue.isEmpty ? _empty() : (done ? _summary(p) : _card(deck, p)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        MascotSays(text: ref.t('No cards yet — start a lesson first!', 'Henüz kart yok — önce bir ders yap!', 'Noch keine Karten – mach zuerst eine Lektion!'), mood: 'thinking'),
        const SizedBox(height: 20),
        ChunkyButton(label: ref.t('Back', 'Geri', 'Zurück'), onPressed: () => context.pop()),
      ]);

  Widget _summary(Profile p) {
    final pct = (correct * 100 / queue.length).round();
    return Confetti(
      play: pct >= 70,
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        PopIn(child: Mascot(personaId: p.persona, mood: pct >= 70 ? 'cheer' : 'happy', size: 170)),
        const SizedBox(height: 12),
        Text(ref.t('Review complete!', 'Tekrar tamamlandı!', 'Wiederholung geschafft!'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          StatChip(icon: '⭐', label: '+${xp + 5} XP'),
          const SizedBox(width: 8),
          StatChip(icon: '🎯', label: '$pct%', color: Brand.green),
        ]),
        const SizedBox(height: 28),
        ChunkyButton(label: ref.t('Done', 'Bitti', 'Fertig'), onPressed: () => context.pop()),
      ]),
    );
  }

  Widget _card(DeckState deck, Profile p) {
    final c = deck.cards[cardKey(lang, queue[index])]!;
    final w = deck.words[c.wordId]!;
    final reverse = _reverse(c);
    final gloss = w.gloss(p.nativeLang);
    final cs = Theme.of(context).colorScheme;

    Widget side(bool back) => Card(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                PictureTile(word: w, size: 110, showGender: back && lang == 'de'),
                const SizedBox(height: 16),
                if (!back) ...[
                  Text(reverse ? ref.t('How do you say…', 'Nasıl denir…', 'Wie sagt man…') : ref.t('What does it mean?', 'Ne demek?', 'Was bedeutet das?'),
                      style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  reverse
                      ? Text(gloss, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900))
                      : TargetWordText(word: w, lang: lang, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  Text(ref.t('Tap to reveal', 'Cevabı görmek için dokun', 'Zum Aufdecken tippen'), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800)),
                ] else ...[
                  TargetWordText(word: w, lang: lang, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text(gloss, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.primary)),
                  if (lang == 'de' && w.example.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 12), child: Text('„${w.example}“', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).hintColor))),
                  IconButton(onPressed: () => speak(w.inLang(lang), lang), icon: const Icon(Icons.volume_up)),
                ],
              ]),
            ),
          ),
        );

    return Column(children: [
      LinearProgressIndicator(value: index / queue.length, minHeight: 10, borderRadius: BorderRadius.circular(8)),
      const SizedBox(height: 8),
      Mascot(personaId: p.persona, mood: mood, size: 80),
      Expanded(
        child: GestureDetector(
          onTap: () => revealed ? null : _reveal(w),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey(index), child: FlipCard(flipped: revealed, front: side(false), back: side(true))),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (!revealed)
        ChunkyButton(label: ref.t('Show answer', 'Cevabı göster', 'Antwort zeigen'), onPressed: () => _reveal(w))
      else
        SlideFadeIn(
          child: Row(children: [
            for (final (g, label, color) in [
              (Grade.again, ref.t('Again', 'Tekrar', 'Nochmal'), Brand.red),
              (Grade.hard, ref.t('Hard', 'Zor', 'Schwer'), const Color(0xFFE09A2B)),
              (Grade.good, ref.t('Good', 'İyi', 'Gut'), Brand.teal),
              (Grade.easy, ref.t('Easy', 'Kolay', 'Leicht'), Brand.green),
            ])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(children: [
                    Text(intervalLabel(c, g, dayUnit: ref.t('d', 'g', 'T')), style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 2),
                    ChunkyButton(label: label, color: color, compact: true, onPressed: () => _grade(g)),
                  ]),
                ),
              ),
          ]),
        ),
    ]);
  }
}
