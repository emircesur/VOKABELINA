import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../services/quests.dart';
import '../../services/streak.dart';
import '../../services/tts.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/juice.dart';
import '../../widgets/picture_card.dart';
import '../words/word_sheet.dart';

/// Three small goals a day; finished ones are claimed for bonus XP with a burst of confetti.
class DailyQuestsCard extends ConsumerStatefulWidget {
  const DailyQuestsCard({super.key});
  @override
  ConsumerState<DailyQuestsCard> createState() => _DailyQuestsCardState();
}

class _DailyQuestsCardState extends ConsumerState<DailyQuestsCard> {
  int bursts = 0;

  @override
  Widget build(BuildContext context) {
    final daily = ref.watch(dailyProvider);
    final p = ref.watch(profileProvider);
    final now = ref.watch(clockProvider)();
    final quests = questsFor(dayKey(now), p.dailyGoalXp);
    final notifier = ref.read(dailyProvider.notifier);
    final claimed = daily.day == dayKey(now) ? daily.claimed : const <String>{};
    final done = quests.where((q) => claimed.contains(q.id)).length;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Stack(children: [
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('🎯', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(child: Text(ref.t('Daily quests', 'Günlük görevler', 'Tagesquests'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                Text('$done/${quests.length}', style: TextStyle(fontWeight: FontWeight.w900, color: done == quests.length ? Brand.green : cs.outline)),
              ]),
              const SizedBox(height: 6),
              for (final q in quests) _row(q, notifier.progress(q), claimed.contains(q.id), notifier),
            ]),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: Confetti(key: ValueKey(bursts), play: bursts > 0, child: const SizedBox.expand()))),
      ]),
    );
  }

  Widget _row(Quest q, int value, bool claimed, DailyNotifier notifier) {
    final ready = value >= q.target && !claimed;
    final color = claimed ? Brand.green : Brand.gold;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Text(q.emoji, style: const TextStyle(fontSize: 19)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(q.title(ref.uiLang), style: TextStyle(fontWeight: FontWeight.w800, decoration: claimed ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 5),
            Semantics(
              label: '$value / ${q.target}',
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: value / q.target),
                duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 9, borderRadius: BorderRadius.circular(6), color: color, backgroundColor: color.withValues(alpha: 0.15)),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 64,
          child: Center(
            child: claimed
                ? PopIn(child: const Icon(Icons.check_circle_rounded, color: Brand.green, size: 28))
                : ready
                    ? Pulse(
                        child: BounceTap(
                          onTap: () {
                            if (notifier.claim(q)) {
                              HapticFeedback.mediumImpact();
                              setState(() => bursts++);
                            }
                          },
                          child: Semantics(
                            button: true,
                            label: ref.t('Claim ${q.reward} XP', '${q.reward} XP al', '${q.reward} XP holen'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Brand.gold, Brand.red]),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Brand.gold.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 3))],
                              ),
                              child: Text('🎁 +${q.reward}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5)),
                            ),
                          ),
                        ),
                      )
                    : Text('$value/${q.target}', style: TextStyle(fontWeight: FontWeight.w800, color: Theme.of(context).hintColor)),
          ),
        ),
      ]),
    );
  }
}

/// One picture word a day at the learner's level; tap for the full card and AI coach.
class WordOfDayCard extends ConsumerWidget {
  const WordOfDayCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final now = ref.watch(clockProvider)();
    final w = wordOfTheDay(dayKey(now), p.level);
    final known = ref.watch(deckProvider).has(p.targetLang, w.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => showWordSheet(context, w),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Wiggle(angle: 0.05, period: const Duration(milliseconds: 2400), child: PictureTile(word: w, size: 76, showGender: p.targetLang == 'de')),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '✨ ${ref.t('Word of the day', 'Günün kelimesi', 'Wort des Tages')}${known ? ' · ${ref.t('in your cards', 'kartlarında', 'in deinen Karten')}' : ''}',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 2),
                  TargetWordText(word: w, lang: p.targetLang),
                  Text(w.gloss(p.nativeLang), style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              ),
              IconButton(
                tooltip: ref.t('Listen', 'Dinle', 'Anhören'),
                icon: const Icon(Icons.volume_up_rounded),
                onPressed: () => speak(w.inLang(p.targetLang), p.targetLang),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
