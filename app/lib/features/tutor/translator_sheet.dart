import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../data/content.dart';
import '../../data/models.dart';
import '../../services/api.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';

Future<void> showTranslatorSheet(BuildContext context, {String initial = ''}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: TranslatorSheet(initial: initial),
      ),
    );

/// AI translator: German ⇄ native language, with notes and tap-to-add words.
class TranslatorSheet extends ConsumerStatefulWidget {
  const TranslatorSheet({super.key, this.initial = ''});
  final String initial;

  @override
  ConsumerState<TranslatorSheet> createState() => _TranslatorSheetState();
}

class _TranslatorSheetState extends ConsumerState<TranslatorSheet> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);
  bool toGerman = false;
  bool busy = false;
  Translation? result;
  String? error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    final profile = ref.read(profileProvider);
    setState(() {
      busy = true;
      error = null;
      result = null;
    });
    try {
      final r = await ref.read(apiProvider).translate(text, from: toGerman ? profile.nativeLang : profile.targetLang, to: toGerman ? profile.targetLang : profile.nativeLang, level: profile.level, nativeLang: profile.nativeLang);
      if (mounted) setState(() => result = r);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => error = e.noProvider || e.code == 'not_configured'
            ? ref.t('Translation needs the AI server. Set it up under Me → Settings.', 'Çeviri için yapay zekâ sunucusu gerekir. Ben → Ayarlar’dan kur.')
            : ref.t('Could not translate: ${e.message}', 'Çevrilemedi: ${e.message}'));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final native = langNames[p.nativeLang]![p.nativeLang]!;
    final targetName = langNames[p.targetLang]![p.nativeLang]!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(toGerman ? native : targetName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            IconButton(tooltip: ref.t('Swap', 'Değiştir'), icon: const Icon(Icons.swap_horiz), onPressed: () => setState(() {
                  toGerman = !toGerman;
                  result = null;
                })),
            Text(toGerman ? targetName : native, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ]),
          TextField(controller: _c, minLines: 2, maxLines: 5, decoration: InputDecoration(hintText: ref.t('Type text…', 'Metin yaz…'))),
          const SizedBox(height: 12),
          ChunkyButton(label: busy ? '…' : ref.t('Translate', 'Çevir'), onPressed: busy ? null : _run, compact: true),
          if (error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
          if (result != null) ...[
            const SizedBox(height: 8),
            SpeechBubble(
              child: Row(children: [
                Expanded(child: SelectableText(result!.translation, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                IconButton(icon: const Icon(Icons.volume_up), tooltip: ref.t('Listen', 'Dinle'), onPressed: () => speak(toGerman ? result!.translation : _c.text, p.targetLang)),
              ]),
            ),
            if (result!.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('💡 ${result!.notes}')),
            for (final w in result!.words) WordRow(word: w, onSpeak: () => speak(w.inLang(p.targetLang), p.targetLang)),
          ],
        ]),
      ),
    );
  }
}
