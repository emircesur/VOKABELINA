import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/curriculum.dart';
import '../../data/models.dart';
import '../../data/personas.dart';
import '../../services/lessons.dart';
import '../../services/streak.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/juice.dart';
import '../../widgets/mascot.dart';
import 'daily_cards.dart';

String lessonTitle(WidgetRef ref, LessonSpec l) => switch (l.kind) {
  LessonKind.words => '${ref.t('Words', 'Kelimeler', 'Wörter')} ${l.part}',
  LessonKind.dialogue => ref.t('Dialogue', 'Diyalog', 'Dialog'),
  LessonKind.grammar => ref.t('Grammar', 'Gramer', 'Grammatik'),
  LessonKind.review => ref.t('Unit review', 'Ünite tekrarı', 'Wiederholung'),
  LessonKind.speak => ref.t('AI conversation', 'AI sohbeti', 'KI-Gespräch'),
  LessonKind.write => ref.t('AI writing', 'AI yazma', 'KI-Schreiben'),
};

IconData lessonIcon(LessonKind k) => switch (k) {
  LessonKind.words => Icons.style_rounded,
  LessonKind.dialogue => Icons.forum_rounded,
  LessonKind.grammar => Icons.architecture_rounded,
  LessonKind.review => Icons.emoji_events_rounded,
  LessonKind.speak => Icons.record_voice_over_rounded,
  LessonKind.write => Icons.edit_note_rounded,
};

/// Opens a lesson: AI lessons have their own screens.
void openLesson(BuildContext context, LessonSpec l) => switch (l.kind) {
  LessonKind.speak => context.push('/roleplay/${l.unitId}'),
  LessonKind.write => context.push('/write/${l.unitId}'),
  _ => context.push('/lesson/${l.id}'),
};

Future<void> showTargetPicker(BuildContext context, WidgetRef ref) => showModalBottomSheet(
  context: context,
  showDragHandle: true,
  builder: (ctx) {
    final p = ref.read(profileProvider);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(ref.t('I want to learn…', 'Öğrenmek istiyorum…', 'Ich möchte lernen…'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final l in targetLangs)
            ListTile(
              enabled: l != p.nativeLang,
              leading: Text(langFlags[l]!, style: const TextStyle(fontSize: 28)),
              // each language in its own words, with the name in the app language below
              title: Text(langNames[l]![l]!, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(l == p.nativeLang ? ref.t('your language', 'ana dilin', 'deine Sprache') : langNames[l]![ref.uiLang]!),
              trailing: l == p.targetLang ? const Icon(Icons.check_circle, color: Brand.green) : null,
              onTap: () {
                ref.read(profileProvider.notifier).setTarget(l);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  },
);

class CourseScreen extends ConsumerWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final course = ref.watch(courseProvider);
    final deck = ref.watch(deckProvider);
    final now = ref.watch(clockProvider)();
    final due = deck.due(now, p.targetLang).length;
    final todayXp = liveTodayXp(p, now);
    final next = course.next();
    final ui = ref.uiLang;
    final byLevel = <String, List<Unit>>{};
    for (final u in units) {
      (byLevel[u.level] ??= []).add(u);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                ActionChip(
                  avatar: Text(langFlags[p.targetLang]!, style: const TextStyle(fontSize: 18)),
                  label: Text(langNames[p.targetLang]![ui] ?? '', style: const TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: () => showTargetPicker(context, ref),
                ),
                const Spacer(),
                Semantics(
                  label: ref.t('${liveStreak(p, now)} day streak', '${liveStreak(p, now)} günlük seri', '${liveStreak(p, now)} Tage in Folge'),
                  child: ExcludeSemantics(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Brand.red.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(99)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        FlameIcon(size: 18, lit: liveStreak(p, now) > 0),
                        const SizedBox(width: 4),
                        Text('${liveStreak(p, now)}', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ProgressRing(
                  value: todayXp / p.dailyGoalXp,
                  size: 40,
                  stroke: 5,
                  color: todayXp >= p.dailyGoalXp ? Brand.green : Brand.gold,
                  child: todayXp >= p.dailyGoalXp
                      ? const PopIn(child: Icon(Icons.check_rounded, color: Brand.green, size: 20))
                      : Text('$todayXp', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(child: _ContinueCard(next: next)),
        const SliverToBoxAdapter(child: DailyQuestsCard()),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 132,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _QuickAction(
                  emoji: '🧠',
                  title: ref.t('Smart practice', 'Akıllı tekrar', 'Smart-Training'),
                  sub: ref.t('AI · weak words', 'AI · zayıf kelimeler', 'KI · schwache Wörter'),
                  onTap: () => context.push('/practice'),
                ),
                _QuickAction(
                  emoji: '🃏',
                  title: ref.t('Review', 'Tekrar', 'Wiederholen'),
                  sub: ref.t('$due due', '$due bekliyor', '$due fällig'),
                  onTap: () => context.push('/review'),
                ),
                _QuickAction(
                  emoji: '📖',
                  title: ref.t('AI story', 'AI hikâye', 'KI-Geschichte'),
                  sub: ref.t('with your words', 'kelimelerinle', 'mit deinen Wörtern'),
                  onTap: () => context.push('/story'),
                ),
                _QuickAction(
                  emoji: '✍️',
                  title: ref.t('Free writing', 'Serbest yazma', 'Freies Schreiben'),
                  sub: ref.t('AI corrects', 'AI düzeltir', 'KI korrigiert'),
                  onTap: () => context.push('/write/free'),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: WordOfDayCard()),
        for (final entry in byLevel.entries) ...[
          SliverToBoxAdapter(
            child: _LevelHeader(level: entry.key, units: entry.value),
          ),
          SliverList.builder(
            itemCount: entry.value.length,
            itemBuilder: (_, i) => SlideFadeIn(
              index: i,
              child: _UnitCard(unit: entry.value[i]),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({required this.next});
  final (Unit, LessonSpec)? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider);
    final persona = personaOf(p.persona);
    final n = next;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [persona.accent.withValues(alpha: 0.9), persona.body.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Mascot(personaId: p.persona, mood: n == null ? 'love' : 'wave', size: 96),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n == null)
                    Text(
                      ref.t('Course complete! 🎉', 'Kurs tamamlandı! 🎉', 'Kurs geschafft! 🎉'),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    )
                  else ...[
                    Text(
                      '${ref.t('Unit', 'Ünite', 'Einheit')} ${n.$1.number} · ${pick(n.$1.title, ref.uiLang)}',
                      style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      lessonTitle(ref, n.$2),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Pulse(
                      child: ChunkyButton(
                        compact: true,
                        color: Colors.white,
                        foreground: persona.accent,
                        label: ref.t('Start', 'Başla', 'Los'),
                        onPressed: () => openLesson(context, n.$2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.emoji, required this.title, required this.sub, required this.onTap});
  final String emoji, title, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 10, bottom: 8),
    child: SizedBox(
      width: 140,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  sub,
                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _LevelHeader extends ConsumerWidget {
  const _LevelHeader({required this.level, required this.units});
  final String level;
  final List<Unit> units;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final done = units.where(course.unitDone).length;
    final name = switch (level) {
      'A1' => ref.t('Beginner', 'Başlangıç', 'Anfänger'),
      'A2' => ref.t('Elementary', 'Temel', 'Grundstufe'),
      _ => ref.t('Intermediate', 'Orta', 'Mittelstufe'),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Brand.teal, borderRadius: BorderRadius.circular(10)),
            child: Text(
              level,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const Spacer(),
          Text('$done/${units.length}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _UnitCard extends ConsumerWidget {
  const _UnitCard({required this.unit});
  final Unit unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final course = ref.watch(courseProvider);
    final open = course.unitUnlocked(unit);
    final done = course.unitDone(unit);
    final ls = lessonsFor(unit);
    final doneCount = ls.where(course.done).length;
    final ui = ref.uiLang;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Opacity(
        opacity: open ? 1 : 0.55,
        child: Card(
          child: Semantics(
            button: true,
            label: open ? null : ref.t('locked', 'kilitli', 'gesperrt'),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => open
                  ? context.push('/unit/${unit.id}')
                  : ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ref.t(
                            'Finish the previous unit first — or raise your level in Me → Settings.',
                            'Önce önceki üniteyi bitir — ya da Ben → Ayarlar’dan seviyeni yükselt.',
                            'Schließe zuerst die vorige Einheit ab – oder erhöhe dein Niveau unter Ich → Einstellungen.',
                          ),
                        ),
                      ),
                    ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: (done ? Brand.green : cs.primary).withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Text(unit.emoji, style: const TextStyle(fontSize: 28)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ref.t('Unit', 'Ünite', 'Einheit')} ${unit.number}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
                          ),
                          Text(pick(unit.title, ui), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(
                            pick(unit.canDo, ui),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12.5, color: Theme.of(context).hintColor),
                          ),
                          const SizedBox(height: 6),
                          ExcludeSemantics(
                            child: LinearProgressIndicator(
                              value: doneCount / ls.length,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(6),
                              color: done ? Brand.green : Brand.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    open ? (done ? const Icon(Icons.verified, color: Brand.green) : const Icon(Icons.chevron_right)) : const Icon(Icons.lock),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
