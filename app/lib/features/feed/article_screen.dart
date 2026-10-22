import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/i18n.dart';
import '../../data/content.dart';
import '../../services/tts.dart';
import '../../state/feed.dart';
import '../../state/providers.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';

/// A news item rewritten by the AI at the learner's CEFR level, with translation and keywords.
class ArticleScreen extends ConsumerStatefulWidget {
  const ArticleScreen({super.key, required this.item});
  final NewsItem item;

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  bool showTranslation = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final async = ref.watch(articleProvider((item: widget.item, level: profile.level, lang: profile.nativeLang)));
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.source)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text(widget.item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              async.when(
                loading: () => Column(children: [
                  Mascot(personaId: profile.persona, mood: 'thinking', size: 110),
                  Text(ref.t('Adapting to level ${profile.level}…', '${profile.level} seviyesine uyarlanıyor…')),
                ]),
                error: (e, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.item.summary),
                  const SizedBox(height: 12),
                  Text(ref.t('The AI simplification is unavailable right now ($e).', 'Yapay zekâ sadeleştirmesi şu an kullanılamıyor ($e).'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ]),
                data: (a) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SpeechBubble(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text('Level ${profile.level}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        const Spacer(),
                        IconButton(tooltip: ref.t('Listen', 'Dinle'), icon: const Icon(Icons.volume_up), onPressed: () => speak(a.german)),
                      ]),
                      SelectableText(a.german, style: const TextStyle(fontSize: 18, height: 1.4)),
                      if (showTranslation) ...[
                        const Divider(height: 24),
                        Text(a.translation, style: TextStyle(fontSize: 16, height: 1.4, color: Theme.of(context).colorScheme.secondary, fontStyle: FontStyle.italic)),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => showTranslation = !showTranslation),
                    icon: const Icon(Icons.translate),
                    label: Text(showTranslation ? ref.t('Hide translation', 'Çeviriyi gizle') : ref.t('Show translation', 'Çeviriyi göster')),
                  ),
                  if (a.cultureNote.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text('🇩🇪 ${a.cultureNote}'),
                  ],
                  if (a.keywords.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(ref.t('Key words', 'Anahtar kelimeler'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    for (final w in a.keywords) WordRow(word: w, onSpeak: () => speak(w.de)),
                  ],
                ]),
              ),
              const SizedBox(height: 20),
              if (widget.item.link.isNotEmpty)
                ChunkyButton(
                  compact: true,
                  color: Theme.of(context).colorScheme.secondary,
                  icon: Icons.open_in_new,
                  label: ref.t('Read the original', 'Orijinalini oku'),
                  onPressed: () => launchUrl(Uri.parse(widget.item.link), mode: LaunchMode.externalApplication),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
