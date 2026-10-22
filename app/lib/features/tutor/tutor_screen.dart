import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/personas.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import 'translator_sheet.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _shownNative = <String>{};

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final t = (text ?? _input.text).trim();
    if (t.isEmpty) return;
    _input.clear();
    ref.read(chatProvider.notifier).send(t);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final profile = ref.watch(profileProvider);
    final persona = personaOf(profile.persona);

    ref.listen(chatProvider.select((c) => c.messages.length), (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });
    });

    final msgs = chat.messages;
    final lastBot = msgs.isNotEmpty && !msgs.last.fromUser ? msgs.last : null;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
        child: Row(children: [
          Mascot(personaId: profile.persona, mood: chat.sending ? 'thinking' : chat.mood, size: 64),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(persona.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(chat.sending ? ref.t('thinking…', 'düşünüyor…') : 'Level ${profile.level}', style: TextStyle(color: Theme.of(context).hintColor)),
            ]),
          ),
          IconButton(tooltip: ref.t('Translator', 'Çevirmen'), icon: const Icon(Icons.translate), onPressed: () => showTranslatorSheet(context)),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') ref.read(chatProvider.notifier).clear();
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'clear', child: Text(ref.t('New conversation', 'Yeni sohbet')))],
          ),
        ]),
      ),
      if (chat.notice != null) _notice(chat.notice!),
      Expanded(
        child: msgs.isEmpty
            ? _empty(persona)
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: msgs.length + (chat.sending ? 1 : 0),
                itemBuilder: (_, i) => i == msgs.length ? _typing() : _bubble(msgs[i]),
              ),
      ),
      if (lastBot != null && lastBot.suggestions.isNotEmpty && !chat.sending)
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final s in lastBot.suggestions)
                Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(s), onPressed: () => _send(s))),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(hintText: ref.t('Write in German…', 'Almanca yaz…')),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: ref.t('Send', 'Gönder'),
            onPressed: chat.sending ? null : _send,
            icon: const Icon(Icons.send),
          ),
        ]),
      ),
    ]);
  }

  Widget _notice(String code) {
    final text = switch (code) {
      'noProvider' => ref.t('The server has no AI key yet — offline practice mode. (Admin: add a key at /admin.)', 'Sunucuda henüz yapay zekâ anahtarı yok — çevrimdışı alıştırma modu. (Yönetici: /admin’den anahtar ekle.)'),
      'notConfigured' => ref.t('No server set — offline practice mode. Set it under Me → Settings.', 'Sunucu ayarlanmamış — çevrimdışı alıştırma modu. Ben → Ayarlar’dan ayarla.'),
      _ => ref.t('Server not reachable — offline practice mode.', 'Sunucuya ulaşılamıyor — çevrimdışı alıştırma modu.'),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Brand.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.cloud_off, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _empty(Persona persona) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Mascot(personaId: persona.id, mood: 'happy', size: 150),
            const SizedBox(height: 12),
            Text(persona.hello, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: [
              for (final s in ['Hallo!', 'Ich lerne Deutsch.', 'Wie geht es dir?'])
                ActionChip(label: Text(s), onPressed: () => _send(s)),
            ]),
          ]),
        ),
      );

  Widget _typing() => const Align(
        alignment: Alignment.centerLeft,
        child: Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 40, child: LinearProgressIndicator(minHeight: 4))),
      );

  Widget _bubble(ChatMessage m) {
    final cs = Theme.of(context).colorScheme;
    if (m.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: cs.primary, borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4))),
          child: SelectableText(m.text, style: TextStyle(color: cs.onPrimary, fontSize: 16)),
        ),
      );
    }
    final showNative = _shownNative.contains(m.id);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SpeechBubble(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SelectableText(m.text, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w600)),
              if (showNative && m.native.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(m.native, style: TextStyle(color: cs.secondary, fontStyle: FontStyle.italic))),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [
                _mini(Icons.volume_up, ref.t('Listen', 'Dinle'), () => speak(m.text)),
                if (m.native.isNotEmpty)
                  _mini(Icons.translate, ref.t('Translate', 'Çevir'), () => setState(() => showNative ? _shownNative.remove(m.id) : _shownNative.add(m.id))),
                if (!m.offline) ...[
                  _mini(m.rating == 1 ? Icons.thumb_up : Icons.thumb_up_outlined, ref.t('Good reply', 'İyi cevap'), () => ref.read(chatProvider.notifier).rate(m.id, m.rating == 1 ? 0 : 1)),
                  _mini(m.rating == -1 ? Icons.thumb_down : Icons.thumb_down_outlined, ref.t('Bad reply', 'Kötü cevap'), () => ref.read(chatProvider.notifier).rate(m.id, m.rating == -1 ? 0 : -1)),
                ],
              ]),
            ]),
          ),
          for (final c in m.corrections) _correction(c),
          if (m.newWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ref.t('New words', 'Yeni kelimeler'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    for (final w in m.newWords) WordRow(word: w, onSpeak: () => speak(w.de)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _mini(IconData icon, String tip, VoidCallback onTap) => IconButton(
        tooltip: tip,
        visualDensity: VisualDensity.compact,
        iconSize: 19,
        icon: Icon(icon),
        onPressed: onTap,
      );

  Widget _correction(Correction c) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Brand.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Brand.green.withValues(alpha: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.original, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Brand.red)),
          Text(c.corrected, style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.green)),
          if (c.explanation.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(c.explanation, style: const TextStyle(fontSize: 13.5))),
        ]),
      );
}
