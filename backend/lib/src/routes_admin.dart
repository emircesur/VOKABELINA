part of 'server.dart';

extension AdminRoutes on VokabelinaServer {
  Future<Response> _adminPage(Request req) async {
    final f = File('$adminWebDir/admin.html');
    if (!f.existsSync()) return Response.notFound('admin.html not found');
    return Response.ok(await f.readAsString(), headers: {'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store'});
  }

  Future<Response> _getConfig(Request req) async => jsonResponse({
        ...store.config.toJson(maskKeys: true),
        'taskDescriptions': AiRoute.descriptions,
      });

  Future<Response> _putConfig(Request req) async {
    store.config.applyAdminUpdate(await _body(req));
    store.saveConfig();
    return _getConfig(req);
  }

  Future<Response> _testProvider(Request req, String providerId) async {
    final p = store.config.provider(providerId);
    if (p == null) return errorResponse(404, 'not_found');
    final model = (req.url.queryParameters['model'] ?? '').isNotEmpty
        ? req.url.queryParameters['model']!
        : store.config.routes.firstWhere((r) => r.providerId == providerId, orElse: () => AiRoute(task: 'chat')).model;
    final started = DateTime.now();
    try {
      final r = await client.complete(p, model, system: 'Reply with the single word: pong', messages: [const ChatTurn('user', 'ping')], maxTokens: 16);
      return jsonResponse({'ok': true, 'model': model, 'reply': r.text.trim(), 'ms': DateTime.now().difference(started).inMilliseconds});
    } catch (e) {
      return jsonResponse({'ok': false, 'model': model, 'error': e is AiException ? e.message : '$e'});
    }
  }

  Future<Response> _stats(Request req) async {
    final log = store.readLog();
    final chats = log.where((e) => e['kind'] == 'chat').length;
    final rated = log.where((e) => e['kind'] == 'feedback');
    return jsonResponse({
      'requestsSinceStart': store.totalRequests,
      'errorsSinceStart': store.totalErrors,
      'activeDevicesSinceStart': store.activeDevices.length,
      'aiCallsToday': _dailyAiCalls,
      'chatsLogged': chats,
      'writingsLogged': log.where((e) => e['kind'] == 'writing').length,
      'thumbsUp': rated.where((e) => e['rating'] == 1).length,
      'thumbsDown': rated.where((e) => e['rating'] == -1).length,
      'aiConfigured': ai.hasAnyProvider,
    });
  }

  /// Aggregated learning analytics (no personal content): which mistakes are
  /// common, how learners are distributed, which teaching style wins, token usage.
  Future<Response> _insights(Request req) async {
    usage.flush();
    final log = store.readLog();
    final tags = <String, int>{};
    final levels = <String, int>{};
    final targets = <String, int>{};
    final devices = <String>{};
    var writingScore = 0, writings = 0;
    for (final e in log) {
      if (e['kind'] == 'chat') {
        devices.add('${e['device']}');
        levels.update('${e['level']}', (v) => v + 1, ifAbsent: () => 1);
        targets.update('${e['target'] ?? 'de'}', (v) => v + 1, ifAbsent: () => 1);
        for (final c in ((e['response'] as Map?)?['corrections'] as List? ?? [])) {
          final t = '${(c as Map)['tag'] ?? ''}'.trim().toLowerCase();
          if (t.isNotEmpty) tags.update(t, (v) => v + 1, ifAbsent: () => 1);
        }
      } else if (e['kind'] == 'writing') {
        writings++;
        writingScore += ((e['score'] ?? 0) as num).toInt();
        for (final t in (e['tags'] as List? ?? [])) {
          final s = '$t'.trim().toLowerCase();
          if (s.isNotEmpty) tags.update(s, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
    final topTags = tags.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return jsonResponse({
      'learners': devices.length,
      'chatTurnsByLevel': levels,
      'chatTurnsByTarget': targets,
      'topMistakeTags': [for (final e in topTags.take(15)) {'tag': e.key, 'count': e.value}],
      'averageWritingScore': writings == 0 ? null : (writingScore / writings).round(),
      'promptVariants': bandit.report(store.config.variants),
      'usage': usage.report(),
    });
  }

  /// Fine-tuning export: chats rated 👍 as `{"messages": [...]}` JSONL (OpenAI/Anthropic-style chat format).
  Future<Response> _export(Request req) async {
    final log = store.readLog();
    final good = _latestRatings(log).entries.where((e) => e.value == 1).map((e) => e.key).toSet();
    final lines = StringBuffer();
    for (final e in log) {
      if (e['kind'] != 'chat' || !good.contains(e['id'])) continue;
      final reply = (e['response'] as Map)['reply'];
      lines.writeln(jsonEncode({
        'messages': [
          ...(e['messages'] as List),
          {'role': 'assistant', 'content': reply},
        ],
        'metadata': {'level': e['level'], 'persona': e['persona'], 'target': e['target'] ?? 'de', 'variant': e['variant']},
      }));
    }
    return Response.ok(lines.toString(), headers: {'content-type': 'application/x-ndjson', 'content-disposition': 'attachment; filename="vokabelina-finetune.jsonl"'});
  }

  /// Preference data with binary labels (KTO-style): every rated reply, 👍 = true, 👎 = false.
  Future<Response> _exportKto(Request req) async {
    final log = store.readLog();
    final ratings = _latestRatings(log);
    final lines = StringBuffer();
    for (final e in log) {
      if (e['kind'] != 'chat') continue;
      final r = ratings[e['id']];
      if (r == null || r == 0) continue;
      lines.writeln(jsonEncode({
        'prompt': e['messages'],
        'completion': [
          {'role': 'assistant', 'content': (e['response'] as Map)['reply']}
        ],
        'label': r == 1,
      }));
    }
    return Response.ok(lines.toString(), headers: {'content-type': 'application/x-ndjson', 'content-disposition': 'attachment; filename="vokabelina-kto.jsonl"'});
  }

  /// The last rating per reply id wins (users can change or clear their vote).
  Map<String, int> _latestRatings(List<Map<String, dynamic>> log) => {
        for (final e in log)
          if (e['kind'] == 'feedback') '${e['id']}': (e['rating'] as num).toInt()
      };
}
