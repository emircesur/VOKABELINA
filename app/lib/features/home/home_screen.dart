import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/personas.dart';
import '../../services/streak.dart';
import '../../state/providers.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/common.dart';
import 'shell.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final deck = ref.watch(deckProvider);
    final learner = ref.watch(learnerProvider);
    final now = ref.watch(clockProvider)();
    final due = deck.due(now).length;
    final streak = liveStreak(profile, now);
    final todayXp = liveTodayXp(profile, now);
    final goalFrac = (todayXp / profile.dailyGoalXp).clamp(0.0, 1.0);
    final persona = personaOf(profile.persona);
    final name = profile.name.isEmpty ? '' : ', ${profile.name}';

    final (de, native) = _greeting(ref, profile.persona, due, streak, name);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(children: [
          StatChip(icon: '🔥', label: '$streak', color: Brand.red),
          const SizedBox(width: 8),
          StatChip(icon: '⭐', label: '${profile.xp} XP'),
          const SizedBox(width: 8),
          StatChip(icon: '🎓', label: profile.level, color: Brand.teal),
        ]),
        const SizedBox(height: 16),
        MascotSays(text: de, sub: native, mood: due > 0 ? 'idle' : 'happy', size: 110),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(ref.t('Daily goal', 'Günlük hedef'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const Spacer(),
                Text('$todayXp / ${profile.dailyGoalXp} XP', style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 10),
              LinearProgressIndicator(value: goalFrac, minHeight: 14, borderRadius: BorderRadius.circular(10), color: goalFrac >= 1 ? Brand.green : null),
              const SizedBox(height: 14),
              Row(children: [
                Text(ref.t('Level ${profile.level} words known', '${profile.level} seviyesi kelimeler'), style: TextStyle(color: Theme.of(context).hintColor)),
                const Spacer(),
                Text('${(learner.levelProgress(profile.level) * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800)),
              ]),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: learner.levelProgress(profile.level), minHeight: 8, borderRadius: BorderRadius.circular(8), color: Brand.teal),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        ChunkyButton(
          icon: Icons.style,
          label: due > 0 ? ref.t('Review $due cards', '$due kartı tekrar et') : ref.t('Nothing due — practise anyway', 'Bekleyen yok — yine de çalış'),
          onPressed: deck.cards.isEmpty ? null : () => context.push('/review'),
        ),
        const SizedBox(height: 10),
        ChunkyButton(
          icon: Icons.add,
          color: Brand.teal,
          label: ref.t('Learn 5 new words', '5 yeni kelime öğren'),
          onPressed: () => context.push('/learn'),
        ),
        const SizedBox(height: 10),
        ChunkyButton(
          icon: Icons.chat_bubble,
          color: persona.accent,
          label: ref.t('Chat with ${persona.name}', '${persona.name} ile sohbet et'),
          onPressed: () => ref.read(tabProvider.notifier).go(2),
        ),
        const SizedBox(height: 10),
        ChunkyButton(
          icon: Icons.emoji_emotions,
          color: Brand.red,
          label: ref.t("Today's German memes & news", 'Bugünün memleri ve haberleri'),
          onPressed: () => ref.read(tabProvider.notifier).go(3),
        ),
      ],
    );
  }

  (String, String) _greeting(WidgetRef ref, String persona, int due, int streak, String name) {
    final tr = ref.isTr;
    switch (persona) {
      case 'fuchs':
        return due > 0
            ? ('Guten Tag$name. $due Karten warten. Los.', tr ? '$due kart bekliyor. Haydi.' : '$due cards are waiting. Go.')
            : ('Alles erledigt. Das ist selten. Gut.', tr ? 'Her şey tamam. Nadir görülür. İyi.' : 'All done. That is rare. Good.');
      case 'brezel':
        return due > 0
            ? ('Servus$name! $due Karten – das schaffst du vor dem Feierabend!', tr ? '$due kart var – paydostan önce yaparsın!' : '$due cards – you can do it before Feierabend!')
            : ('Nix zu tun! Zeit für ein Meme 🥨', tr ? 'Yapacak bir şey yok! Meme zamanı.' : 'Nothing to do! Meme time.');
      default:
        return due > 0
            ? ('Hallo$name! Heute warten $due Karten auf dich.', tr ? 'Merhaba! Bugün seni $due kart bekliyor.' : 'Hi! $due cards are waiting for you today.')
            : (streak > 0 ? 'Super! Du bist heute fertig. 🍯' : 'Hallo$name! Bereit zum Lernen?', tr ? 'Harika, bugünlük bitti!' : 'Great, you are done for today!');
    }
  }
}
