import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/personas.dart';
import '../../services/achievements.dart';
import '../../services/api.dart';
import '../../services/streak.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/mascot.dart';
import '../course/course_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final now = ref.watch(clockProvider)();
    final deck = ref.watch(deckProvider);
    final badges = achievements(profile: p, cards: deck.forLang(p.targetLang), progress: ref.watch(progressProvider), memory: ref.watch(memoryProvider));

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), children: [
      Row(children: [
        PopIn(child: Mascot(personaId: p.persona, mood: 'wave', size: 84)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name.isEmpty ? 'Vokabelina' : p.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text('${langFlags[p.targetLang]} ${p.level} · ${p.xp} XP · 🔥 ${liveStreak(p, now)} (${ref.t('best', 'en iyi', 'Rekord')} ${p.bestStreak})', style: TextStyle(color: Theme.of(context).hintColor)),
          ]),
        ),
      ]),
      const SizedBox(height: 20),
      const _MemoryHub(),
      const SizedBox(height: 24),
      _section('🏅 ${ref.t('Badges', 'Rozetler', 'Abzeichen')}'),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final (i, b) in badges.indexed)
          SlideFadeIn(
            index: i,
            child: Tooltip(
              message: tr3(ref.uiLang, b.title.$1, b.title.$2, b.title.$3),
              child: SizedBox(
                width: 76,
                child: Column(children: [
                  ProgressRing(
                    value: b.progress,
                    size: 60,
                    stroke: 5,
                    color: b.unlocked ? Brand.green : Brand.gold,
                    child: Opacity(opacity: b.unlocked ? 1 : 0.35, child: Text(b.emoji, style: const TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(height: 4),
                  Text(tr3(ref.uiLang, b.title.$1, b.title.$2, b.title.$3), maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5)),
                ]),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 24),
      const _Settings(),
    ]);
  }
}

Widget _section(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)));
Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 6, top: 12), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)));

const _factIcons = {'personal': '🙂', 'work': '💼', 'family': '👨‍👩‍👧', 'hobby': '🎨', 'goal': '🎯', 'place': '📍', 'other': '📝'};

class _MemoryHub extends ConsumerStatefulWidget {
  const _MemoryHub();
  @override
  ConsumerState<_MemoryHub> createState() => _MemoryHubState();
}

class _MemoryHubState extends ConsumerState<_MemoryHub> {
  bool syncing = false;

  Future<void> _sync() async {
    setState(() => syncing = true);
    final ok = await ref.read(memoryProvider.notifier).sync();
    if (!mounted) return;
    setState(() => syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? ref.t('Memory synced ✓', 'Hafıza senkronlandı ✓', 'Gedächtnis synchronisiert ✓') : ref.t('Sync not possible (offline or disabled).', 'Senkron mümkün değil (çevrimdışı ya da kapalı).', 'Sync nicht möglich (offline oder deaktiviert).'))));
  }

  Future<void> _addInterest() async {
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.t('Add an interest', 'İlgi alanı ekle', 'Interesse hinzufügen')),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: ref.t('e.g. football, cooking, history', 'ör. futbol, yemek, tarih', 'z. B. Fußball, Kochen, Geschichte'))),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('OK'))],
      ),
    );
    c.dispose();
    if (v != null && v.isNotEmpty) {
      final m = ref.read(memoryProvider);
      ref.read(memoryProvider.notifier).setInterests([...m.interests, v]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider);
    final m = ref.watch(memoryProvider);
    final learner = ref.watch(learnerProvider);
    final now = ref.watch(clockProvider)();
    final persona = personaOf(p.persona);
    final mistakes = m.topMistakes(p.targetLang, now, 8);
    final weak = learner.pickWeak(8);
    final hint = TextStyle(color: Theme.of(context).hintColor);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: _section('🧠 ${ref.t('${persona.name}\'s memory of you', '${persona.name} seni böyle hatırlıyor', 'Was ${persona.name} über dich weiß')}')),
        if (p.cloudMemory)
          IconButton(
            tooltip: ref.t('Sync now', 'Şimdi senkronla', 'Jetzt synchronisieren'),
            onPressed: syncing ? null : _sync,
            icon: syncing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
          ),
      ]),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              ref.t('The tutor uses this to talk at your level and remember your life. Everything is editable.', 'Öğretmen bunları seviyene göre konuşmak ve hayatını hatırlamak için kullanır. Her şey düzenlenebilir.',
                  'Der Tutor nutzt das, um auf deinem Niveau zu sprechen und sich an dich zu erinnern. Alles ist bearbeitbar.'),
              style: hint.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _metric('${learner.known.length}', ref.t('words known', 'bilinen kelime', 'Wörter gelernt'), Brand.green)),
              Expanded(child: _metric('${learner.cards.length}', ref.t('cards', 'kart', 'Karten'), Brand.teal)),
              Expanded(child: _metric('${mistakes.length}', ref.t('mistake patterns', 'hata kalıbı', 'Fehlermuster'), Brand.red)),
              Expanded(child: _metric('${m.episodes.length}', ref.t('conversations', 'sohbet', 'Gespräche'), const Color(0xFF7B4FB8))),
            ]),
            if (m.summary.isNotEmpty) ...[
              _label('📝 ${ref.t('Profile summary (AI)', 'Profil özeti (AI)', 'Profil-Zusammenfassung (KI)')}'),
              Text(m.summary, style: const TextStyle(height: 1.4)),
            ],
            if (m.estimatedLevel.isNotEmpty && m.estimatedLevel != p.level) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Brand.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Expanded(
                    child: Text(ref.t('Your writing looks like ${m.estimatedLevel}. Switch level?', 'Yazdıkların ${m.estimatedLevel} seviyesinde görünüyor. Seviye değişsin mi?',
                        'Dein Schreiben wirkt wie ${m.estimatedLevel}. Niveau wechseln?')),
                  ),
                  TextButton(onPressed: () => ref.read(profileProvider.notifier).update((x) => x.copyWith(level: m.estimatedLevel)), child: Text(m.estimatedLevel)),
                ]),
              ),
            ],
            if (m.focus.isNotEmpty) ...[
              _label('🎯 ${ref.t('Next focus', 'Sıradaki odak', 'Nächster Fokus')}'),
              for (final f in m.focus) Text('• $f'),
            ],
            _label('🔁 ${ref.t('Practising now (weakest words)', 'Şu an çalışılan (en zayıf kelimeler)', 'Wird gerade geübt (schwächste Wörter)')}'),
            weak.isEmpty
                ? Text(ref.t('Do lessons and chat to build this list.', 'Ders yap ve sohbet et, liste oluşsun.', 'Mach Lektionen und chatte, um die Liste aufzubauen.'), style: hint)
                : Wrap(spacing: 6, runSpacing: 6, children: [for (final w in weak) Chip(avatar: Text(w.emoji), label: Text(w.inLang(p.targetLang)), visualDensity: VisualDensity.compact)]),
            _label('🩹 ${ref.t('Recurring mistakes (fade as you improve)', 'Tekrarlayan hatalar (geliştikçe solar)', 'Wiederkehrende Fehler (verblassen mit der Zeit)')}'),
            if (mistakes.isEmpty)
              Text(ref.t('None yet — nice!', 'Henüz yok — harika!', 'Noch keine – super!'), style: hint)
            else
              for (final mp in mistakes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(
                      width: 46,
                      child: Column(children: [
                        Text('×${mp.count}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        LinearProgressIndicator(value: (mp.weight(now) / mp.count).clamp(0.0, 1.0), minHeight: 4, color: Brand.red, borderRadius: BorderRadius.circular(4)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(mp.tag, style: const TextStyle(fontWeight: FontWeight.w800)),
                        if (mp.explanation.isNotEmpty && mp.explanation != mp.tag) Text(mp.explanation, style: const TextStyle(fontSize: 13)),
                        for (final ex in mp.examples.take(2)) Text(ex, style: hint.copyWith(fontSize: 12.5)),
                      ]),
                    ),
                    IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close, size: 18), onPressed: () => ref.read(memoryProvider.notifier).removeMistake(mp.key)),
                  ]),
                ),
            _label('💛 ${ref.t('Interests', 'İlgi alanları', 'Interessen')}'),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final i in m.interests)
                InputChip(label: Text(i), visualDensity: VisualDensity.compact, onDeleted: () => ref.read(memoryProvider.notifier).setInterests(m.interests.where((x) => x != i).toList())),
              ActionChip(avatar: const Icon(Icons.add, size: 16), label: Text(ref.t('Add', 'Ekle', 'Hinzufügen')), onPressed: _addInterest, visualDensity: VisualDensity.compact),
            ]),
            if (m.goals.isNotEmpty) ...[
              _label('🏁 ${ref.t('Your goals', 'Hedeflerin', 'Deine Ziele')}'),
              for (final g in m.goals) Text('• $g'),
            ],
            _label('📌 ${ref.t('Things I know about you', 'Senin hakkında bildiklerim', 'Was ich über dich weiß')}'),
            if (m.facts.isEmpty)
              Text(ref.t('Tell your tutor about yourself — job, hobbies, city.', 'Öğretmenine kendinden bahset — iş, hobiler, şehir.', 'Erzähl dem Tutor von dir – Beruf, Hobbys, Stadt.'), style: hint)
            else
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final f in m.facts)
                  InputChip(
                    avatar: Text(_factIcons[f.category] ?? '📝'),
                    label: Text(f.text),
                    onDeleted: () => ref.read(memoryProvider.notifier).removeFact(f.text),
                    visualDensity: VisualDensity.compact,
                  ),
              ]),
            if (m.episodes.isNotEmpty) ...[
              _label('🗓️ ${ref.t('Past conversations', 'Geçmiş sohbetler', 'Frühere Gespräche')}'),
              for (final e in m.episodes.take(5))
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text('${e.date.day}.${e.date.month}.', style: const TextStyle(fontWeight: FontWeight.w800)),
                  title: Text(e.summary),
                  subtitle: e.topics.isEmpty ? null : Text(e.topics.join(' · ')),
                ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => ref.read(memoryProvider.notifier).clear(), child: Text(ref.t('Forget everything', 'Hepsini unut', 'Alles vergessen'))),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _metric(String value, String label, Color c) => Column(children: [
        CountUp(value: int.tryParse(value) ?? 0, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: c)),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
      ]);
}

class _Settings extends ConsumerWidget {
  const _Settings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final n = ref.read(profileProvider.notifier);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _section('⚙️ ${ref.t('Settings', 'Ayarlar', 'Einstellungen')}'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label(ref.t('My language (app language)', 'Ana dilim (uygulama dili)', 'Meine Sprache (App-Sprache)')),
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'tr', label: Text('Türkçe')), ButtonSegment(value: 'en', label: Text('English')), ButtonSegment(value: 'de', label: Text('Deutsch'))],
              selected: {p.nativeLang},
              onSelectionChanged: (s) => n.setNative(s.first),
            ),
            _label(ref.t('I am learning', 'Öğrendiğim dil', 'Ich lerne')),
            ActionChip(
              avatar: Text(langFlags[p.targetLang]!),
              label: Text(langNames[p.targetLang]![ref.uiLang] ?? ''),
              onPressed: () => showTargetPicker(context, ref),
            ),
            _label(ref.t('Level', 'Seviye', 'Niveau')),
            Wrap(spacing: 8, children: [for (final l in levels) ChoiceChip(label: Text(l), selected: p.level == l, onSelected: (_) => n.update((x) => x.copyWith(level: l)))]),
            _label(ref.t('Tutor', 'Öğretmen', 'Tutor')),
            Row(children: [
              for (final per in personas.values)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => n.update((x) => x.copyWith(persona: per.id)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.persona == per.id ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                      ),
                      child: Column(children: [
                        Mascot(personaId: per.id, mood: p.persona == per.id ? 'happy' : 'idle', size: 70),
                        Text(per.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      ]),
                    ),
                  ),
                ),
            ]),
            _label(ref.t('Daily goal', 'Günlük hedef', 'Tagesziel')),
            SegmentedButton<int>(
              segments: const [ButtonSegment(value: 20, label: Text('20')), ButtonSegment(value: 50, label: Text('50')), ButtonSegment(value: 100, label: Text('100 XP'))],
              selected: {p.dailyGoalXp},
              onSelectionChanged: (s) => n.update((x) => x.copyWith(dailyGoalXp: s.first)),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: p.cloudMemory,
              onChanged: (v) => n.update((x) => x.copyWith(cloudMemory: v)),
              title: Text(ref.t('Cloud memory', 'Bulut hafıza', 'Cloud-Gedächtnis'), style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(ref.t('The server summarises your conversations so the tutor remembers you across sessions. Stored under an anonymous device id.',
                  'Sunucu, öğretmenin seni oturumlar arasında hatırlaması için sohbetlerini özetler. Anonim bir cihaz kimliğiyle saklanır.',
                  'Der Server fasst deine Gespräche zusammen, damit der Tutor sich an dich erinnert. Gespeichert unter einer anonymen Geräte-ID.')),
            ),
            _label(ref.t('AI server URL', 'Yapay zekâ sunucu adresi', 'KI-Server-URL')),
            const _ServerField(),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        TextButton.icon(onPressed: () => _deleteServer(context, ref), icon: const Icon(Icons.cloud_off), label: Text(ref.t('Delete my data on the server', 'Sunucudaki verimi sil', 'Meine Daten auf dem Server löschen'))),
        TextButton.icon(onPressed: () => _confirmReset(context, ref), icon: const Icon(Icons.delete_outline), label: Text(ref.t('Reset all progress', 'Tüm ilerlemeyi sıfırla', 'Fortschritt zurücksetzen'))),
      ]),
    ]);
  }

  Future<void> _deleteServer(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(apiProvider).deleteServerData();
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.t('Server data deleted.', 'Sunucudaki veriler silindi.', 'Serverdaten gelöscht.'))));
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.t('Reset everything?', 'Her şey sıfırlansın mı?', 'Alles zurücksetzen?')),
        content: Text(ref.t('Cards, lessons, XP, streak, chat and AI memory will be erased from this device.', 'Kartlar, dersler, XP, seri, sohbet ve yapay zekâ hafızası bu cihazdan silinecek.',
            'Karten, Lektionen, XP, Serie, Chat und KI-Gedächtnis werden von diesem Gerät gelöscht.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.t('Cancel', 'İptal', 'Abbrechen'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ref.t('Reset', 'Sıfırla', 'Zurücksetzen'))),
        ],
      ),
    );
    if (ok != true) return;
    ref.read(deckProvider.notifier).reset();
    ref.read(memoryProvider.notifier).clear();
    ref.read(progressProvider.notifier).reset();
    ref.read(chatProvider.notifier).clear();
    ref.read(profileProvider.notifier).set(Profile(serverUrl: ref.read(profileProvider).serverUrl));
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
    ref.read(profileProvider.notifier).update((p) => p.copyWith(serverUrl: _c.text.trim()));
    setState(() => status = '…');
    final ok = await ref.read(apiProvider).health();
    if (mounted) setState(() => status = ok ? ref.t('Connected ✓', 'Bağlandı ✓', 'Verbunden ✓') : ref.t('Not reachable', 'Ulaşılamıyor', 'Nicht erreichbar'));
    if (ok) ref.read(memoryProvider.notifier).sync();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: TextField(controller: _c, keyboardType: TextInputType.url, decoration: const InputDecoration(hintText: 'https://your-app.up.railway.app', isDense: true), onSubmitted: (_) => _save())),
        const SizedBox(width: 8),
        FilledButton(onPressed: _save, child: Text(ref.t('Save', 'Kaydet', 'Speichern'))),
      ]),
      if (status != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(status!)),
    ]);
  }
}
