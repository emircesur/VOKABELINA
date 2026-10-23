import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/personas.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../words/word_sheet.dart';
import 'translator_sheet.dart';

/// Free conversation with the AI tutor.
class TutorScreen extends ConsumerWidget {
  const TutorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatProvider);
    final p = ref.watch(profileProvider);
    final persona = personaOf(p.persona);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
        child: Row(children: [
          Mascot(personaId: p.persona, mood: chat.sending ? 'thinking' : chat.mood, size: 64),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(persona.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text(chat.sending ? ref.t('thinking…', 'düşünüyor…', 'denkt nach…') : '${langFlags[p.targetLang]} ${p.level}', style: TextStyle(color: Theme.of(context).hintColor)),
            ]),
          ),
          IconButton(tooltip: ref.t('Translator', 'Çevirmen', 'Übersetzer'), icon: const Icon(Icons.translate), onPressed: () => showTranslatorSheet(context)),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') ref.read(chatProvider.notifier).clear();
            },
            itemBuilder: (_) => [PopupMenuItem(value: 'clear', child: Text(ref.t('New conversation', 'Yeni sohbet', 'Neues Gespräch')))],
          ),
        ]),
      ),
      Expanded(child: ChatView(provider: chatProvider)),
    ]);
  }
}

/// Message list + suggestions + input for any [ChatNotifier] (free chat or role-play).
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key, required this.provider, this.emptyHint});
  final NotifierProvider<ChatNotifier, ChatState> provider;
  final Widget? emptyHint;

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
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
    ref.read(widget.provider.notifier).send(t);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(widget.provider);
    final p = ref.watch(profileProvider);
    final persona = personaOf(p.persona);

    ref.listen(widget.provider.select((c) => c.messages.length), (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent + 200, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });
    });

    final msgs = chat.messages;
    final lastBot = msgs.isNotEmpty && !msgs.last.fromUser ? msgs.last : null;

    return Column(children: [
      if (chat.notice != null) _notice(chat.notice!),
      Expanded(
        child: msgs.isEmpty
            ? (widget.emptyHint ?? _empty(persona, p.targetLang))
            : ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                itemCount: msgs.length + (chat.sending ? 1 : 0),
                itemBuilder: (_, i) => i == msgs.length ? _typing() : SlideFadeIn(key: ValueKey(msgs[i].id), offset: 12, child: _bubble(msgs[i], p.targetLang)),
              ),
      ),
      if (lastBot != null && lastBot.suggestions.isNotEmpty && !chat.sending)
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final s in lastBot.suggestions) Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(s), onPressed: () => _send(s))),
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
              decoration: InputDecoration(
                  hintText: ref.t('Write in ${langNames[p.targetLang]!['en']}…', '${langNames[p.targetLang]!['tr']} yaz…', 'Auf ${langNames[p.targetLang]!['de']} schreiben…')),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(tooltip: ref.t('Send', 'Gönder', 'Senden'), onPressed: chat.sending ? null : _send, icon: const Icon(Icons.send)),
        ]),
      ),
    ]);
  }

  Widget _notice(String code) {
    final text = switch (code) {
      'noProvider' => ref.t('The server has no AI key yet — offline practice mode. (Admin: add a key at /admin.)', 'Sunucuda henüz yapay zekâ anahtarı yok — çevrimdışı alıştırma modu. (Yönetici: /admin’den anahtar ekle.)',
          'Der Server hat noch keinen KI-Schlüssel – Offline-Übungsmodus. (Admin: Schlüssel unter /admin eintragen.)'),
      'notConfigured' => ref.t('No server set — offline practice mode. Set it under Me → Settings.', 'Sunucu ayarlanmamış — çevrimdışı alıştırma modu. Ben → Ayarlar’dan ayarla.',
          'Kein Server eingestellt – Offline-Übungsmodus. Unter Ich → Einstellungen eintragen.'),
      _ => ref.t('Server not reachable — offline practice mode.', 'Sunucuya ulaşılamıyor — çevrimdışı alıştırma modu.', 'Server nicht erreichbar – Offline-Übungsmodus.'),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Brand.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [const Icon(Icons.cloud_off, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: const TextStyle(fontSize: 13)))]),
    );
  }

  Widget _empty(Persona persona, String target) {
    final starters = switch (target) {
      'en' => ['Hi!', "I'm learning English.", 'How are you?'],
      'tr' => ['Merhaba!', 'Türkçe öğreniyorum.', 'Nasılsın?'],
      _ => ['Hallo!', 'Ich lerne Deutsch.', 'Wie geht es dir?'],
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PopIn(child: Mascot(personaId: persona.id, mood: 'wave', size: 150)),
          const SizedBox(height: 12),
          Text(
            persona.greeting(target),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            ref.t('I remember your words, mistakes and stories — and talk at your level.', 'Kelimelerini, hatalarını ve anlattıklarını hatırlıyorum — seviyene göre konuşurum.',
                'Ich merke mir deine Wörter, Fehler und Geschichten – und spreche auf deinem Niveau.'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [for (final s in starters) ActionChip(label: Text(s), onPressed: () => _send(s))]),
        ]),
      ),
    );
  }

  Widget _typing() => const Align(
        alignment: Alignment.centerLeft,
        child: Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 40, child: LinearProgressIndicator(minHeight: 4))),
      );

  Widget _bubble(ChatMessage m, String target) {
    final cs = Theme.of(context).colorScheme;
    if (m.fromUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomLeft: Radius.circular(18), bottomRight: Radius.circular(4))),
          child: SelectableText(m.text, style: TextStyle(color: cs.onPrimary, fontSize: 16)),
        ),
      );
    }
    final showNative = _shownNative.contains(m.id);
    final notifier = ref.read(widget.provider.notifier);
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
                _mini(Icons.volume_up, ref.t('Listen', 'Dinle', 'Anhören'), () => speak(m.text, target)),
                if (m.native.isNotEmpty) _mini(Icons.translate, ref.t('Translate', 'Çevir', 'Übersetzen'), () => setState(() => showNative ? _shownNative.remove(m.id) : _shownNative.add(m.id))),
                if (!m.offline && m.id != 'open') ...[
                  _mini(m.rating == 1 ? Icons.thumb_up : Icons.thumb_up_outlined, ref.t('Good reply', 'İyi cevap', 'Gute Antwort'), () => notifier.rate(m.id, m.rating == 1 ? 0 : 1)),
                  _mini(m.rating == -1 ? Icons.thumb_down : Icons.thumb_down_outlined, ref.t('Bad reply', 'Kötü cevap', 'Schlechte Antwort'), () => notifier.rate(m.id, m.rating == -1 ? 0 : -1)),
                ],
              ]),
            ]),
          ),
          for (final c in m.corrections) PopIn(child: _correction(c)),
          if (m.newWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ref.t('New words', 'Yeni kelimeler', 'Neue Wörter'), style: const TextStyle(fontWeight: FontWeight.w900)),
                    for (final w in m.newWords) WordRow(word: w, onSpeak: () => speak(w.inLang(target), target), onOpen: () => showWordSheet(context, w)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _mini(IconData icon, String tip, VoidCallback onTap) => IconButton(tooltip: tip, visualDensity: VisualDensity.compact, iconSize: 19, icon: Icon(icon), onPressed: onTap);

  Widget _correction(Correction c) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Brand.green.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14), border: Border.all(color: Brand.green.withValues(alpha: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (c.tag.isNotEmpty) Text('🏷️ ${c.tag}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          Text(c.original, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Brand.red)),
          Text(c.corrected, style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.green)),
          if (c.explanation.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(c.explanation, style: const TextStyle(fontSize: 13.5))),
        ]),
      );
}
