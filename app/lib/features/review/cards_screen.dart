import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/curriculum.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';
import '../../widgets/picture_card.dart';
import '../words/word_sheet.dart';

/// "Wortschatz": picture-card collection of the current target language.
class CardsScreen extends ConsumerStatefulWidget {
  const CardsScreen({super.key});
  @override
  ConsumerState<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends ConsumerState<CardsScreen> {
  String query = '';

  /// 'mine' (deck) | 'all' (catalogue) | a unit id
  String filter = 'mine';

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final deck = ref.watch(deckProvider);
    final now = ref.watch(clockProvider)();
    final mine = deck.forLang(p.targetLang);
    final due = deck.due(now, p.targetLang).length;
    final known = mine.values.where((c) => c.isKnown).length;
    final q = query.trim().toLowerCase();

    final source = switch (filter) {
      'mine' => [for (final id in mine.keys) deck.words[id]].whereType<Word>().toList(),
      'all' => deck.words.values.where((w) => !w.custom).toList(),
      _ => unitsById[filter]?.words ?? const <Word>[],
    };
    final items = source.where((w) => q.isEmpty || w.inLang(p.targetLang).toLowerCase().contains(q) || w.gloss(p.nativeLang).toLowerCase().contains(q)).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(ref.t('Vocabulary', 'Kelime hazinesi', 'Wortschatz'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const Spacer(),
            Text(langFlags[p.targetLang]!, style: const TextStyle(fontSize: 22)),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6, children: [
            StatChip(icon: '📚', label: '${mine.length}'),
            StatChip(icon: '⏰', label: ref.t('$due due', '$due bekliyor', '$due fällig'), color: Brand.red),
            StatChip(icon: '✅', label: ref.t('$known known', '$known biliniyor', '$known gelernt'), color: Brand.green),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ChunkyButton(label: ref.t('Review', 'Tekrar et', 'Wiederholen'), icon: Icons.style, compact: true, onPressed: mine.isEmpty ? null : () => context.push('/review'))),
            const SizedBox(width: 8),
            Expanded(child: ChunkyButton(label: ref.t('Practice', 'Alıştırma', 'Üben'), icon: Icons.psychology, compact: true, color: Brand.teal, onPressed: () => context.push('/practice'))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: ref.t('Search', 'Ara', 'Suchen'), isDense: true),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(tooltip: ref.t('Add a word', 'Kelime ekle', 'Wort hinzufügen'), onPressed: () => _addWord(context), icon: const Icon(Icons.add)),
          ]),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              _chip('mine', ref.t('My cards', 'Kartlarım', 'Meine Karten')),
              _chip('all', ref.t('All', 'Tümü', 'Alle')),
              for (final u in units) _chip(u.id, '${u.emoji} ${u.number}'),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: items.isEmpty
            ? Center(child: Text(ref.t('No cards here yet — start a lesson!', 'Burada henüz kart yok — bir derse başla!', 'Hier gibt es noch keine Karten – starte eine Lektion!')))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 130, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.72),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final w = items[i];
                  final c = mine[w.id];
                  return SlideFadeIn(
                    index: i,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => showWordSheet(context, w),
                      child: Column(children: [
                        PictureTile(word: w, size: 92, showGender: p.targetLang == 'de'),
                        const SizedBox(height: 4),
                        Text(w.inLang(p.targetLang), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(w.gloss(p.nativeLang), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
                        if (c != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: LinearProgressIndicator(value: c.mastery, minHeight: 4, borderRadius: BorderRadius.circular(4), color: c.isKnown ? Brand.green : Brand.gold),
                          ),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _chip(String id, String label) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(label: Text(label), selected: filter == id, onSelected: (_) => setState(() => filter = id), visualDensity: VisualDensity.compact),
      );

  Future<void> _addWord(BuildContext context) async {
    final target = TextEditingController();
    final gloss = TextEditingController();
    final p = ref.read(profileProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.t('Add a word', 'Kelime ekle', 'Wort hinzufügen')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: target,
            autofocus: true,
            decoration: InputDecoration(labelText: '${langNames[p.targetLang]![ref.uiLang] ?? ''}${p.targetLang == 'de' ? ' (+ der/die/das)' : ''}'),
          ),
          const SizedBox(height: 10),
          TextField(controller: gloss, decoration: InputDecoration(labelText: langNames[p.nativeLang]![ref.uiLang] ?? '')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.t('Cancel', 'İptal', 'Abbrechen'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ref.t('Add', 'Ekle', 'Hinzufügen'))),
        ],
      ),
    );
    if (ok == true && target.text.trim().isNotEmpty) {
      final t = target.text.trim(), g = gloss.text.trim();
      final forms = {'de': '', 'en': '', 'tr': ''}
        ..[p.targetLang] = t
        ..[p.nativeLang] = g;
      ref.read(deckProvider.notifier).add([
        Word(id: 'my_${Word.idFor('${p.targetLang}_$t')}', de: forms['de']!, en: forms['en']!, tr: forms['tr']!, custom: true, topic: 'mine', emoji: '📝'),
      ]);
    }
    target.dispose();
    gloss.dispose();
  }
}
