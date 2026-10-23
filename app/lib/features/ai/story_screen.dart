import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../services/api.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';

/// Graded reader: a short AI story using the learner's known/weak words and interests.
class StoryScreen extends ConsumerStatefulWidget {
  const StoryScreen({super.key});
  @override
  ConsumerState<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends ConsumerState<StoryScreen> {
  Story? story;
  String? error;
  bool showTranslation = false;
  final answers = <int, int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      story = null;
      error = null;
      answers.clear();
    });
    final p = ref.read(profileProvider);
    final learner = ref.read(learnerProvider);
    final words = {...learner.pickWeak(4), ...learner.known.take(10)}.map((w) => w.inLang(p.targetLang)).toList();
    try {
      final s = await ref.read(apiProvider).story(profile: p, words: words, interests: ref.read(memoryProvider).interests);
      if (mounted) setState(() => story = s);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => error = e.noProvider || e.code == 'not_configured'
            ? ref.t('Stories are written by the AI — connect the server in Me → Settings.', 'Hikâyeleri yapay zekâ yazar — Ben → Ayarlar’dan sunucuya bağlan.',
                'Geschichten schreibt die KI – verbinde den Server unter Ich → Einstellungen.')
            : e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final s = story;
    return Scaffold(
      appBar: AppBar(
        title: Text('📖 ${ref.t('AI story', 'AI hikâye', 'KI-Geschichte')}'),
        actions: [IconButton(tooltip: ref.t('New story', 'Yeni hikâye', 'Neue Geschichte'), onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: error != null
              ? Padding(padding: const EdgeInsets.all(24), child: MascotSays(text: error!, mood: 'sad'))
              : s == null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Mascot(personaId: p.persona, mood: 'thinking', size: 140),
                        Text(ref.t('Writing a story with your words…', 'Kelimelerinle bir hikâye yazıyorum…', 'Ich schreibe eine Geschichte mit deinen Wörtern…')),
                      ]),
                    )
                  : ListView(padding: const EdgeInsets.all(16), children: [
                      SlideFadeIn(child: Text(s.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                      const SizedBox(height: 10),
                      SlideFadeIn(
                        index: 1,
                        child: SpeechBubble(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              const Spacer(),
                              IconButton(onPressed: () => speak(s.text, p.targetLang), icon: const Icon(Icons.volume_up)),
                              IconButton(onPressed: () => speak(s.text, p.targetLang, 0.3), icon: const Icon(Icons.slow_motion_video)),
                            ]),
                            SelectableText(s.text, style: const TextStyle(fontSize: 17.5, height: 1.5)),
                            if (showTranslation && s.translation.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text(s.translation, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontStyle: FontStyle.italic, height: 1.45)),
                            ],
                          ]),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => showTranslation = !showTranslation),
                        icon: const Icon(Icons.translate),
                        label: Text(showTranslation ? ref.t('Hide translation', 'Çeviriyi gizle', 'Übersetzung ausblenden') : ref.t('Show translation', 'Çeviriyi göster', 'Übersetzung zeigen')),
                      ),
                      if (s.glossary.isNotEmpty) ...[
                        Text(ref.t('Glossary', 'Sözlükçe', 'Glossar'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        for (final w in s.glossary) WordRow(word: w, onSpeak: () => speak(w.inLang(p.targetLang), p.targetLang)),
                      ],
                      if (s.questions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(ref.t('Did you understand?', 'Anladın mı?', 'Hast du es verstanden?'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        for (final (qi, q) in s.questions.indexed)
                          Card(
                            margin: const EdgeInsets.only(top: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(q.question, style: const TextStyle(fontWeight: FontWeight.w800)),
                                const SizedBox(height: 6),
                                Wrap(spacing: 8, runSpacing: 8, children: [
                                  for (final (oi, o) in q.options.indexed)
                                    ChoiceChip(
                                      label: Text(o),
                                      selected: answers[qi] == oi,
                                      selectedColor: answers[qi] == null ? null : (oi == q.answer ? Brand.green.withValues(alpha: 0.3) : Brand.red.withValues(alpha: 0.3)),
                                      onSelected: answers.containsKey(qi)
                                          ? null
                                          : (_) {
                                              setState(() => answers[qi] = oi);
                                              if (oi == q.answer) ref.read(profileProvider.notifier).addXp(2);
                                            },
                                    ),
                                ]),
                                if (answers.containsKey(qi) && answers[qi] != q.answer && q.answer < q.options.length)
                                  Padding(padding: const EdgeInsets.only(top: 6), child: Text('✔ ${q.options[q.answer]}', style: const TextStyle(color: Brand.green, fontWeight: FontWeight.w800))),
                              ]),
                            ),
                          ),
                      ],
                    ]),
        ),
      ),
    );
  }
}
