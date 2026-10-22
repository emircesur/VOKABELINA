import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/srs.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';

/// Flashcard session. Words with some history are sometimes shown in reverse
/// (native → German) to train recall instead of recognition.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final List<String> queue;
  int index = 0;
  bool revealed = false;
  int correct = 0;
  int xp = 0;
  String mood = 'idle';

  @override
  void initState() {
    super.initState();
    final deck = ref.read(deckProvider);
    final now = ref.read(clockProvider)();
    final due = deck.due(now).map((c) => c.wordId).toList();
    final all = deck.cards.values.toList()..sort((a, b) => a.due.compareTo(b.due));
    queue = (due.isNotEmpty ? due : all.map((c) => c.wordId).toList()).take(20).toList();
  }

  bool _reverse(CardState c) => c.reps >= 2 && c.wordId.hashCode.isEven;

  void _grade(Grade g) {
    final id = queue[index];
    ref.read(deckProvider.notifier).review(id, g);
    final gain = switch (g) { Grade.again => 1, Grade.hard => 2, Grade.good => 3, Grade.easy => 4 };
    xp += gain;
    if (g != Grade.again) correct++;
    setState(() {
      mood = g == Grade.again ? 'sad' : (g == Grade.easy ? 'cheer' : 'happy');
      revealed = false;
      index++;
    });
    if (index >= queue.length) ref.read(profileProvider.notifier).addXp(xp + 5);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final deck = ref.watch(deckProvider);
    final done = index >= queue.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(ref.t('Review', 'Tekrar')),
        actions: [if (!done) Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: Text('${index + 1} / ${queue.length}', style: const TextStyle(fontWeight: FontWeight.w800))))],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: queue.isEmpty ? _empty() : (done ? _summary() : _card(deck, profile)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        MascotSays(text: ref.t('Add some words first!', 'Önce birkaç kelime ekle!'), mood: 'thinking'),
        const SizedBox(height: 20),
        ChunkyButton(label: ref.t('Learn new words', 'Yeni kelime öğren'), onPressed: () => context.pushReplacement('/learn')),
      ]);

  Widget _summary() {
    final pct = queue.isEmpty ? 0 : (correct * 100 / queue.length).round();
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Mascot(personaId: ref.read(profileProvider).persona, mood: pct >= 60 ? 'cheer' : 'happy', size: 180),
      const SizedBox(height: 12),
      Text(ref.t('Session complete!', 'Seans tamamlandı!'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        StatChip(icon: '⭐', label: '+${xp + 5} XP'),
        const SizedBox(width: 8),
        StatChip(icon: '🎯', label: '$pct%', color: Brand.green),
      ]),
      const SizedBox(height: 28),
      ChunkyButton(label: ref.t('Done', 'Bitti'), onPressed: () => context.pop()),
    ]);
  }

  Widget _card(DeckState deck, Profile profile) {
    final c = deck.cards[queue[index]]!;
    final w = deck.words[c.wordId]!;
    final reverse = _reverse(c);
    final gloss = w.gloss(profile.nativeLang);
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      LinearProgressIndicator(value: index / queue.length, minHeight: 10, borderRadius: BorderRadius.circular(8)),
      const SizedBox(height: 12),
      Mascot(personaId: profile.persona, mood: mood, size: 90),
      Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => revealed = true);
            if (!reverse || revealed) speak(w.de);
          },
          child: Card(
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(reverse ? ref.t('How do you say…', 'Almancası ne…') : ref.t('What does this mean?', 'Bu ne demek?'), style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 14),
                  Text(reverse ? gloss : w.de, textAlign: TextAlign.center, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                  if (!reverse) IconButton(tooltip: ref.t('Listen', 'Dinle'), onPressed: () => speak(w.de), icon: const Icon(Icons.volume_up)),
                  const SizedBox(height: 14),
                  if (!revealed)
                    Text(ref.t('Tap to reveal', 'Cevabı görmek için dokun'), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800))
                  else ...[
                    Divider(color: cs.outlineVariant),
                    const SizedBox(height: 8),
                    Text(reverse ? w.de : gloss, textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: cs.primary)),
                    if (w.example.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text('„${w.example}“', textAlign: TextAlign.center, style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).hintColor))),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      if (!revealed)
        ChunkyButton(label: ref.t('Show answer', 'Cevabı göster'), onPressed: () {
          setState(() => revealed = true);
          speak(w.de);
        })
      else
        Row(children: [
          for (final (g, label, color) in [
            (Grade.again, ref.t('Again', 'Tekrar'), Brand.red),
            (Grade.hard, ref.t('Hard', 'Zor'), const Color(0xFFE09A2B)),
            (Grade.good, ref.t('Good', 'İyi'), Brand.teal),
            (Grade.easy, ref.t('Easy', 'Kolay'), Brand.green),
          ])
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(children: [
                  Text(intervalLabel(c, g, dayUnit: ref.t('d', 'g')), style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                  const SizedBox(height: 2),
                  ChunkyButton(label: label, color: color, compact: true, onPressed: () => _grade(g)),
                ]),
              ),
            ),
        ]),
    ]);
  }
}
