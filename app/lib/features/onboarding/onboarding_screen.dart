import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';
import '../../data/personas.dart';
import '../../state/providers.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/mascot.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  int step = 0;
  String nativeLang = 'tr';
  String level = 'A1';
  String persona = 'bruno';
  int goal = 50;
  final _name = TextEditingController();

  bool get tr => nativeLang == 'tr';
  String t(String en, String trk) => tr ? trk : en;

  void _finish() {
    ref.read(profileProvider.notifier).set(Profile(
          onboarded: true,
          name: _name.text.trim(),
          nativeLang: nativeLang,
          level: level,
          persona: persona,
          dailyGoalXp: goal,
          serverUrl: ref.read(profileProvider).serverUrl,
        ));
    final deck = ref.read(deckProvider.notifier);
    if (ref.read(deckProvider).cards.isEmpty) deck.add(deck.newWordsFor(level, 8));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_welcome(), _language(), _levelPage(), _personaPage(), _goalPage()];
    final last = step == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                LinearProgressIndicator(value: (step + 1) / pages.length, minHeight: 10, borderRadius: BorderRadius.circular(8)),
                Expanded(child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: SingleChildScrollView(key: ValueKey(step), child: pages[step]))),
                Row(children: [
                  if (step > 0) TextButton(onPressed: () => setState(() => step--), child: Text(t('Back', 'Geri'))),
                  const Spacer(),
                  SizedBox(width: 200, child: ChunkyButton(turkishCase: tr, label: last ? t("Let's go!", 'Başlayalım!') : t('Continue', 'Devam'), onPressed: last ? _finish : () => setState(() => step++))),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text, [String? sub]) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 16),
        child: Column(children: [
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          if (sub != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(sub, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).hintColor))),
        ]),
      );

  Widget _welcome() => Column(children: [
        const SizedBox(height: 24),
        Mascot(personaId: persona, mood: 'cheer', size: 190),
        _title('Vokabelina', t('Learn German with AI mascots, memes and real news.', 'Yapay zekâ maskotları, memler ve gerçek haberlerle Almanca öğren.')),
        TextField(controller: _name, decoration: InputDecoration(hintText: t('What should we call you?', 'Sana ne diyelim?')), textCapitalization: TextCapitalization.words),
      ]);

  Widget _language() => Column(children: [
        _title(t('I speak…', 'Ana dilim…'), t('Explanations and translations will be in this language.', 'Açıklamalar ve çeviriler bu dilde olacak.')),
        _choice('🇹🇷  Türkçe', nativeLang == 'tr', () => setState(() => nativeLang = 'tr')),
        _choice('🇬🇧  English', nativeLang == 'en', () => setState(() => nativeLang = 'en')),
      ]);

  Widget _levelPage() => Column(children: [
        _title(t('Your German level?', 'Almanca seviyen?'), t('The AI adapts to it — and keeps adjusting as you learn.', 'Yapay zekâ buna uyum sağlar ve öğrendikçe ayarlanır.')),
        _choice(t('🌱  Brand new (A1)', '🌱  Hiç bilmiyorum (A1)'), level == 'A1', () => setState(() => level = 'A1')),
        _choice(t('🌿  Basics (A2)', '🌿  Temel (A2)'), level == 'A2', () => setState(() => level = 'A2')),
        _choice(t('🌳  Conversations (B1)', '🌳  Sohbet edebiliyorum (B1)'), level == 'B1', () => setState(() => level = 'B1')),
        _choice(t('🏔️  Fluent-ish (B2+)', '🏔️  İleri (B2+)'), level == 'B2', () => setState(() => level = 'B2')),
      ]);

  Widget _personaPage() => Column(children: [
        _title(t('Pick your tutor', 'Öğretmenini seç'), t('You can switch any time.', 'İstediğin zaman değiştirebilirsin.')),
        for (final p in personas.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _choice(
              '${p.name}  ·  ${p.species}',
              persona == p.id,
              () => setState(() => persona = p.id),
              sub: p.tagline(nativeLang),
              leading: Mascot(personaId: p.id, mood: persona == p.id ? 'happy' : 'idle', size: 64),
              pad: false,
            ),
          ),
      ]);

  Widget _goalPage() => Column(children: [
        _title(t('Daily goal', 'Günlük hedef')),
        _choice(t('☕  Casual — 20 XP', '☕  Rahat — 20 XP'), goal == 20, () => setState(() => goal = 20)),
        _choice(t('🚶  Regular — 50 XP', '🚶  Düzenli — 50 XP'), goal == 50, () => setState(() => goal = 50)),
        _choice(t('🏃  Serious — 100 XP', '🏃  Ciddi — 100 XP'), goal == 100, () => setState(() => goal = 100)),
      ]);

  Widget _choice(String label, bool selected, VoidCallback onTap, {String? sub, Widget? leading, bool pad = true}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: pad ? 10 : 0),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? cs.primary.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: 2),
            ),
            child: Row(children: [
              if (leading != null) ...[leading, const SizedBox(width: 12)],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  if (sub != null) Text(sub, style: TextStyle(color: Theme.of(context).hintColor)),
                ]),
              ),
              if (selected) Icon(Icons.check_circle, color: cs.primary),
            ]),
          ),
        ),
      ),
    );
  }
}
