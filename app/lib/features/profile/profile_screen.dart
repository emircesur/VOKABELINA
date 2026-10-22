import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/personas.dart';
import '../../services/streak.dart';
import '../../state/providers.dart';
import '../../widgets/mascot.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final deck = ref.watch(deckProvider);
    final learner = ref.watch(learnerProvider);
    final memory = ref.watch(memoryProvider);
    final now = ref.watch(clockProvider)();
    final persona = personaOf(profile.persona);
    final known = learner.known;
    final weak = learner.pickWeak(6);
    final n = ref.read(profileProvider.notifier);

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      Row(children: [
        Mascot(personaId: profile.persona, mood: 'happy', size: 84),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(profile.name.isEmpty ? 'Vokabelina' : profile.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text('${profile.level} · ${profile.xp} XP · 🔥 ${liveStreak(profile, now)}', style: TextStyle(color: Theme.of(context).hintColor)),
          ]),
        ),
      ]),
      const SizedBox(height: 20),

      // ---------------------------------------------------------- AI memory hub
      _section(context, '🧠 ${ref.t('${persona.name}\'s memory', '${persona.name} seni böyle hatırlıyor')}'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ref.t('Everything here is sent to your tutor so it can talk at your level. You stay in control.', 'Buradaki her şey öğretmenine gönderilir; böylece seviyene göre konuşur. Kontrol sende.'), style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _metric('${known.length}', ref.t('words known', 'bilinen kelime'), Brand.green)),
              Expanded(child: _metric('${deck.cards.length}', ref.t('in your deck', 'destende'), Brand.teal)),
              Expanded(child: _metric('${memory.mistakes.length}', ref.t('mistake patterns', 'hata kalıbı'), Brand.red)),
            ]),
            const SizedBox(height: 14),
            _label(ref.t('Practising now (weakest words)', 'Şu an çalışılan (en zayıf kelimeler)')),
            weak.isEmpty
                ? Text(ref.t('Chat and review to build this list.', 'Sohbet et ve tekrar yap, liste oluşsun.'), style: TextStyle(color: Theme.of(context).hintColor))
                : Wrap(spacing: 6, runSpacing: 6, children: [for (final w in weak) Chip(label: Text(w.de), visualDensity: VisualDensity.compact)]),
            const SizedBox(height: 14),
            _label(ref.t('Recurring mistakes', 'Tekrarlayan hatalar')),
            if (memory.mistakes.isEmpty)
              Text(ref.t('None yet — nice!', 'Henüz yok — harika!'), style: TextStyle(color: Theme.of(context).hintColor))
            else
              for (final m in memory.topMistakes(5)) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $m (×${memory.mistakes[m]})')),
            const SizedBox(height: 14),
            _label(ref.t('Things I know about you', 'Senin hakkında bildiklerim')),
            if (memory.facts.isEmpty)
              Text(ref.t('Tell your tutor about yourself — job, hobbies, city.', 'Öğretmenine kendinden bahset — iş, hobiler, şehir.'), style: TextStyle(color: Theme.of(context).hintColor))
            else
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final f in memory.facts) InputChip(label: Text(f), onDeleted: () => ref.read(memoryProvider.notifier).removeFact(f), visualDensity: VisualDensity.compact),
              ]),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ref.read(memoryProvider.notifier).clear(),
                child: Text(ref.t('Forget everything', 'Hepsini unut')),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 24),

      // --------------------------------------------------------------- settings
      _section(context, '⚙️ ${ref.t('Settings', 'Ayarlar')}'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label(ref.t('My language', 'Ana dilim')),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'tr', label: Text('Türkçe')), ButtonSegment(value: 'en', label: Text('English'))],
              selected: {profile.nativeLang},
              onSelectionChanged: (s) => n.update((p) => p.copyWith(nativeLang: s.first)),
            ),
            const SizedBox(height: 16),
            _label(ref.t('German level', 'Almanca seviyesi')),
            Wrap(spacing: 8, children: [
              for (final l in levels) ChoiceChip(label: Text(l), selected: profile.level == l, onSelected: (_) => n.update((p) => p.copyWith(level: l))),
            ]),
            const SizedBox(height: 16),
            _label(ref.t('Tutor', 'Öğretmen')),
            Row(children: [
              for (final p in personas.values)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => n.update((x) => x.copyWith(persona: p.id)),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: profile.persona == p.id ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                      ),
                      child: Column(children: [
                        Mascot(personaId: p.id, mood: profile.persona == p.id ? 'happy' : 'idle', size: 70),
                        Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ]),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 16),
            _label(ref.t('Daily goal', 'Günlük hedef')),
            SegmentedButton<int>(
              segments: const [ButtonSegment(value: 20, label: Text('20')), ButtonSegment(value: 50, label: Text('50')), ButtonSegment(value: 100, label: Text('100 XP'))],
              selected: {profile.dailyGoalXp},
              onSelectionChanged: (s) => n.update((p) => p.copyWith(dailyGoalXp: s.first)),
            ),
            const SizedBox(height: 16),
            _label(ref.t('AI server URL', 'Yapay zekâ sunucu adresi')),
            const _ServerField(),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      TextButton.icon(
        onPressed: () => _confirmReset(context, ref),
        icon: const Icon(Icons.delete_outline),
        label: Text(ref.t('Reset all progress', 'Tüm ilerlemeyi sıfırla')),
      ),
    ]);
  }

  Widget _section(BuildContext context, String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)));
  Widget _metric(String value, String label, Color c) => Column(children: [
        Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: c)),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11.5)),
      ]);

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.t('Reset everything?', 'Her şey sıfırlansın mı?')),
        content: Text(ref.t('Cards, XP, streak, chat and AI memory will be erased from this device.', 'Kartlar, XP, seri, sohbet ve yapay zekâ hafızası bu cihazdan silinecek.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.t('Cancel', 'İptal'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ref.t('Reset', 'Sıfırla'))),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(deckProvider.notifier).reset();
    ref.read(memoryProvider.notifier).clear();
    ref.read(chatProvider.notifier).clear();
    ref.read(profileProvider.notifier).set(const Profile());
  }
}

class _ServerField extends ConsumerStatefulWidget {
  const _ServerField();

  @override
  ConsumerState<_ServerField> createState() => _ServerFieldState();
}

class _ServerFieldState extends ConsumerState<_ServerField> {
  late final _c = TextEditingController(text: ref.read(profileProvider).serverUrl);
  String? status;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _c.text.trim();
    ref.read(profileProvider.notifier).update((p) => p.copyWith(serverUrl: url));
    setState(() => status = '…');
    final ok = await ref.read(apiProvider).health();
    if (mounted) setState(() => status = ok ? ref.t('Connected ✓', 'Bağlandı ✓') : ref.t('Not reachable', 'Ulaşılamıyor'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(controller: _c, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://your-app.up.railway.app', isDense: true), onSubmitted: (_) => _save())),
        const SizedBox(width: 8),
        FilledButton(onPressed: _save, child: Text(ref.t('Save', 'Kaydet'))),
      ]),
      if (status != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(status!)),
    ]);
  }
}
