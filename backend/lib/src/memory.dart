import 'dart:async';

import 'ai.dart';
import 'prompts.dart';
import 'store.dart';

/// Server-side long-term memory per (hashed) device.
///
/// * Semantic: facts with categories, interests, goals, a profile summary.
/// * Procedural: mistake tags aggregated across sessions.
/// * Episodic: one summary per consolidated conversation stretch.
///
/// Consolidation runs in the background every few chat turns: the AI reads the
/// recent turns from the interaction log and updates the memory. Retrieval
/// adds the profile and the most relevant past episodes to each chat prompt.
class MemoryService {
  MemoryService(this.store, this.ai, {this.turnsPerConsolidation = 8});
  final Store store;
  final AiRouter ai;
  final int turnsPerConsolidation;
  final _running = <String>{};

  String _doc(String hash) => 'memory/$hash.json';

  Map<String, dynamic> get(String hash) => store.readDoc(_doc(hash)) ?? {};

  void _save(String hash, Map<String, dynamic> m) => store.writeDoc(_doc(hash), m);

  void delete(String hash) => store.deleteDoc(_doc(hash));

  /// Counts a chat turn; returns true when a consolidation is due.
  bool noteTurn(String hash) {
    final m = get(hash);
    m['turnsSince'] = ((m['turnsSince'] ?? 0) as num).toInt() + 1;
    _save(hash, m);
    return (m['turnsSince'] as int) >= turnsPerConsolidation;
  }

  /// Merges what the app knows (facts, interests, goals) into the server memory.
  void mergeClient(String hash, Map<String, dynamic> client) {
    final m = get(hash);
    final facts = _facts(m['facts']);
    for (final f in (client['facts'] as List? ?? [])) {
      final text = (f is Map ? (f['t'] ?? f['text']) : f)?.toString().trim() ?? '';
      if (text.isEmpty) continue;
      final cat = f is Map ? '${f['c'] ?? f['category'] ?? 'other'}' : 'other';
      if (!facts.any((x) => '${x['text']}'.toLowerCase() == text.toLowerCase())) facts.add({'text': text, 'category': cat});
    }
    m['facts'] = facts.length > 60 ? facts.sublist(facts.length - 60) : facts;
    m['interests'] = _union(m['interests'], client['interests'], 15);
    m['goals'] = _union(m['goals'], client['goals'], 10);
    _save(hash, m);
  }

  List<Map<String, dynamic>> _facts(Object? v) => [for (final f in (v as List? ?? [])) if (f is Map) Map<String, dynamic>.from(f)];

  List<String> _union(Object? a, Object? b, int max) {
    final out = <String>[];
    for (final x in [...(a as List? ?? []), ...(b as List? ?? [])]) {
      final s = '$x'.trim();
      if (s.isNotEmpty && !out.any((y) => y.toLowerCase() == s.toLowerCase())) out.add(s);
    }
    return out.length > max ? out.sublist(out.length - max) : out;
  }

  /// Recent chat turns of this device since the last consolidation.
  List<(String, String)> _recentTurns(String hash, String? since) {
    final turns = <(String, String)>[];
    for (final e in store.readLog()) {
      if (e['kind'] != 'chat' || e['device'] != hash) continue;
      if (since != null && '${e['ts']}'.compareTo(since) <= 0) continue;
      final msgs = (e['messages'] as List? ?? []);
      final user = msgs.isEmpty ? '' : '${(msgs.last as Map)['content']}';
      final reply = '${(e['response'] as Map?)?['reply'] ?? ''}';
      turns.add((user, reply));
    }
    return turns.length > 40 ? turns.sublist(turns.length - 40) : turns;
  }

  /// Runs the AI consolidation (no-op if nothing new or already running).
  Future<bool> consolidate(String hash, {required String target, required String native, required String level, DateTime? now}) async {
    if (_running.contains(hash)) return false;
    final m = get(hash);
    final turns = _recentTurns(hash, m['lastConsolidated'] as String?);
    if (turns.isEmpty) return false;
    _running.add(hash);
    try {
      final transcript = [for (final (u, a) in turns) 'Learner: $u\nTutor: $a'].join('\n---\n');
      final out = await ai.runJson(
        'memory',
        system: memoryConsolidationPrompt(target: target, native: native, level: level),
        messages: [
          ChatTurn('user', 'CURRENT MEMORY:\n${_brief(m)}\n\nNEW CONVERSATION TURNS:\n$transcript'),
        ],
        temperature: 0.2,
        maxTokens: 1200,
        valid: (j) => j['summary'] is String,
      );
      final j = out.json;
      final ts = (now ?? DateTime.now()).toUtc().toIso8601String();
      final fresh = get(hash); // re-read: turns may have been counted meanwhile
      fresh['summary'] = '${j['summary']}'.trim();
      final facts = _facts(fresh['facts']);
      for (final f in (j['facts'] as List? ?? [])) {
        if (f is! Map) continue;
        final text = '${f['text'] ?? ''}'.trim();
        if (text.isEmpty) continue;
        final i = facts.indexWhere((x) => '${x['text']}'.toLowerCase() == text.toLowerCase());
        final entry = {'text': text, 'category': '${f['category'] ?? 'other'}'};
        i >= 0 ? facts[i] = entry : facts.add(entry);
      }
      fresh['facts'] = facts.length > 60 ? facts.sublist(facts.length - 60) : facts;
      fresh['interests'] = _union(fresh['interests'], j['interests'], 15);
      fresh['goals'] = _union(fresh['goals'], j['goals'], 10);
      final tags = Map<String, dynamic>.from((fresh['mistakeTags'] as Map?) ?? {});
      for (final t in (j['mistakeTags'] as List? ?? [])) {
        if (t is! Map) continue;
        final tag = '${t['tag'] ?? ''}'.trim().toLowerCase();
        if (tag.isEmpty) continue;
        final prev = Map<String, dynamic>.from((tags[tag] as Map?) ?? {'count': 0});
        tags[tag] = {'count': (prev['count'] as num).toInt() + 1, 'explanation': '${t['explanation'] ?? prev['explanation'] ?? ''}', 'lang': target};
      }
      fresh['mistakeTags'] = tags;
      final ep = j['episode'];
      if (ep is Map && '${ep['summary'] ?? ''}'.trim().isNotEmpty) {
        final eps = [for (final e in (fresh['episodes'] as List? ?? [])) Map<String, dynamic>.from(e as Map)];
        eps.insert(0, {'d': ts, 's': '${ep['summary']}', 't': [for (final x in (ep['topics'] as List? ?? [])) '$x'], 'lang': target});
        fresh['episodes'] = eps.take(30).toList();
      }
      if (_levels.contains(j['estimatedLevel'])) fresh['estimatedLevel'] = j['estimatedLevel'];
      fresh['focus'] = [for (final x in (j['focus'] as List? ?? [])) '$x'].take(4).toList();
      fresh['lastConsolidated'] = ts;
      fresh['turnsSince'] = 0;
      _save(hash, fresh);
      return true;
    } finally {
      _running.remove(hash);
    }
  }

  static const _levels = {'A1', 'A2', 'B1', 'B2', 'C1', 'C2'};

  String _brief(Map<String, dynamic> m) {
    final facts = _facts(m['facts']).map((f) => f['text']).join('; ');
    return [
      if ('${m['summary'] ?? ''}'.isNotEmpty) 'Summary: ${m['summary']}',
      if (facts.isNotEmpty) 'Facts: $facts',
      if ((m['interests'] as List?)?.isNotEmpty ?? false) 'Interests: ${(m['interests'] as List).join(', ')}',
      if ((m['goals'] as List?)?.isNotEmpty ?? false) 'Goals: ${(m['goals'] as List).join(', ')}',
    ].join('\n');
  }

  /// Episodes ranked by word overlap with [query] plus a small recency bonus.
  List<Map<String, dynamic>> relevantEpisodes(String hash, String query, {int k = 2, String? lang}) {
    final eps = [
      for (final e in (get(hash)['episodes'] as List? ?? []))
        if (lang == null || (e as Map)['lang'] == null || e['lang'] == lang) Map<String, dynamic>.from(e as Map)
    ];
    if (eps.isEmpty) return const [];
    final q = _words(query);
    final scored = <(double, Map<String, dynamic>)>[];
    for (var i = 0; i < eps.length; i++) {
      final e = eps[i];
      final w = _words('${e['s']} ${(e['t'] as List? ?? []).join(' ')}');
      final overlap = q.intersection(w).length.toDouble();
      scored.add((overlap * 2 + 1 / (i + 1), e)); // newest first in the list
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [for (final s in scored.take(k)) s.$2];
  }

  static Set<String> _words(String s) => {for (final m in RegExp(r'[\p{L}]{4,}', unicode: true).allMatches(s.toLowerCase())) m.group(0)!};

  /// Block appended to the chat system prompt.
  String promptContext(String hash, String query, {String? lang}) {
    final m = get(hash);
    final parts = <String>[];
    if ('${m['summary'] ?? ''}'.isNotEmpty) parts.add('- Profile: ${m['summary']}');
    final eps = relevantEpisodes(hash, query, lang: lang);
    for (final e in eps) {
      parts.add('- Earlier conversation (${'${e['d']}'.substring(0, 10)}): ${e['s']}');
    }
    final focus = (m['focus'] as List? ?? []);
    if (focus.isNotEmpty) parts.add('- Suggested focus: ${focus.join('; ')}');
    return parts.isEmpty ? '' : 'LONG-TERM MEMORY (from earlier sessions; refer to it naturally, e.g. ask how something went):\n${parts.join('\n')}';
  }

  /// What the app shows in the memory hub.
  Map<String, dynamic> publicView(String hash) {
    final m = get(hash);
    return {
      'summary': m['summary'] ?? '',
      'estimatedLevel': m['estimatedLevel'] ?? '',
      'focus': m['focus'] ?? [],
      'interests': m['interests'] ?? [],
      'goals': m['goals'] ?? [],
      'facts': m['facts'] ?? [],
      'episodes': m['episodes'] ?? [],
      'mistakeTags': m['mistakeTags'] ?? {},
      'lastConsolidated': m['lastConsolidated'],
    };
  }
}
