import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n.dart';
import '../data/models.dart';
import '../state/providers.dart';
import 'mascot.dart';

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.child, this.tailLeft = true});
  final Widget child;
  final bool tailLeft;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(tailLeft ? 4 : 18),
          bottomRight: Radius.circular(tailLeft ? 18 : 4),
        ),
        border: Border.all(color: cs.outlineVariant, width: 1.5),
      ),
      child: child,
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({super.key, required this.icon, required this.label, this.color});
  final String icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: (color ?? Theme.of(context).colorScheme.primary).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

/// A word in the target language with its meaning; the trailing button adds it
/// to the deck (or shows a check if present). Tapping the picture opens the card.
class WordRow extends ConsumerWidget {
  const WordRow({super.key, required this.word, this.onSpeak, this.onOpen});
  final Word word;
  final VoidCallback? onSpeak;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final inDeck = ref.watch(deckProvider.select((d) => d.has(p.targetLang, word.id)));
    final title = word.inLang(p.targetLang).isEmpty ? word.de : word.inLang(p.targetLang);
    final gloss = word.gloss(p.nativeLang);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: word.emoji.isEmpty ? null : GestureDetector(onTap: onOpen, child: Text(word.emoji, style: const TextStyle(fontSize: 26))),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      subtitle: gloss == title ? null : Text(gloss),
      onTap: onSpeak,
      trailing: inDeck
          ? const Icon(Icons.check_circle, color: Colors.green)
          : IconButton(
              tooltip: ref.t('Add to my cards', 'Kartlarıma ekle', 'Zu meinen Karten'),
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                ref.read(deckProvider.notifier).add([word]);
                ref.read(profileProvider.notifier).addXp(1);
              },
            ),
    );
  }
}

/// Small mascot + speech bubble row used at the top of screens.
class MascotSays extends ConsumerWidget {
  const MascotSays({super.key, required this.text, this.sub, this.mood = 'idle', this.size = 96});
  final String text;
  final String? sub;
  final String mood;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(profileProvider.select((p) => p.persona));
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Mascot(personaId: persona, mood: mood, size: size),
      const SizedBox(width: 8),
      Expanded(
        child: SpeechBubble(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (sub != null && sub!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text(sub!, style: TextStyle(color: Theme.of(context).hintColor))),
          ]),
        ),
      ),
    ]);
  }
}
