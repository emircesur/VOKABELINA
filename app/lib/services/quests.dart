import 'dart:math';

import '../core/i18n.dart';
import '../data/models.dart';
import '../data/vocab_bank.dart';

/// Today's activity counters (lessons, reviews, chat messages …) and claimed quests.
class DailyStats {
  const DailyStats({this.day = '', this.counts = const {}, this.claimed = const {}});
  final String day;
  final Map<String, int> counts;
  final Set<String> claimed;

  int operator [](String metric) => counts[metric] ?? 0;

  DailyStats bump(String metric, int n) => DailyStats(day: day, counts: {...counts, metric: this[metric] + n}, claimed: claimed);
  DailyStats claim(String questId) => DailyStats(day: day, counts: counts, claimed: {...claimed, questId});

  Map<String, dynamic> toJson() => {'day': day, 'counts': counts, 'claimed': claimed.toList()};
  factory DailyStats.fromJson(Map<String, dynamic> j) => DailyStats(
        day: '${j['day'] ?? ''}',
        counts: {for (final e in ((j['counts'] as Map?) ?? {}).entries) '${e.key}': (e.value as num).toInt()},
        claimed: {for (final x in (j['claimed'] as List? ?? [])) '$x'},
      );
}

/// Metrics a quest can count. 'xp' is read from the profile, the rest from [DailyStats].
abstract final class Metric {
  static const xp = 'xp', lessons = 'lessons', perfect = 'perfect', reviews = 'reviews', chat = 'chat', words = 'words';
}

class Quest {
  const Quest(this.id, this.metric, this.target, this.emoji, this._en, this._tr, this._de);
  final String id, metric, emoji;
  final int target;
  final String _en, _tr, _de;

  /// Title with the target number filled in.
  String title(String lang) => tr3(lang, _en, _tr, _de).replaceAll('{n}', '$target');
  int get reward => 10;
}

const _pool = [
  Quest('lessons1', Metric.lessons, 1, '📘', 'Finish a lesson', 'Bir ders bitir', 'Schließe eine Lektion ab'),
  Quest('lessons2', Metric.lessons, 2, '📚', 'Finish {n} lessons', '{n} ders bitir', 'Schließe {n} Lektionen ab'),
  Quest('perfect1', Metric.perfect, 1, '⭐', 'Get 3 stars in a lesson', 'Bir derste 3 yıldız al', 'Hol 3 Sterne in einer Lektion'),
  Quest('reviews10', Metric.reviews, 10, '🃏', 'Review {n} cards', '{n} kart tekrar et', 'Wiederhole {n} Karten'),
  Quest('reviews20', Metric.reviews, 20, '🗂️', 'Review {n} cards', '{n} kart tekrar et', 'Wiederhole {n} Karten'),
  Quest('chat3', Metric.chat, 3, '💬', 'Send {n} messages to your tutor', 'Öğretmenine {n} mesaj gönder', 'Schick deinem Tutor {n} Nachrichten'),
  Quest('chat6', Metric.chat, 6, '🗣️', 'Send {n} messages to your tutor', 'Öğretmenine {n} mesaj gönder', 'Schick deinem Tutor {n} Nachrichten'),
  Quest('words10', Metric.words, 10, '🧩', 'Practise {n} words in lessons', 'Derslerde {n} kelime çalış', 'Übe {n} Wörter in Lektionen'),
  Quest('words25', Metric.words, 25, '🧠', 'Practise {n} words in lessons', 'Derslerde {n} kelime çalış', 'Übe {n} Wörter in Lektionen'),
];

int _daySeed(String day) => day.codeUnits.fold(17, (a, c) => (a * 31 + c) & 0x7fffffff);

/// Three quests per day, the same all day: the daily XP goal plus two others with different metrics.
List<Quest> questsFor(String day, int goalXp) {
  final r = Random(_daySeed(day));
  final shuffled = [..._pool]..shuffle(r);
  final picked = <Quest>[];
  for (final q in shuffled) {
    if (picked.length == 2) break;
    if (picked.every((p) => p.metric != q.metric)) picked.add(q);
  }
  return [Quest('goal', Metric.xp, goalXp, '🔥', 'Reach your daily goal ({n} XP)', 'Günlük hedefine ulaş ({n} XP)', 'Erreiche dein Tagesziel ({n} XP)'), ...picked];
}

/// A word of the day at (or just below) the learner's level, the same for everyone on that day.
Word wordOfTheDay(String day, String level) {
  final li = levels.indexOf(level).clamp(0, 2);
  final pool = bankWords.values.where((w) => w.emoji.isNotEmpty && levels.indexOf(w.level) <= li && levels.indexOf(w.level) >= li - 1).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  return pool[_daySeed(day) % pool.length];
}
