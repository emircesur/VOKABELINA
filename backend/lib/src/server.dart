import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ai.dart';
import 'bandit.dart';
import 'config.dart';
import 'feeds.dart';
import 'memory.dart';
import 'prompts.dart';
import 'store.dart';
import 'usage.dart';

part 'routes_admin.dart';
part 'routes_learning.dart';
part 'routes_memory.dart';

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

/// Learner context common to every learning request.
class LearnerCtx {
  const LearnerCtx({required this.level, required this.native, required this.target});
  final String level;
  final String native;
  final String target;
}

class VokabelinaServer {
  VokabelinaServer({required this.store, required http.Client httpClient, this.adminToken = '', this.adminWebDir = 'web'})
      : auth = DeviceAuth(store.tokenSecret) {
    usage = UsageTracker(store);
    client = AiClient(httpClient);
    ai = AiRouter(() => store.config, client, onUsage: (p, m, t, i, o) => usage.record(p, m, t, i, o));
    feeds = FeedService(httpClient, () => store.config.feeds);
    memory = MemoryService(store, ai);
    bandit = PromptBandit(store);
  }

  final Store store;
  final String adminToken;
  final String adminWebDir;
  final DeviceAuth auth;
  final _limiter = RateLimiter();
  String _budgetDay = '';
  int _dailyAiCalls = 0;
  late final UsageTracker usage;
  late final AiClient client;
  late final AiRouter ai;
  late final FeedService feeds;
  late final MemoryService memory;
  late final PromptBandit bandit;

  /// In-memory LRU-ish cache for per-request results.
  final _cache = <String, Map<String, dynamic>>{};

  /// Background jobs (memory consolidation) — awaited by tests via [idle].
  final _jobs = <Future<void>>{};
  Future<void> get idle => Future.wait(_jobs.toList());

  static String _today() => DateTime.now().toUtc().toIso8601String().substring(0, 10);
  static String deviceHash(String deviceId) => sha1.convert(utf8.encode(deviceId)).toString().substring(0, 10);

  Handler get handler {
    final r = Router()
      ..get('/health', (Request _) => jsonResponse({'ok': true, 'aiConfigured': ai.hasAnyProvider, 'imagesEnabled': store.config.imagesEnabled}))
      ..post('/v1/auth/register', _register)
      ..post('/v1/ai/chat', _guard(_chat, ai: true))
      ..post('/v1/ai/translate', _guard(_translate, ai: true))
      ..post('/v1/ai/simplify', _guard(_simplify, ai: true))
      ..post('/v1/ai/word', _guard(_word, ai: true))
      ..post('/v1/ai/check', _guard(_check, ai: true))
      ..post('/v1/ai/judge', _guard(_judge, ai: true))
      ..post('/v1/ai/practice', _guard(_practice, ai: true))
      ..post('/v1/ai/story', _guard(_story, ai: true))
      ..post('/v1/ai/grammar', _guard(_grammar, ai: true))
      ..get('/v1/feed/news', _guard(_news))
      ..get('/v1/feed/memes', _guard(_memes, ai: true))
      ..get('/v1/images/<file>', _image)
      ..post('/v1/feedback', _guard(_feedback))
      ..post('/v1/memory/sync', _guard(_memorySync))
      ..post('/v1/memory/delete', _guard(_memoryDelete))
      ..get('/admin', _adminPage)
      ..get('/admin/', _adminPage)
      ..get('/admin/api/config', _admin(_getConfig))
      ..put('/admin/api/config', _admin(_putConfig))
      ..post('/admin/api/test/<providerId>', (Request req, String id) => _admin((r) => _testProvider(r, id))(req))
      ..get('/admin/api/stats', _admin(_stats))
      ..get('/admin/api/insights', _admin(_insights))
      ..get('/admin/api/export.jsonl', _admin(_export))
      ..get('/admin/api/export-kto.jsonl', _admin(_exportKto));
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

  static LearnerCtx _ctx(Map<String, dynamic> b) {
    final native = _lng(b['nativeLang']);
    var target = _lng(b['targetLang'], 'de');
    if (target == native) target = native == 'de' ? 'en' : 'de';
    return LearnerCtx(level: _level(b['level']), native: native, target: target);
  }

  static List<Map<String, String>> _words(Object? v) => [
        for (final w in (v as List? ?? []))
          if (w is Map) {'de': '${w['de'] ?? ''}', 'en': '${w['en'] ?? ''}', 'tr': '${w['tr'] ?? ''}'}
      ];

  void _remember(String key, Map<String, dynamic> value) {
    if (_cache.length > 500) _cache.remove(_cache.keys.first);
    _cache[key] = value;
  }

  /// Shared on-disk cache for content that is the same for every learner (word coach, grammar).
  Map<String, dynamic>? _diskCache(String key) => store.readDoc('cache/${sha1.convert(utf8.encode(key))}.json');
  void _diskCachePut(String key, Map<String, dynamic> v) => store.writeDoc('cache/${sha1.convert(utf8.encode(key))}.json', v);

  void _background(Future<void> Function() job) {
    late final Future<void> f;
    f = job().catchError((_) {}).whenComplete(() => _jobs.remove(f));
    _jobs.add(f);
  }

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
}

extension _TakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
