import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../data/models.dart';

const _definedBase = String.fromEnvironment('API_BASE');

class ApiException implements Exception {
  ApiException(this.message, {this.status, this.code});
  final String message;
  final int? status;
  final String? code;

  /// Server reachable but no AI key configured yet.
  bool get noProvider => code == 'no_provider';
  @override
  String toString() => 'ApiException($status/$code): $message';
}

/// Thin client for the Vokabelina backend. All AI calls go through it, so API
/// keys never exist in the app.
class ApiClient {
  ApiClient(this._http, this._prefs, {String baseUrl = ''}) : baseUrl = _normalize(baseUrl.isNotEmpty ? baseUrl : _definedBase);

  final http.Client _http;
  final SharedPreferences _prefs;
  final String baseUrl;
  String? _token;

  bool get configured => baseUrl.isNotEmpty;

  static String _normalize(String s) => s.trim().replaceAll(RegExp(r'/+$'), '');

  String get _deviceId {
    var id = _prefs.getString('deviceId');
    if (id == null) {
      final r = Random.secure();
      id = List.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
      _prefs.setString('deviceId', id);
    }
    return id;
  }

  Future<Map<String, String>> _headers() async {
    _token ??= await _register();
    return {'content-type': 'application/json', 'authorization': 'Bearer $_token'};
  }

  Future<String> _register() async {
    final res = await _send(() => _http.post(Uri.parse('$baseUrl/v1/auth/register'),
        headers: {'content-type': 'application/json'}, body: jsonEncode({'deviceId': _deviceId})));
    return (_decode(res) as Map)['token'] as String;
  }

  Future<http.Response> _send(Future<http.Response> Function() f) async {
    if (!configured) throw ApiException('No server configured', code: 'not_configured');
    try {
      return await f().timeout(const Duration(seconds: 70));
    } catch (e) {
      throw ApiException('Server not reachable: $e', code: 'unreachable');
    }
  }

  Object _decode(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    Object? json;
    try {
      json = jsonDecode(body);
    } catch (_) {}
    if (res.statusCode >= 300) {
      final m = json is Map ? json : const {};
      throw ApiException('${m['message'] ?? body}', status: res.statusCode, code: m['error'] as String?);
    }
    return json ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> _call(String method, String path, {Object? body}) async {
    Future<http.Response> go() async {
      final h = await _headers();
      final uri = Uri.parse('$baseUrl$path');
      return method == 'GET' ? _http.get(uri, headers: h) : _http.post(uri, headers: h, body: jsonEncode(body ?? {}));
    }

    var res = await _send(go);
    if (res.statusCode == 401) {
      _token = null; // server secret rotated: re-register once
      res = await _send(go);
    }
    return Map<String, dynamic>.from(_decode(res) as Map);
  }

  Future<bool> health() async {
    try {
      final res = await _send(() => _http.get(Uri.parse('$baseUrl/health')));
      return res.statusCode == 200;
    } on ApiException {
      return false;
    }
  }

  Future<ChatReply> chat({
    required Profile profile,
    required List<ChatMessage> history,
    required Map<String, dynamic> memory,
  }) async {
    final j = await _call('POST', '/v1/ai/chat', body: {
      'level': profile.level,
      'persona': profile.persona,
      'nativeLang': profile.nativeLang,
      'memory': memory,
      'messages': [
        for (final m in history.where((m) => m.text.isNotEmpty).toList().reversed.take(14).toList().reversed)
          {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text}
      ],
    });
    return ChatReply.fromJson(j, level: profile.level);
  }

  Future<Translation> translate(String text, {required String from, required String to, required String level}) async =>
      Translation.fromJson(await _call('POST', '/v1/ai/translate', body: {'text': text, 'from': from, 'to': to, 'level': level}));

  Future<List<NewsItem>> news() async {
    final j = await _call('GET', '/v1/feed/news');
    return [for (final i in (j['items'] as List)) NewsItem.fromJson(Map<String, dynamic>.from(i as Map))];
  }

  Future<SimplifiedArticle> simplify(NewsItem item, {required String level, required String nativeLang}) async =>
      SimplifiedArticle.fromJson(await _call('POST', '/v1/ai/simplify', body: {'id': item.id, 'text': '${item.title}. ${item.summary}', 'level': level, 'nativeLang': nativeLang}),
          level: level);

  Future<List<Meme>> memes({required String level, required String nativeLang}) async {
    final j = await _call('GET', '/v1/feed/memes?level=$level&lang=$nativeLang&count=5');
    return [for (final m in (j['memes'] as List)) Meme.fromJson(Map<String, dynamic>.from(m as Map), level: level)];
  }

  Future<void> feedback(String id, int rating) async {
    await _call('POST', '/v1/feedback', body: {'id': id, 'rating': rating});
  }
}
