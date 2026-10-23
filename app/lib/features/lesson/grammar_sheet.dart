import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../data/content.dart';
import '../../services/api.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/common.dart';

/// AI grammar explanation in the learner's own language, with follow-up questions.
Future<void> showGrammarSheet(BuildContext context, {required String topic}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: _GrammarSheet(topic: topic),
      ),
    );

class _GrammarSheet extends ConsumerStatefulWidget {
  const _GrammarSheet({required this.topic});
  final String topic;
  @override
  ConsumerState<_GrammarSheet> createState() => _GrammarSheetState();
}

class _GrammarSheetState extends ConsumerState<_GrammarSheet> {
  final _q = TextEditingController();
  GrammarExplanation? result;
  String? error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _ask();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _ask([String question = '']) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await ref.read(apiProvider).grammar(profile: ref.read(profileProvider), topic: widget.topic, question: question);
      if (mounted) setState(() => result = r);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => error = e.noProvider || e.code == 'not_configured'
            ? ref.t('AI explanations need the server (Me → Settings).', 'Yapay zekâ açıklamaları için sunucu gerekli (Ben → Ayarlar).', 'KI-Erklärungen brauchen den Server (Ich → Einstellungen).')
            : e.message);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = ref.watch(profileProvider.select((p) => p.targetLang));
    final r = result;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          if (busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (r != null && !busy)
            SlideFadeIn(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                SpeechBubble(child: Text(r.explanation, style: const TextStyle(height: 1.45))),
                for (final (text, tr) in r.examples)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: IconButton(icon: const Icon(Icons.volume_up), onPressed: () => speak(text, target)),
                    title: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(tr),
                  ),
              ]),
            ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _q, decoration: InputDecoration(hintText: ref.t('Ask a follow-up question…', 'Ek bir soru sor…', 'Stell eine Nachfrage…'), isDense: true))),
            const SizedBox(width: 8),
            IconButton.filled(onPressed: busy ? null : () => _ask(_q.text.trim()), icon: const Icon(Icons.send)),
          ]),
        ]),
      ),
    );
  }
}
