import '../data/curriculum.dart';
import '../data/models.dart';

class Achievement {
  const Achievement({required this.id, required this.emoji, required this.title, required this.progress});
  final String id;
  final String emoji;

  /// (en, tr, de)
  final (String, String, String) title;

  /// 0..1 (1 = unlocked)
  final double progress;
  bool get unlocked => progress >= 1;
}

double _ratio(num v, num goal) => (v / goal).clamp(0.0, 1.0).toDouble();

/// Badges derived from existing state (no extra storage needed).
List<Achievement> achievements({
  required Profile profile,
  required Map<String, CardState> cards,
  required Map<String, LessonResult> progress,
  required LearnerMemory memory,
}) {
  final lessons = progress.length;
  final perfect = progress.values.where((r) => r.stars == 3).length;
  final known = cards.values.where((c) => c.isKnown).length;
  final langs = {for (final k in progress.keys) k.split(':').first};
  final aiDone = progress.keys.where((k) => k.endsWith('_speak') || k.endsWith('_write')).length;
  bool unitDone(String lang, Unit u) => ['${u.id}_dialog', '${u.id}_grammar', '${u.id}_review'].every((l) => progress.containsKey('$lang:$l'));
  final unitsDone = units.where((u) => unitDone(profile.targetLang, u)).length;
  final a1Done = units.where((u) => u.level == 'A1').every((u) => unitDone(profile.targetLang, u));
  return [
    Achievement(id: 'first', emoji: '🐣', title: ('First lesson', 'İlk ders', 'Erste Lektion'), progress: _ratio(lessons, 1)),
    Achievement(id: 'ten', emoji: '📚', title: ('10 lessons', '10 ders', '10 Lektionen'), progress: _ratio(lessons, 10)),
    Achievement(id: 'perfect', emoji: '🌟', title: ('5 perfect lessons', '5 kusursuz ders', '5 perfekte Lektionen'), progress: _ratio(perfect, 5)),
    Achievement(id: 'streak7', emoji: '🔥', title: ('7-day streak', '7 günlük seri', '7-Tage-Serie'), progress: _ratio(profile.bestStreak, 7)),
    Achievement(id: 'streak30', emoji: '🏔️', title: ('30-day streak', '30 günlük seri', '30-Tage-Serie'), progress: _ratio(profile.bestStreak, 30)),
    Achievement(id: 'words50', emoji: '🧠', title: ('50 words known', '50 kelime', '50 Wörter gelernt'), progress: _ratio(known, 50)),
    Achievement(id: 'words300', emoji: '🏛️', title: ('300 words known', '300 kelime', '300 Wörter gelernt'), progress: _ratio(known, 300)),
    Achievement(id: 'unit', emoji: '🎓', title: ('First unit done', 'İlk ünite bitti', 'Erste Einheit fertig'), progress: _ratio(unitsDone, 1)),
    Achievement(id: 'a1', emoji: '🥇', title: ('A1 complete', 'A1 tamamlandı', 'A1 geschafft'), progress: a1Done ? 1 : _ratio(units.where((u) => u.level == 'A1' && unitDone(profile.targetLang, u)).length, 14)),
    Achievement(id: 'ai', emoji: '🤖', title: ('5 AI lessons', '5 AI dersi', '5 KI-Lektionen'), progress: _ratio(aiDone, 5)),
    Achievement(id: 'polyglot', emoji: '🌍', title: ('Learn 2 languages', '2 dil öğren', '2 Sprachen lernen'), progress: _ratio(langs.length, 2)),
    Achievement(id: 'xp1000', emoji: '💎', title: ('1000 XP', '1000 XP', '1000 XP'), progress: _ratio(profile.xp, 1000)),
    Achievement(id: 'friend', emoji: '🤝', title: ('Tutor knows you (5 facts)', 'Öğretmen seni tanıyor (5 bilgi)', 'Der Tutor kennt dich (5 Fakten)'), progress: _ratio(memory.facts.length, 5)),
  ];
}
