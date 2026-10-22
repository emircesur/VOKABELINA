import '../data/models.dart';

/// 0 = again, 1 = hard, 2 = good, 3 = easy
enum Grade { again, hard, good, easy }

/// SM-2 variant with fractional intervals for the first steps.
/// Returns the same [card] mutated, so callers can persist it.
CardState schedule(CardState card, Grade grade, {DateTime? now}) {
  final t = now ?? DateTime.now();
  card.lastReviewed = t;
  switch (grade) {
    case Grade.again:
      card.lapses++;
      card.failures++;
      card.reps = 0;
      card.intervalDays = 0;
      card.ease = (card.ease - 0.2).clamp(1.3, 3.0);
      card.due = t.add(const Duration(minutes: 10));
    case Grade.hard:
      card.successes++;
      card.reps++;
      card.intervalDays = card.intervalDays == 0 ? 1 : (card.intervalDays * 1.2).ceil();
      card.ease = (card.ease - 0.15).clamp(1.3, 3.0);
      card.due = t.add(Duration(days: card.intervalDays));
    case Grade.good:
      card.successes++;
      card.reps++;
      card.intervalDays = switch (card.reps) {
        1 => 1,
        2 => 3,
        _ => (card.intervalDays * card.ease).round(),
      };
      card.due = t.add(Duration(days: card.intervalDays));
    case Grade.easy:
      card.successes++;
      card.reps++;
      card.intervalDays = switch (card.reps) {
        1 => 3,
        2 => 6,
        _ => (card.intervalDays * card.ease * 1.3).round(),
      };
      card.ease = (card.ease + 0.15).clamp(1.3, 3.0);
      card.due = t.add(Duration(days: card.intervalDays));
  }
  return card;
}

/// Preview of the next interval for the grade buttons ("10 min", "3 d").
String intervalLabel(CardState c, Grade g, {String dayUnit = 'd'}) {
  final copy = CardState.fromJson(c.toJson());
  final now = DateTime.now();
  schedule(copy, g, now: now);
  final d = copy.due.difference(now);
  if (d.inMinutes < 60) return '${d.inMinutes.clamp(1, 59)} min';
  if (d.inHours < 24) return '${d.inHours} h';
  return '${d.inDays} $dayUnit';
}
