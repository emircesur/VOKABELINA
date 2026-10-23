import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../services/api.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import '../../widgets/picture_card.dart';

Future<void> showWordSheet(BuildContext context, Word word) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, scroll) => WordSheet(word: word, scroll: scroll),
      ),
    );

/// AI insight per word, cached for the session.
final wordInsightProvider = FutureProvider.autoDispose.family<WordInsight, ({Word word, bool image})>((ref, k) async {
  ref.keepAlive();
  return ref.read(apiProvider).word(k.word, profile: ref.read(profileProvider), image: k.image);
});

/// Flip-able picture card with audio, grammar info and an AI "memory trick".
class WordSheet extends ConsumerStatefulWidget {
  const WordSheet({super.key, required this.word, this.scroll});
  final Word word;
  final ScrollController? scroll;

  @override
  ConsumerState<WordSheet> createState() => _WordSheetState();
}

class _WordSheetState extends ConsumerState<WordSheet> {
  bool flipped = false;
  bool askAi = false;
  bool wantImage = false;

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final w = widget.word;
    final target = p.targetLang;
    final card = ref.watch(deckProvider.select((d) => d.cards[cardKey(target, w.id)]));
    final cs = Theme.of(context).colorScheme;

    Widget face(bool back) => Card(
          child: SizedBox(
            width: double.infinity,
            height: 260,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                PictureTile(word: w, size: 104, showGender: target == 'de'),
                const SizedBox(height: 14),
                if (!back) ...[
                  TargetWordText(word: w, lang: target, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                  if (target == 'de' && w.pluralForm != null) Text('${ref.t('plural', 'çoğul', 'Plural')}: ${w.pluralForm}', style: TextStyle(color: Theme.of(context).hintColor)),
                ] else ...[
                  Text(w.gloss(p.nativeLang), textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: cs.primary)),
                  if (target == 'de' && w.example.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 8), child: Text('„${w.example}“', textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic))),
                ],
              ]),
            ),
          ),
        );

    return ListView(controller: widget.scroll, padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), children: [
      GestureDetector(
        onTap: () => setState(() => flipped = !flipped),
        child: FlipCard(flipped: flipped, front: face(false), back: face(true)),
      ),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FilledButton.tonalIcon(onPressed: () => speak(w.inLang(target), target), icon: const Icon(Icons.volume_up), label: Text(ref.t('Listen', 'Dinle', 'Anhören'))),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(onPressed: () => speak(w.inLang(target), target, 0.25), icon: const Icon(Icons.slow_motion_video), label: Text(ref.t('Slow', 'Yavaş', 'Langsam'))),
        const SizedBox(width: 8),
        IconButton.filledTonal(tooltip: ref.t('Flip', 'Çevir', 'Umdrehen'), onPressed: () => setState(() => flipped = !flipped), icon: const Icon(Icons.flip)),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
        for (final l in targetLangs)
          Chip(avatar: Text(langFlags[l]!), label: Text(w.inLang(l)), visualDensity: VisualDensity.compact),
      ]),
      const SizedBox(height: 10),
      if (card == null)
        FilledButton.icon(
          onPressed: () => ref.read(deckProvider.notifier).add([w]),
          icon: const Icon(Icons.add),
          label: Text(ref.t('Add to my cards', 'Kartlarıma ekle', 'Zu meinen Karten')),
        )
      else
        Row(children: [
          Expanded(child: LinearProgressIndicator(value: card.mastery, minHeight: 8, borderRadius: BorderRadius.circular(8), color: card.isKnown ? Brand.green : Brand.gold)),
          const SizedBox(width: 10),
          Text('${(card.mastery * 100).round()}% · ${ref.t('next review', 'sonraki tekrar', 'nächste Wiederholung')}: ${_due(card.due)}', style: const TextStyle(fontSize: 12)),
        ]),
      const SizedBox(height: 20),
      Text('✨ ${ref.t('AI word coach', 'Yapay zekâ kelime koçu', 'KI-Wortcoach')}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      if (!askAi)
        Wrap(spacing: 8, children: [
          OutlinedButton.icon(
            onPressed: () => setState(() => askAi = true),
            icon: const Icon(Icons.psychology_alt_outlined),
            label: Text(ref.t('Memory trick & examples', 'Hafıza ipucu ve örnekler', 'Merkhilfe & Beispiele')),
          ),
          OutlinedButton.icon(
            onPressed: () => setState(() {
              askAi = true;
              wantImage = true;
            }),
            icon: const Icon(Icons.image_outlined),
            label: Text(ref.t('+ AI picture', '+ AI görseli', '+ KI-Bild')),
          ),
        ])
      else
        _Insight(word: w, image: wantImage, target: target),
    ]);
  }

  String _due(DateTime d) {
    final diff = d.difference(ref.read(clockProvider)());
    if (diff.inMinutes <= 0) return ref.t('now', 'şimdi', 'jetzt');
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} ${ref.t('d', 'g', 'T')}';
  }
}

class _Insight extends ConsumerWidget {
  const _Insight({required this.word, required this.image, required this.target});
  final Word word;
  final bool image;
  final String target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(wordInsightProvider((word: word, image: image)));
    return async.when(
      loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(
        e is ApiException && (e.noProvider || e.code == 'not_configured')
            ? ref.t('The AI coach needs the server (Me → Settings).', 'Yapay zekâ koçu için sunucu gerekli (Ben → Ayarlar).', 'Der KI-Coach braucht den Server (Ich → Einstellungen).')
            : '$e',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      data: (i) => SlideFadeIn(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (i.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(i.imageUrl, height: 200, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
          if (i.mnemonic.isNotEmpty) ...[
            const SizedBox(height: 10),
            SpeechBubble(child: Text('🧠 ${i.mnemonic}', style: const TextStyle(fontSize: 15.5))),
          ],
          if (i.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('📐 ${i.notes}')),
          for (final (text, tr) in i.examples)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speak(text, target)),
              title: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(tr),
            ),
          if (i.related.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(ref.t('Related words', 'İlgili kelimeler', 'Verwandte Wörter'), style: const TextStyle(fontWeight: FontWeight.w900)),
            for (final w in i.related) WordRow(word: w, onSpeak: () => speak(w.inLang(target), target)),
          ],
        ]),
      ),
    );
  }
}
