import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/curriculum.dart';
import '../../data/grammar.dart';
import '../../services/lessons.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/mascot.dart';
import '../lesson/lesson_screen.dart';
import '../words/word_sheet.dart';
import 'course_screen.dart';

/// One unit: goal, culture note, a winding lesson path and the unit's picture cards.
class UnitScreen extends ConsumerWidget {
  const UnitScreen({super.key, required this.unitId});
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = unitsById[unitId]!;
    final p = ref.watch(profileProvider);
    final course = ref.watch(courseProvider);
    final ui = ref.uiLang;
    final ls = lessonsFor(unit);
    final g = grammarFor(p.targetLang, unit.id);
    final culture = unit.culture[ui] ?? unit.culture['en'];
    final current = ls.where((l) => !course.done(l) && course.lessonUnlocked(unit, l)).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text('${unit.emoji}  ${pick(unit.title, ui)}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Brand.teal, borderRadius: BorderRadius.circular(8)),
                      child: Text(unit.level, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    Text('${ref.t('Unit', 'Ünite', 'Einheit')} ${unit.number}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: Color(0xFFF2C14E)),
                    Text('${course.unitStars(unit)}/${ls.length * 3}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                  const SizedBox(height: 10),
                  Text('🎯 ${pick(unit.canDo, ui)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  if (g != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('📐 ${g.titleIn(ui)}', style: TextStyle(color: Theme.of(context).hintColor))),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            for (final (i, l) in ls.indexed)
              _PathNode(
                lesson: l,
                index: i,
                done: course.done(l),
                stars: course.result(l)?.stars ?? 0,
                unlocked: course.lessonUnlocked(unit, l),
                current: identical(l, current) || l.id == current?.id,
                persona: p.persona,
              ),
            if (culture != null && ui != 'de') ...[
              const SizedBox(height: 18),
              Card(
                color: Brand.gold.withValues(alpha: 0.12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('🇩🇪 ${ref.t('Life in Germany', 'Almanya’da yaşam', 'Leben in Deutschland')}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(culture, style: const TextStyle(height: 1.4)),
                  ]),
                ),
              ),
            ],
            const SizedBox(height: 22),
            Text('🖼️ ${ref.t('Picture cards', 'Resimli kartlar', 'Bildkarten')} (${unit.words.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            UnitWordGrid(unit: unit, onOpen: (w) => showWordSheet(context, w)),
          ]),
        ),
      ),
    );
  }
}

class _PathNode extends ConsumerWidget {
  const _PathNode({required this.lesson, required this.index, required this.done, required this.stars, required this.unlocked, required this.current, required this.persona});
  final LessonSpec lesson;
  final int index;
  final bool done, unlocked, current;
  final int stars;
  final String persona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    // winding path: offset nodes on a sine curve
    final dx = math.sin(index * 1.1) * 70;
    final color = !unlocked ? Colors.grey : (done ? Brand.green : (lesson.isAi ? const Color(0xFF7B4FB8) : cs.primary));
    final node = Material(
      color: color,
      shape: const CircleBorder(),
      elevation: unlocked ? 3 : 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: unlocked
            ? () => openLesson(context, lesson)
            : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ref.t('Finish the lessons before this one.', 'Önce bundan önceki dersleri bitir.', 'Schließe zuerst die vorigen Lektionen ab.')))),
        child: SizedBox(width: 74, height: 74, child: Icon(unlocked ? lessonIcon(lesson.kind) : Icons.lock, color: Colors.white, size: 34)),
      ),
    );
    return SlideFadeIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Transform.translate(
          offset: Offset(dx, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (current && dx > 0) Mascot(personaId: persona, mood: 'wave', size: 64),
            Column(children: [
              current ? Pulse(scale: 0.08, child: node) : node,
              const SizedBox(height: 4),
              Text(lessonTitle(ref, lesson), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              if (lesson.isAi) Text('✨ AI', style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
              if (done)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var s = 0; s < 3; s++) Icon(Icons.star_rounded, size: 16, color: s < stars ? const Color(0xFFF2C14E) : Colors.grey.withValues(alpha: 0.35)),
                ]),
            ]),
            if (current && dx <= 0) Mascot(personaId: persona, mood: 'wave', size: 64),
          ]),
        ),
      ),
    );
  }
}
