import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../data/curriculum.dart';
import '../../data/models.dart';
import '../../services/api.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';

/// Busuu-style free writing, corrected instantly by the AI. `unitId == 'free'`
/// is an open journal entry.
class WritingScreen extends ConsumerStatefulWidget {
  const WritingScreen({super.key, required this.unitId});
  final String unitId;
  @override
  ConsumerState<WritingScreen> createState() => _WritingScreenState();
}

class _WritingScreenState extends ConsumerState<WritingScreen> {
  final _ctl = TextEditingController();
  WritingFeedback? fb;
  String? error;
  bool busy = false;

  Unit? get unit => unitsById[widget.unitId];

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  String _task() {
    final u = unit;
    if (u != null) return pick(u.writing, ref.read(profileProvider).nativeLang);
    return ref.t('Write about your day, your plans or anything you like.', 'Günün, planların ya da istediğin herhangi bir şey hakkında yaz.', 'Schreib über deinen Tag, deine Pläne oder was du möchtest.');
  }

  Future<void> _submit() async {
    final p = ref.read(profileProvider);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await ref.read(apiProvider).checkWriting(profile: p, task: _task(), text: _ctl.text.trim(), memory: ref.read(learnerProvider).toPayload());
      if (!mounted) return;
      setState(() => fb = r);
      // the corrections feed long-term memory
      ref.read(memoryProvider.notifier).addCorrections(p.targetLang, [for (final i in r.items) Correction(original: i.original, corrected: i.corrected, explanation: i.explanation, tag: i.tag)]);
      final u = unit;
      if (u != null) ref.read(progressProvider.notifier).complete('${u.id}_write', correct: r.score, total: 100);
      ref.read(profileProvider.notifier).addXp(10 + r.score ~/ 10);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => error = e.noProvider || e.code == 'not_configured'
            ? ref.t('Writing correction needs the AI server (Me → Settings).', 'Yazma düzeltmesi için yapay zekâ sunucusu gerekli (Ben → Ayarlar).',
                'Die Schreibkorrektur braucht den KI-Server (Ich → Einstellungen).')
            : e.message);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final f = fb;
    return Scaffold(
      appBar: AppBar(title: Text('✍️ ${unit == null ? ref.t('Free writing', 'Serbest yazma', 'Freies Schreiben') : pick(unit!.title, ref.uiLang)}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            MascotSays(text: _task(), mood: f == null ? 'talking' : (f.score >= 80 ? 'cheer' : 'happy'), size: 80),
            const SizedBox(height: 16),
            TextField(
              controller: _ctl,
              minLines: 5,
              maxLines: 12,
              enabled: f == null && !busy,
              decoration: InputDecoration(
                  hintText: ref.t('Write in ${langNames[p.targetLang]!['en']}…', '${langNames[p.targetLang]!['tr']} yaz…', 'Auf ${langNames[p.targetLang]!['de']} schreiben…')),
            ),
            const SizedBox(height: 12),
            if (f == null)
              ListenableBuilder(
                listenable: _ctl,
                builder: (_, _) => ChunkyButton(
                  label: busy ? '…' : ref.t('Check with AI', 'AI ile kontrol et', 'Mit KI prüfen'),
                  icon: Icons.auto_awesome,
                  onPressed: busy || _ctl.text.trim().length < 10 ? null : _submit,
                ),
              ),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            if (f != null) ...[
              const SizedBox(height: 8),
              Confetti(
                play: f.score >= 80,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      ProgressRing(
                        value: f.score / 100,
                        size: 84,
                        stroke: 9,
                        color: f.score >= 80 ? Brand.green : (f.score >= 50 ? Brand.gold : Brand.red),
                        child: CountUp(value: f.score, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (f.level.isNotEmpty) Text('${ref.t('Level of this text', 'Bu metnin seviyesi', 'Niveau dieses Textes')}: ${f.level}', style: const TextStyle(fontWeight: FontWeight.w900)),
                          if (f.praise.isNotEmpty) Text('👏 ${f.praise}'),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(ref.t('Corrected version', 'Düzeltilmiş hâli', 'Korrigierte Fassung'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              SpeechBubble(
                child: Row(children: [
                  Expanded(child: SelectableText(f.corrected, style: const TextStyle(fontSize: 16, height: 1.4))),
                  IconButton(onPressed: () => speak(f.corrected, p.targetLang), icon: const Icon(Icons.volume_up)),
                ]),
              ),
              const SizedBox(height: 10),
              for (final (i, it) in f.items.indexed)
                SlideFadeIn(
                  index: i,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Brand.green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14), border: Border.all(color: Brand.green.withValues(alpha: 0.4))),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (it.tag.isNotEmpty) Text('🏷️ ${it.tag}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                      Text(it.original, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Brand.red)),
                      Text(it.corrected, style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.green)),
                      Text(it.explanation, style: const TextStyle(fontSize: 13.5)),
                    ]),
                  ),
                ),
              if (f.tip.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('💡 ${f.tip}')),
              for (final w in f.newWords) WordRow(word: w, onSpeak: () => speak(w.inLang(p.targetLang), p.targetLang)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      fb = null;
                      _ctl.text = f.corrected;
                    }),
                    child: Text(ref.t('Rewrite', 'Yeniden yaz', 'Neu schreiben')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: ChunkyButton(label: ref.t('Done', 'Bitti', 'Fertig'), onPressed: () => context.pop())),
              ]),
            ],
          ]),
        ),
      ),
    );
  }
}
