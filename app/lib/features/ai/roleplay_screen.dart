import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/curriculum.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/mascot.dart';
import '../tutor/tutor_screen.dart';

const _goalTurns = 4;

/// Unit role-play with the AI tutor (Busuu-style speaking practice, but live).
class RoleplayScreen extends ConsumerStatefulWidget {
  const RoleplayScreen({super.key, required this.unitId});
  final String unitId;
  @override
  ConsumerState<RoleplayScreen> createState() => _RoleplayScreenState();
}

class _RoleplayScreenState extends ConsumerState<RoleplayScreen> {
  late final Unit unit = unitsById[widget.unitId]!;
  bool done = false;

  @override
  void initState() {
    super.initState();
    final target = ref.read(profileProvider).targetLang;
    // the tutor opens the scene with the first line of the unit dialogue
    final opener = unit.phrases.isEmpty ? '' : unit.phrases.first.inLang(target);
    Future.microtask(() => ref.read(roleplayProvider.notifier).startScenario(unit.scenario, opener: opener));
  }

  void _complete() {
    final chat = ref.read(roleplayProvider);
    final turns = chat.userTurns;
    final clean = chat.messages.where((m) => !m.fromUser && m.id != 'open' && m.corrections.isEmpty).length;
    ref.read(progressProvider.notifier).complete('${unit.id}_speak', correct: clean.clamp(0, turns), total: turns);
    ref.read(profileProvider.notifier).addXp(15);
    setState(() => done = true);
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(roleplayProvider);
    final p = ref.watch(profileProvider);
    final ui = ref.uiLang;
    final turns = chat.userTurns;
    return Scaffold(
      appBar: AppBar(title: Text('🎭 ${pick(unit.title, ui)}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: done
              ? Confetti(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      PopIn(child: Mascot(personaId: p.persona, mood: 'love', size: 160)),
                      Text(ref.t('Great conversation!', 'Harika bir sohbetti!', 'Tolles Gespräch!'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text('+15 XP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Brand.gold)),
                      const SizedBox(height: 20),
                      SizedBox(width: 240, child: ChunkyButton(label: ref.t('Continue', 'Devam', 'Weiter'), onPressed: () => context.pop())),
                    ]),
                  ),
                )
              : Column(children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Mascot(personaId: p.persona, mood: chat.sending ? 'thinking' : 'talking', size: 44),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('🎯 ${pick(unit.canDo, ui)}', style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: (turns / _goalTurns).clamp(0.0, 1.0), minHeight: 8, borderRadius: BorderRadius.circular(8), color: Brand.green),
                          Text(ref.t('${turns.clamp(0, _goalTurns)}/$_goalTurns replies', '${turns.clamp(0, _goalTurns)}/$_goalTurns cevap', '${turns.clamp(0, _goalTurns)}/$_goalTurns Antworten'),
                              style: const TextStyle(fontSize: 12)),
                        ]),
                      ),
                    ]),
                  ),
                  Expanded(child: ChatView(provider: roleplayProvider)),
                  if (turns >= _goalTurns)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: PopIn(child: ChunkyButton(label: ref.t('Finish conversation', 'Sohbeti bitir', 'Gespräch beenden'), color: Brand.green, onPressed: _complete)),
                    ),
                ]),
        ),
      ),
    );
  }
}
