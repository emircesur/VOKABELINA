import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';

/// "Wortschatz": the learner's deck with mastery per word and manual add.
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});

  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final deck = ref.watch(deckProvider);
    final lang = ref.watch(profileProvider.select((p) => p.nativeLang));
    final now = ref.watch(clockProvider)();
    final due = deck.due(now).length;
    final known = deck.cards.values.where((c) => c.isKnown).length;
    final q = query.trim().toLowerCase();
    final items = [
      for (final c in deck.cards.values)
        if (deck.words[c.wordId] != null && (q.isEmpty || deck.words[c.wordId]!.de.toLowerCase().contains(q) || deck.words[c.wordId]!.gloss(lang).toLowerCase().contains(q))) c
    ]..sort((a, b) => a.due.compareTo(b.due));

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Wortschatz', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            StatChip(icon: '📚', label: ref.t('${deck.cards.length} words', '${deck.cards.length} kelime')),
            StatChip(icon: '⏰', label: ref.t('$due due', '$due bekliyor'), color: Brand.red),
            StatChip(icon: '✅', label: ref.t('$known known', '$known biliniyor'), color: Brand.green),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: ref.t('Search words', 'Kelime ara'), isDense: true),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(tooltip: ref.t('Add a word', 'Kelime ekle'), onPressed: () => _addWord(context), icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 10),
          ChunkyButton(label: ref.t('Review', 'Tekrar et'), icon: Icons.style, compact: true, onPressed: deck.cards.isEmpty ? null : () => context.push('/review')),
        ]),
      ),
      Expanded(
        child: items.isEmpty
            ? Center(child: Text(ref.t('No words yet — learn some from the home tab.', 'Henüz kelime yok — ana sekmeden öğren.')))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final c = items[i];
                  final w = deck.words[c.wordId]!;
                  return Card(
                    child: ListTile(
                      onTap: () => speak(w.de),
                      title: Text(w.de, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(w.gloss(lang)),
                      trailing: SizedBox(
                        width: 56,
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          LinearProgressIndicator(value: c.mastery, minHeight: 6, borderRadius: BorderRadius.circular(6), color: c.isKnown ? Brand.green : Brand.gold),
                          const SizedBox(height: 4),
                          Text(c.reps == 0 ? ref.t('new', 'yeni') : '${(c.mastery * 100).round()}%', style: const TextStyle(fontSize: 11)),
                        ]),
                      ),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Future<void> _addWord(BuildContext context) async {
    final de = TextEditingController();
    final gloss = TextEditingController();
    final lang = ref.read(profileProvider).nativeLang;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.t('Add a word', 'Kelime ekle')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: de, autofocus: true, decoration: InputDecoration(labelText: ref.t('German (with article)', 'Almanca (artikel ile)'))),
          const SizedBox(height: 10),
          TextField(controller: gloss, decoration: InputDecoration(labelText: lang == 'tr' ? 'Türkçe' : 'English')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.t('Cancel', 'İptal'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ref.t('Add', 'Ekle'))),
        ],
      ),
    );
    if (ok == true && de.text.trim().isNotEmpty) {
      final d = de.text.trim();
      ref.read(deckProvider.notifier).add([
        Word(id: Word.idFor(d), de: d, en: lang == 'en' ? gloss.text.trim() : '', tr: lang == 'tr' ? gloss.text.trim() : '', custom: true, topic: 'mine'),
      ]);
    }
    de.dispose();
    gloss.dispose();
  }
}
