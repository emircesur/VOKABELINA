import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ai.dart';
import 'config.dart';
import 'feeds.dart';
import 'prompts.dart';
import 'store.dart';

final _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonResponse(Object body, {int status = 200}) => Response(status, body: jsonEncode(body), headers: _jsonHeaders);
Response errorResponse(int status, String code, [String? message]) =>
    jsonResponse({'error': code, if (message != null) 'message': message}, status: status);

/// Anonymous device tokens: `v1.<deviceId>.<hmac>`; no personal data is stored.
class DeviceAuth {
  DeviceAuth(this.secret);
  final String secret;

  String issue(String deviceId) => 'v1.$deviceId.${_sig(deviceId)}';

  String? verify(String? header) {
    if (header == null || !header.startsWith('Bearer ')) return null;
    final parts = header.substring(7).split('.');
    if (parts.length != 3 || parts[0] != 'v1') return null;
    return _safeEq(parts[2], _sig(parts[1])) ? parts[1] : null;
  }

  String _sig(String id) => Hmac(sha256, utf8.encode(secret)).convert(utf8.encode(id)).toString();
}

bool _safeEq(String a, String b) {
  if (a.length != b.length) return false;
  var r = 0;
  for (var i = 0; i < a.length; i++) {
    r |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return r == 0;
}

/// Sliding one-minute window per key.
class RateLimiter {
  final _hits = <String, List<DateTime>>{};
  bool allow(String key, int perMinute, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final list = _hits.putIfAbsent(key, () => []);
    list.removeWhere((h) => t.difference(h) > const Duration(minutes: 1));
    if (list.length >= perMinute) return false;
    list.add(t);
    return true;
  }
}

class VokabelinaServer {
  VokabelinaServer({required this.store, required http.Client httpClient, this.adminToken = '', this.adminWebDir = 'web'})
      : _http = httpClient,
        auth = DeviceAuth(store.tokenSecret) {
    ai = AiRouter(() => store.config, AiClient(httpClient));
    feeds = FeedService(httpClient, () => store.config.feeds);
  }

  final Store store;
  final http.Client _http;
  final String adminToken;
  final String adminWebDir;
  final DeviceAuth auth;
  final _limiter = RateLimiter();
  String _budgetDay = '';
  int _dailyAiCalls = 0;
  static String _today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);
  late final AiRouter ai;
  late final FeedService feeds;
  final _cache = <String, Map<String, dynamic>>{};

  Handler get handler {
    final r = Router()
      ..get('/health', (Request _) => jsonResponse({'ok': true, 'aiConfigured': ai.hasAnyProvider}))
      ..post('/v1/auth/register', _register)
      ..post('/v1/ai/chat', _guard(_chat, ai: true))
      ..post('/v1/ai/translate', _guard(_translate, ai: true))
      ..post('/v1/ai/simplify', _guard(_simplify, ai: true))
      ..get('/v1/feed/news', _guard(_news))
      ..get('/v1/feed/memes', _guard(_memes, ai: true))
      ..post('/v1/feedback', _guard(_feedback))
      ..get('/admin', _adminPage)
      ..get('/admin/', _adminPage)
      ..get('/admin/api/config', _admin(_getConfig))
      ..put('/admin/api/config', _admin(_putConfig))
      ..post('/admin/api/test/<providerId>', (Request req, String id) => _admin((r) => _testProvider(r, id))(req))
      ..get('/admin/api/stats', _admin(_stats))
      ..get('/admin/api/export.jsonl', _admin(_export));
    return const Pipeline().addMiddleware(_cors).addMiddleware(_safe).addHandler(r.call);
  }

  // ---------------------------------------------------------------- plumbing

  Middleware get _cors => (inner) => (req) async {
        const h = {
          'access-control-allow-origin': '*',
          'access-control-allow-headers': 'authorization, content-type',
          'access-control-allow-methods': 'GET, POST, PUT, OPTIONS',
        };
        if (req.method == 'OPTIONS') return Response.ok('', headers: h);
        return (await inner(req)).change(headers: h);
      };

  Middleware get _safe => (inner) => (req) async {
        try {
          return await inner(req);
        } on FormatException catch (e) {
          return errorResponse(400, 'bad_request', e.message);
        } catch (e) {
          store.totalErrors++;
          return errorResponse(500, 'internal', '$e');
        }
      };

  /// [ai] endpoints additionally count against the global per-minute and daily budgets.
  Handler _guard(Future<Response> Function(Request, String deviceId) fn, {bool ai = false}) => (req) async {
        final id = auth.verify(req.headers['authorization']);
        if (id == null) return errorResponse(401, 'unauthorized');
        if (!_limiter.allow(id, store.config.rateLimitPerMinute)) return errorResponse(429, 'rate_limited');
        if (ai) {
          final day = _today();
          if (day != _budgetDay) {
            _budgetDay = day;
            _dailyAiCalls = 0;
          }
          if (_dailyAiCalls >= store.config.dailyAiLimit) return errorResponse(429, 'daily_budget_exhausted');
          if (!_limiter.allow('*global*', store.config.globalAiPerMinute)) return errorResponse(429, 'server_busy');
          _dailyAiCalls++;
        }
        store.totalRequests++;
        store.activeDevices.add(id);
        return fn(req, id);
      };

  Handler _admin(Future<Response> Function(Request) fn) => (req) async {
        if (adminToken.isEmpty) return errorResponse(503, 'admin_disabled', 'Set the ADMIN_TOKEN environment variable.');
        final h = req.headers['authorization'] ?? '';
        if (!h.startsWith('Bearer ') || !_safeEq(h.substring(7), adminToken)) return errorResponse(401, 'unauthorized');
        return fn(req);
      };

  Future<Map<String, dynamic>> _body(Request req) async {
    final raw = await req.readAsString();
    final v = jsonDecode(raw.isEmpty ? '{}' : raw);
    if (v is! Map<String, dynamic>) throw const FormatException('JSON object expected');
    return v;
  }

  Response _aiError(Object e) {
    store.totalErrors++;
    if (!ai.hasAnyProvider) return errorResponse(503, 'no_provider', 'No AI provider configured.');
    return errorResponse(502, 'ai_failed', e is AiException ? e.message : '$e');
  }

  static String _level(Object? v) {
    final s = '$v'.toUpperCase();
    return levelGuides.containsKey(s) ? s : 'A1';
  }

  static String _lng(Object? v, [String fallback = 'en']) => langNames.containsKey('$v') ? '$v' : fallback;

  // ------------------------------------------------------------------ public

  /// Client address as seen by the nearest trusted proxy (Railway appends it to X-Forwarded-For).
  String _clientIp(Request req) {
    final fwd = req.headers['x-forwarded-for'];
    if (fwd != null && fwd.trim().isNotEmpty) return fwd.split(',').last.trim();
    final info = req.context['shelf.io.connection_info'];
    return info is HttpConnectionInfo ? info.remoteAddress.address : 'unknown';
  }

  Future<Response> _register(Request req) async {
    // Registration is open, so cap it per IP: otherwise minting device ids would bypass per-device limits.
    if (!_limiter.allow('reg:${_clientIp(req)}', 10)) return errorResponse(429, 'rate_limited');
    final body = await _body(req);
    final id = '${body['deviceId'] ?? ''}';
    if (!RegExp(r'^[A-Za-z0-9_-]{8,64}$').hasMatch(id)) return errorResponse(400, 'bad_device_id');
    return jsonResponse({'token': auth.issue(id)});
  }

  Future<Response> _chat(Request req, String deviceId) async {
    final b = await _body(req);
    final level = _level(b['level']);
    final persona = personas.containsKey(b['persona']) ? '${b['persona']}' : 'bruno';
    final native = _lng(b['nativeLang']);
    final raw = (b['messages'] as List? ?? []).takeLast(20);
    final turns = [
      for (final m in raw)
        ChatTurn((m as Map)['role'] == 'assistant' ? 'assistant' : 'user', '${m['content']}'.trim()),
    ].where((t) => t.content.isNotEmpty).toList();
    if (turns.isEmpty || turns.last.role != 'user') return errorResponse(400, 'bad_request', 'Last message must be from the user.');
    final memory = Map<String, dynamic>.from((b['memory'] as Map?) ?? {});
    try {
      final out = await ai.run(
        'chat',
        system: chatSystemPrompt(persona: persona, level: level, nativeLang: native, memory: memory),
        messages: turns,
        json: true,
      );
      final parsed = extractJsonObject(out.text);
      // Models occasionally ignore the JSON contract: degrade to a plain reply.
      final result = parsed != null && parsed['reply'] is String
          ? _normalizeChat(parsed)
          : {'reply': out.text.trim(), 'replyNative': '', 'corrections': [], 'newWords': [], 'usedKnownWords': [], 'suggestions': [], 'newFacts': [], 'mood': 'happy'};
      final id = sha1.convert(utf8.encode('$deviceId${DateTime.now().microsecondsSinceEpoch}')).toString().substring(0, 12);
      store.logInteraction({
        'kind': 'chat',
        'id': id,
        'device': sha1.convert(utf8.encode(deviceId)).toString().substring(0, 10),
        'level': level,
        'persona': persona,
        'model': out.used,
        'messages': [for (final t in turns) {'role': t.role, 'content': t.content}],
        'response': result,
      });
      return jsonResponse({...result, 'id': id, 'model': out.used});
    } catch (e) {
      return _aiError(e);
    }
  }

  Map<String, dynamic> _normalizeChat(Map<String, dynamic> p) {
    List<Map<String, dynamic>> maps(Object? v, List<String> keys) => [
          for (final x in (v as List? ?? []))
            if (x is Map) {for (final k in keys) k: '${x[k] ?? ''}'}
        ];
    const moods = {'happy', 'thinking', 'sad', 'cheer'};
    return {
      'reply': p['reply'],
      'replyNative': '${p['replyNative'] ?? ''}',
      'corrections': maps(p['corrections'], ['original', 'corrected', 'explanation']),
      'newWords': maps(p['newWords'], ['de', 'en', 'tr']),
      'usedKnownWords': [for (final w in (p['usedKnownWords'] as List? ?? [])) '$w'],
      'suggestions': [for (final w in (p['suggestions'] as List? ?? [])) '$w'].take(3).toList(),
      'newFacts': [for (final w in (p['newFacts'] as List? ?? [])) '$w'].take(3).toList(),
      'mood': moods.contains(p['mood']) ? p['mood'] : 'happy',
    };
  }

  Future<Response> _translate(Request req, String deviceId) async {
    final b = await _body(req);
    final text = '${b['text'] ?? ''}'.trim();
    if (text.isEmpty || text.length > 1500) return errorResponse(400, 'bad_request', 'text must be 1-1500 chars');
    final from = _lng(b['from'], 'de');
    final to = _lng(b['to'], 'en');
    final level = _level(b['level']);
    final key = 'tr|$from|$to|$level|$text';
    if (_cache[key] case final hit?) return jsonResponse(hit);
    try {
      final out = await ai.run('translate',
          system: translateSystemPrompt(from: from, to: to, level: level),
          messages: [ChatTurn('user', text)],
          json: true,
          temperature: 0.2);
      final p = extractJsonObject(out.text);
      final res = {
        'translation': '${p?['translation'] ?? out.text.trim()}',
        'notes': '${p?['notes'] ?? ''}',
        'words': [
          for (final w in (p?['words'] as List? ?? []))
            if (w is Map) {'de': '${w['de'] ?? ''}', 'en': '${w['en'] ?? ''}', 'tr': '${w['tr'] ?? ''}'}
        ],
      };
      _remember(key, res);
      return jsonResponse(res);
    } catch (e) {
      return _aiError(e);
    }
  }

  Future<Response> _news(Request req, String deviceId) async {
    final items = await feeds.news();
    return jsonResponse({'items': [for (final n in items.take(30)) n.toJson()]});
  }

  Future<Response> _simplify(Request req, String deviceId) async {
    final b = await _body(req);
    final level = _level(b['level']);
    final native = _lng(b['nativeLang']);
    final item = feeds.byId('${b['id'] ?? ''}');
    final text = item != null ? '${item.title}. ${item.summary}' : '${b['text'] ?? ''}'.trim();
    if (text.isEmpty || text.length > 3000) return errorResponse(400, 'bad_request', 'unknown article id or empty text');
    final key = 'simp|${sha1.convert(utf8.encode(text))}|$level|$native';
    if (_cache[key] case final hit?) return jsonResponse(hit);
    try {
      final out = await ai.run('simplify',
          system: simplifySystemPrompt(level: level, nativeLang: native),
          messages: [ChatTurn('user', text)],
          json: true,
          temperature: 0.3);
      final p = extractJsonObject(out.text);
      if (p == null || p['german'] is! String) return errorResponse(502, 'ai_failed', 'Unparseable model output');
      final res = {
        'german': p['german'],
        'translation': '${p['translation'] ?? ''}',
        'cultureNote': '${p['cultureNote'] ?? ''}',
        'keywords': [
          for (final w in (p['keywords'] as List? ?? []))
            if (w is Map) {'de': '${w['de'] ?? ''}', 'en': '${w['en'] ?? ''}', 'tr': '${w['tr'] ?? ''}'}
        ],
      };
      _remember(key, res);
      return jsonResponse(res);
    } catch (e) {
      return _aiError(e);
    }
  }

  Future<Response> _memes(Request req, String deviceId) async {
    final q = req.url.queryParameters;
    final level = _level(q['level']);
    final native = _lng(q['lang']);
    final count = (int.tryParse(q['count'] ?? '') ?? 5).clamp(1, 8);
    final day = _today();
    final key = 'memes|$day|$level|$native|$count';
    if (_cache[key] case final hit?) return jsonResponse(hit);
    try {
      final out = await ai.run('memes',
          system: memesSystemPrompt(level: level, nativeLang: native, count: count),
          messages: [ChatTurn('user', 'Date: $day. Create today\'s memes.')],
          json: true,
          temperature: 0.95,
          maxTokens: 1800);
      final p = extractJsonObject(out.text);
      final list = p?['memes'];
      if (list is! List || list.isEmpty) return errorResponse(502, 'ai_failed', 'Unparseable model output');
      final res = {
        'date': day,
        'memes': [
          for (var i = 0; i < list.length; i++)
            if (list[i] is Map)
              {
                'id': '$day-$level-$i',
                'top': '${list[i]['top'] ?? ''}',
                'bottom': '${list[i]['bottom'] ?? ''}',
                'theme': '${list[i]['theme'] ?? ''}',
                'emoji': '${list[i]['emoji'] ?? '🥨'}',
                'explanation': '${list[i]['explanation'] ?? ''}',
                'vocab': [
                  for (final w in (list[i]['vocab'] as List? ?? []))
                    if (w is Map) {'de': '${w['de'] ?? ''}', 'en': '${w['en'] ?? ''}', 'tr': '${w['tr'] ?? ''}'}
                ],
              }
        ],
      };
      _remember(key, res);
      return jsonResponse(res);
    } catch (e) {
      return _aiError(e);
    }
  }

  void _remember(String key, Map<String, dynamic> value) {
    if (_cache.length > 500) _cache.remove(_cache.keys.first);
    _cache[key] = value;
  }

  /// Thumbs up/down on a tutor message. Rated chats become the fine-tuning set.
  Future<Response> _feedback(Request req, String deviceId) async {
    final b = await _body(req);
    final rating = b['rating'];
    if (rating != 1 && rating != -1) return errorResponse(400, 'bad_request', 'rating must be 1 or -1');
    store.logInteraction({'kind': 'feedback', 'id': '${b['id']}', 'rating': rating, 'note': '${b['note'] ?? ''}'});
    return jsonResponse({'ok': true});
  }

  // ------------------------------------------------------------------- admin

  Future<Response> _adminPage(Request req) async {
    final f = File('$adminWebDir/admin.html');
    if (!f.existsSync()) return Response.notFound('admin.html not found');
    return Response.ok(await f.readAsString(), headers: {'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store'});
  }

  Future<Response> _getConfig(Request req) async => jsonResponse(store.config.toJson(maskKeys: true));

  Future<Response> _putConfig(Request req) async {
    store.config.applyAdminUpdate(await _body(req));
    store.saveConfig();
    return jsonResponse(store.config.toJson(maskKeys: true));
  }

  Future<Response> _testProvider(Request req, String providerId) async {
    final p = store.config.provider(providerId);
    if (p == null) return errorResponse(404, 'not_found');
    final model = (req.url.queryParameters['model'] ?? '').isNotEmpty
        ? req.url.queryParameters['model']!
        : store.config.routes.firstWhere((r) => r.providerId == providerId, orElse: () => AiRoute(task: 'chat')).model;
    final started = DateTime.now();
    try {
      final text = await AiClient(_http).complete(p, model,
          system: 'Reply with the single word: pong', messages: [const ChatTurn('user', 'ping')], maxTokens: 16);
      return jsonResponse({'ok': true, 'model': model, 'reply': text.trim(), 'ms': DateTime.now().difference(started).inMilliseconds});
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
      'chatsLogged': chats,
      'thumbsUp': rated.where((e) => e['rating'] == 1).length,
      'thumbsDown': rated.where((e) => e['rating'] == -1).length,
      'aiConfigured': ai.hasAnyProvider,
    });
  }

  /// Fine-tuning export: chats rated 👍 as `{"messages": [...]}` JSONL (OpenAI/Anthropic-style chat format).
  Future<Response> _export(Request req) async {
    final log = store.readLog();
    final good = {for (final e in log) if (e['kind'] == 'feedback' && e['rating'] == 1) e['id']};
    final lines = StringBuffer();
    for (final e in log) {
      if (e['kind'] != 'chat' || !good.contains(e['id'])) continue;
      final reply = (e['response'] as Map)['reply'];
      lines.writeln(jsonEncode({
        'messages': [
          ...(e['messages'] as List),
          {'role': 'assistant', 'content': reply},
        ],
        'metadata': {'level': e['level'], 'persona': e['persona']},
      }));
    }
    return Response.ok(lines.toString(), headers: {'content-type': 'application/x-ndjson', 'content-disposition': 'attachment; filename="vokabelina-finetune.jsonl"'});
  }
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
