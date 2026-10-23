import 'store.dart';

/// Token usage per day and provider/model/task (for cost control in the admin panel).
class UsageTracker {
  UsageTracker(this.store);
  final Store store;
  static const _doc = 'usage.json';
  Map<String, dynamic>? _cache;
  int _dirty = 0;

  Map<String, dynamic> get _data => _cache ??= store.readDoc(_doc) ?? {};

  void record(String provider, String model, String task, int input, int output, {DateTime? now}) {
    final day = (now ?? DateTime.now()).toUtc().toIso8601String().substring(0, 10);
    final days = _data;
    final d = Map<String, dynamic>.from((days[day] as Map?) ?? {});
    final key = '$provider/$model/$task';
    final e = Map<String, dynamic>.from((d[key] as Map?) ?? {'calls': 0, 'in': 0, 'out': 0});
    e['calls'] = (e['calls'] as num).toInt() + 1;
    e['in'] = (e['in'] as num).toInt() + input;
    e['out'] = (e['out'] as num).toInt() + output;
    d[key] = e;
    days[day] = d;
    // keep 90 days
    if (days.length > 90) {
      final keys = days.keys.toList()..sort();
      for (final k in keys.take(days.length - 90)) {
        days.remove(k);
      }
    }
    if (++_dirty >= 5) flush();
  }

  void flush() {
    if (_cache == null) return;
    store.writeDoc(_doc, _cache!);
    _dirty = 0;
  }

  /// Last [days] days, newest first: [{day, key, calls, in, out}].
  List<Map<String, dynamic>> report({int days = 14}) {
    final data = _data;
    final keys = data.keys.toList()..sort((a, b) => b.compareTo(a));
    return [
      for (final day in keys.take(days))
        for (final e in (data[day] as Map).entries) {'day': day, 'key': e.key, ...Map<String, dynamic>.from(e.value as Map)}
    ];
  }
}
