import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../data/models.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';

/// Introduces a batch of new words (tap to hear), then adds them to the SRS deck.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  late final List<Word> batch;

  @override
  void initState() {
    super.initState();
    batch = ref.read(deckProvider.notifier).newWordsFor(ref.read(profileProvider).level, 5);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(profileProvider.select((p) => p.nativeLang));
    return Scaffold(
      appBar: AppBar(title: Text(ref.t('New words', 'Yeni kelimeler'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: batch.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: MascotSays(
                      mood: 'cheer',
                      text: ref.t('You have every word in the catalogue! Ask the tutor for more.', 'Katalogdaki tüm kelimeler sende! Öğretmenden yenilerini iste.'),
                    ),
                  )
                : Column(children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: batch.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final w = batch[i];
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              title: Text(w.de, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(w.gloss(lang), style: const TextStyle(fontSize: 16)),
                                  if (w.example.isNotEmpty) Text('„${w.example}“', style: TextStyle(fontStyle: FontStyle.italic, color: Theme.of(context).hintColor)),
                                ]),
                              ),
                              trailing: IconButton(tooltip: ref.t('Listen', 'Dinle'), icon: const Icon(Icons.volume_up), onPressed: () => speak(w.de)),
                              onTap: () => speak(w.de),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ChunkyButton(
                        label: ref.t('Add to my cards', 'Kartlarıma ekle'),
                        onPressed: () {
                          ref.read(deckProvider.notifier).add(batch);
                          ref.read(profileProvider.notifier).addXp(batch.length * 2);
                          context.pop();
                        },
                      ),
                    ),
                  ]),
          ),
        ),
      ),
    );
  }
}
