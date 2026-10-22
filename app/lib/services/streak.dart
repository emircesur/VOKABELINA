import '../data/models.dart';

String dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Adds [xp] and maintains today's XP and the daily streak.
Profile awardXp(Profile p, int xp, DateTime now) {
  final today = dayKey(now);
  final yesterday = dayKey(now.subtract(const Duration(days: 1)));
  if (p.lastActiveDay == today) {
    return p.copyWith(xp: p.xp + xp, todayXp: p.todayXp + xp);
  }
  final streak = p.lastActiveDay == yesterday ? p.streak + 1 : 1;
  return p.copyWith(xp: p.xp + xp, todayXp: xp, streak: streak, lastActiveDay: today);
}

/// The streak shown in the UI: a missed day resets it even before new activity.
int liveStreak(Profile p, DateTime now) {
  if (p.lastActiveDay == dayKey(now) || p.lastActiveDay == dayKey(now.subtract(const Duration(days: 1)))) return p.streak;
  return 0;
}

int liveTodayXp(Profile p, DateTime now) => p.lastActiveDay == dayKey(now) ? p.todayXp : 0;
