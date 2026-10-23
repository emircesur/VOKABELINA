import 'dart:math';

import 'config.dart';
import 'store.dart';

/// Online "reinforcement learning" over teaching styles: each chat reply uses
/// one [PromptVariant], learners rate replies 👍/👎, and Thompson sampling over
/// Beta(up+1, down+1) shifts traffic towards the styles learners prefer while
/// still exploring the others.
class PromptBandit {
  PromptBandit(this.store, {Random? rng}) : _rng = rng ?? Random();
  final Store store;
  final Random _rng;
  static const _doc = 'bandit.json';

  Map<String, dynamic> get _stats => store.readDoc(_doc) ?? {};

  /// Picks a variant for [task] (null when none are enabled).
  PromptVariant? choose(String task, List<PromptVariant> variants) {
    final live = variants.where((v) => v.enabled && v.task == task && v.text.trim().isNotEmpty).toList();
    if (live.isEmpty) return null;
    final stats = _stats;
    PromptVariant? best;
    var bestScore = -1.0;
    for (final v in live) {
      final s = (stats[v.id] as Map?) ?? const {};
      final score = _beta(((s['up'] ?? 0) as num).toInt() + 1, ((s['down'] ?? 0) as num).toInt() + 1);
      if (score > bestScore) {
        bestScore = score;
        best = v;
      }
    }
    _bump(best!.id, 'shown');
    return best;
  }

  void reward(String variantId, int rating) {
    if (rating == 1) _bump(variantId, 'up');
    if (rating == -1) _bump(variantId, 'down');
  }

  void _bump(String id, String key) {
    final stats = _stats;
    final s = Map<String, dynamic>.from((stats[id] as Map?) ?? {});
    s[key] = ((s[key] ?? 0) as num).toInt() + 1;
    stats[id] = s;
    store.writeDoc(_doc, stats);
  }

  /// Per-variant counts and the posterior mean win rate (for the admin panel).
  List<Map<String, dynamic>> report(List<PromptVariant> variants) {
    final stats = _stats;
    return [
      for (final v in variants)
        () {
          final s = (stats[v.id] as Map?) ?? const {};
          final up = ((s['up'] ?? 0) as num).toInt(), down = ((s['down'] ?? 0) as num).toInt();
          return {'id': v.id, 'task': v.task, 'enabled': v.enabled, 'shown': (s['shown'] ?? 0), 'up': up, 'down': down, 'winRate': (up + 1) / (up + down + 2)};
        }(),
    ];
  }

  double _beta(int a, int b) {
    final x = _gamma(a.toDouble()), y = _gamma(b.toDouble());
    return x / (x + y);
  }

  double _gamma(double k) {
    if (k < 1) return _gamma(k + 1) * pow(_rng.nextDouble(), 1 / k);
    final d = k - 1 / 3, c = 1 / sqrt(9 * d);
    while (true) {
      double x, v;
      do {
        final u1 = 1 - _rng.nextDouble(), u2 = _rng.nextDouble();
        x = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
        v = 1 + c * x;
      } while (v <= 0);
      v = v * v * v;
      final u = _rng.nextDouble();
      if (u < 1 - 0.0331 * x * x * x * x || log(u) < 0.5 * x * x + d * (1 - v + log(v))) return d * v;
    }
  }
}
