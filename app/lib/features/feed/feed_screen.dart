import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../services/api.dart';
import '../../services/tts.dart';
import '../../state/feed.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Align(alignment: Alignment.centerLeft, child: Text('Kultur', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900))),
        ),
        TabBar(tabs: [Tab(text: ref.t('Memes', 'Memler')), Tab(text: ref.t('News', 'Haberler'))]),
        const Expanded(child: TabBarView(children: [_MemesTab(), _NewsTab()])),
      ]),
    );
  }
}

// ------------------------------------------------------------------- memes

class _MemesTab extends ConsumerWidget {
  const _MemesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(memesProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (d) => Column(children: [
        if (d.offline)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(ref.t('Showing bundled memes — connect the AI server for fresh daily ones.', 'Hazır memler gösteriliyor — her gün yenileri için yapay zekâ sunucusunu bağla.'),
                style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12.5)),
          ),
        Expanded(
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: d.memes.length,
            itemBuilder: (_, i) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14), child: _MemeCard(meme: d.memes[i], index: i)),
          ),
        ),
        Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(ref.t('Swipe for more →', 'Daha fazlası için kaydır →'), style: TextStyle(color: Theme.of(context).hintColor))),
      ]),
    );
  }
}

class _MemeCard extends ConsumerStatefulWidget {
  const _MemeCard({required this.meme, required this.index});
  final Meme meme;
  final int index;

  @override
  ConsumerState<_MemeCard> createState() => _MemeCardState();
}

class _MemeCardState extends ConsumerState<_MemeCard> {
  bool explained = false;

  static const _palettes = [
    [Color(0xFFE8832A), Color(0xFFD64545)],
    [Color(0xFF1F8A8A), Color(0xFF2B5EA7)],
    [Color(0xFF7B4FB8), Color(0xFFD64545)],
    [Color(0xFF3FA96B), Color(0xFF1F8A8A)],
    [Color(0xFFC98A3C), Color(0xFF8A4B1C)],
  ];

  Widget _memeText(String text) {
    // white fill with dark outline, as on classic image macros
    TextStyle base(Paint? stroke) => TextStyle(fontSize: 22, height: 1.15, fontWeight: FontWeight.w900, foreground: stroke, color: stroke == null ? Colors.white : null);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.black.withValues(alpha: 0.75);
    return Stack(children: [
      Text(text, textAlign: TextAlign.center, style: base(outline)),
      Text(text, textAlign: TextAlign.center, style: base(null)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meme;
    final profile = ref.watch(profileProvider);
    final colors = _palettes[widget.index % _palettes.length];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight)),
            child: Stack(children: [
              Column(children: [
                _memeText(m.top),
                Expanded(child: Center(child: Text(m.emoji, style: const TextStyle(fontSize: 84)))),
                _memeText(m.bottom),
              ]),
              Positioned(right: 0, bottom: 56, child: Mascot(personaId: profile.persona, mood: 'happy', size: 56)),
              Positioned(left: 0, bottom: 56, child: IconButton(tooltip: ref.t('Listen', 'Dinle'), color: Colors.white, icon: const Icon(Icons.volume_up), onPressed: () => speak('${m.top} ${m.bottom}', profile.targetLang))),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: explained
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.explain(profile.nativeLang), style: const TextStyle(fontSize: 14.5)),
                  for (final w in m.vocab) WordRow(word: w, onSpeak: () => speak(w.inLang(profile.targetLang), profile.targetLang)),
                ])
              : FilledButton.tonalIcon(
                  onPressed: () => setState(() => explained = true),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: Text(ref.t('Explain the joke', 'Şakayı açıkla')),
                ),
        ),
      ]),
    );
  }
}

// -------------------------------------------------------------------- news

class _NewsTab extends ConsumerWidget {
  const _NewsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(newsProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(newsProvider.future),
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const Mascot(personaId: 'bruno', mood: 'sad', size: 120),
              const SizedBox(height: 12),
              Text(
                e is ApiException && e.code == 'not_configured'
                    ? ref.t('News needs the Vokabelina server. Set its URL under Me → Settings.', 'Haberler için Vokabelina sunucusu gerekir. URL’yi Ben → Ayarlar’dan gir.')
                    : ref.t('Could not load the news. Pull down to retry.', 'Haberler yüklenemedi. Yenilemek için aşağı çek.'),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ]),
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final n = items[i];
            return Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => context.push('/article', extra: n),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.source.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: Theme.of(context).colorScheme.secondary)),
                    const SizedBox(height: 4),
                    Text(n.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    if (n.summary.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(n.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).hintColor))),
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.auto_awesome, size: 16, color: Brand.gold),
                      const SizedBox(width: 6),
                      Text(ref.t('Read at your level', 'Seviyene göre oku'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ]),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
