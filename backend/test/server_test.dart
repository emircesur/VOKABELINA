import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:vokabelina_server/src/ai.dart';
import 'package:vokabelina_server/src/config.dart';
import 'package:vokabelina_server/src/feeds.dart';
import 'package:vokabelina_server/src/server.dart';
import 'package:vokabelina_server/src/store.dart';

const _chatJson = '{"reply":"Hallo! Wie geht es dir?","replyNative":"Merhaba!","corrections":[],'
    '"newWords":[{"de":"das Wetter","en":"weather","tr":"hava"}],"usedKnownWords":["Hallo"],"suggestions":["Gut!"],"mood":"cheer"}';

VokabelinaServer _server(MockClient client, {bool withKey = true}) {
  final store = Store(null);
  if (withKey) store.config.provider('anthropic')!.apiKey = 'sk-test-1234567890';
  return VokabelinaServer(store: store, httpClient: client, adminToken: 'adm', adminWebDir: 'web');
}

Future<Response> _call(VokabelinaServer s, String method, String path, {Object? body, String? bearer}) {
  final req = Request(method, Uri.parse('http://x$path'),
      body: body == null ? null : jsonEncode(body), headers: {if (bearer != null) 'authorization': 'Bearer $bearer'});
  return Future.sync(() => s.handler(req));
}

Future<String> _token(VokabelinaServer s) async {
  final r = await _call(s, 'POST', '/v1/auth/register', body: {'deviceId': 'device-12345678'});
  return (jsonDecode(await r.readAsString()) as Map)['token'] as String;
}

void main() {
  group('extractJsonObject', () {
    test('handles fences, chatter and braces inside strings', () {
      final m = extractJsonObject('Sure!\n```json\n{"a":"x } y","b":{"c":1}}\n```');
      expect(m, {'a': 'x } y', 'b': {'c': 1}});
    });
    test('returns null on garbage', () {
      expect(extractJsonObject('no json'), isNull);
      expect(extractJsonObject('{"a": '), isNull);
    });
  });

  group('auth', () {
    test('rejects missing / tampered tokens', () async {
      final s = _server(MockClient((_) async => http.Response('', 500)));
      expect((await _call(s, 'POST', '/v1/ai/chat', body: {})).statusCode, 401);
      final t = await _token(s);
      expect((await _call(s, 'POST', '/v1/ai/chat', body: {}, bearer: '${t}x')).statusCode, 401);
    });
    test('admin is disabled without token and needs the right token', () async {
      final store = Store(null);
      final off = VokabelinaServer(store: store, httpClient: MockClient((_) async => http.Response('', 500)));
      expect((await _call(off, 'GET', '/admin/api/config')).statusCode, 503);
      final on = _server(MockClient((_) async => http.Response('', 500)));
      expect((await _call(on, 'GET', '/admin/api/config', bearer: 'nope')).statusCode, 401);
      expect((await _call(on, 'GET', '/admin/api/config', bearer: 'adm')).statusCode, 200);
    });
  });

  group('chat', () {
    test('calls Anthropic with key header and returns normalized result', () async {
      late http.Request seen;
      final s = _server(MockClient((req) async {
        seen = req;
        return http.Response(
            jsonEncode({'content': [{'type': 'text', 'text': 'Here you go: $_chatJson'}]}), 200,
            headers: {'content-type': 'application/json'});
      }));
      final t = await _token(s);
      final r = await _call(s, 'POST', '/v1/ai/chat',
          bearer: t,
          body: {
            'level': 'A2',
            'persona': 'fuchs',
            'nativeLang': 'tr',
            'memory': {'known': ['Hallo'], 'weak': ['der Tisch']},
            'messages': [{'role': 'user', 'content': 'Hallo!'}],
          });
      expect(r.statusCode, 200);
      final j = jsonDecode(await r.readAsString()) as Map;
      expect(j['reply'], 'Hallo! Wie geht es dir?');
      expect(j['mood'], 'cheer');
      expect((j['newWords'] as List).single['tr'], 'hava');
      expect(seen.headers['x-api-key'], 'sk-test-1234567890');
      final sent = jsonDecode(seen.body) as Map;
      expect(sent['system'], allOf(contains('Frau Fuchs'), contains('CEFR A2'), contains('der Tisch'), contains('Turkish')));
    });

    test('falls back to the second provider when the first fails', () async {
      final calls = <String>[];
      final s = _server(MockClient((req) async {
        calls.add(req.url.host);
        if (req.url.host == 'api.anthropic.com') return http.Response('overloaded', 529);
        return http.Response(jsonEncode({'choices': [{'message': {'content': _chatJson}}]}), 200);
      }));
      s.store.config.provider('openai')!.apiKey = 'sk-openai';
      s.store.config.route('chat')
        ..fallbackProviderId = 'openai'
        ..fallbackModel = 'gpt-4o-mini';
      final r = await _call(s, 'POST', '/v1/ai/chat',
          bearer: await _token(s), body: {'messages': [{'role': 'user', 'content': 'Hi'}]});
      expect(r.statusCode, 200);
      expect(calls, ['api.anthropic.com', 'api.openai.com']);
      expect((jsonDecode(await r.readAsString()) as Map)['model'], 'openai/gpt-4o-mini');
    });

    test('plain-text model output degrades gracefully', () async {
      final s = _server(MockClient((_) async => http.Response(jsonEncode({'content': [{'type': 'text', 'text': 'Hallo zusammen'}]}), 200)));
      final r = await _call(s, 'POST', '/v1/ai/chat', bearer: await _token(s), body: {'messages': [{'role': 'user', 'content': 'x'}]});
      expect((jsonDecode(await r.readAsString()) as Map)['reply'], 'Hallo zusammen');
    });

    test('503 no_provider when nothing is configured; 400 when last msg is not user', () async {
      final s = _server(MockClient((_) async => http.Response('', 500)), withKey: false);
      final t = await _token(s);
      expect((await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: {'messages': [{'role': 'user', 'content': 'x'}]})).statusCode, 503);
      expect((await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: {'messages': [{'role': 'assistant', 'content': 'x'}]})).statusCode, 400);
    });

    test('global per-minute and daily budgets stop token-minting abuse', () async {
      final s = _server(MockClient((_) async => http.Response(jsonEncode({'content': [{'type': 'text', 'text': _chatJson}]}), 200)));
      s.store.config
        ..rateLimitPerMinute = 100
        ..globalAiPerMinute = 3
        ..dailyAiLimit = 100;
      // three different devices share the global budget
      final codes = <int>[];
      for (var i = 0; i < 5; i++) {
        final r = await _call(s, 'POST', '/v1/auth/register', body: {'deviceId': 'device-abcdef0$i'});
        final t = (jsonDecode(await r.readAsString()) as Map)['token'] as String;
        codes.add((await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: {'messages': [{'role': 'user', 'content': 'x'}]})).statusCode);
      }
      expect(codes, [200, 200, 200, 429, 429]);

      final d = _server(MockClient((_) async => http.Response(jsonEncode({'content': [{'type': 'text', 'text': _chatJson}]}), 200)));
      d.store.config
        ..rateLimitPerMinute = 100
        ..dailyAiLimit = 1;
      final t = await _token(d);
      final body = {'messages': [{'role': 'user', 'content': 'x'}]};
      expect((await _call(d, 'POST', '/v1/ai/chat', bearer: t, body: body)).statusCode, 200);
      final over = await _call(d, 'POST', '/v1/ai/chat', bearer: t, body: body);
      expect(over.statusCode, 429);
      expect((jsonDecode(await over.readAsString()) as Map)['error'], 'daily_budget_exhausted');
    });

    test('registration is rate limited per IP', () async {
      final s = _server(MockClient((_) async => http.Response('', 500)));
      final codes = <int>[];
      for (var i = 0; i < 12; i++) {
        final req = Request('POST', Uri.parse('http://x/v1/auth/register'), body: jsonEncode({'deviceId': 'device-1234567$i'}), headers: {'x-forwarded-for': '1.2.3.4, 9.9.9.9'});
        codes.add((await s.handler(req)).statusCode);
      }
      expect(codes.where((c) => c == 200), hasLength(10));
      expect(codes.last, 429);
      // a different client behind the proxy is unaffected
      final other = Request('POST', Uri.parse('http://x/v1/auth/register'), body: jsonEncode({'deviceId': 'device-7654321x'}), headers: {'x-forwarded-for': '1.2.3.4, 8.8.8.8'});
      expect((await s.handler(other)).statusCode, 200);
    });

    test('rate limiter blocks bursts', () async {
      final s = _server(MockClient((_) async => http.Response(jsonEncode({'content': [{'type': 'text', 'text': _chatJson}]}), 200)));
      s.store.config.rateLimitPerMinute = 2;
      final t = await _token(s);
      final codes = [
        for (var i = 0; i < 3; i++)
          (await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: {'messages': [{'role': 'user', 'content': 'x'}]})).statusCode
      ];
      expect(codes, [200, 200, 429]);
    });
  });

  group('admin', () {
    test('masks keys and keeps the stored key when a masked value is sent back', () async {
      final s = _server(MockClient((_) async => http.Response('', 500)));
      final get = jsonDecode(await (await _call(s, 'GET', '/admin/api/config', bearer: 'adm')).readAsString()) as Map<String, dynamic>;
      final anth = (get['providers'] as List).firstWhere((p) => p['id'] == 'anthropic') as Map;
      expect(anth['apiKey'], contains('••••'));
      expect(anth['apiKey'], isNot(contains('1234567890')));
      anth['name'] = 'Claude';
      final put = await _call(s, 'PUT', '/admin/api/config', bearer: 'adm', body: get);
      expect(put.statusCode, 200);
      expect(s.store.config.provider('anthropic')!.apiKey, 'sk-test-1234567890');
      expect(s.store.config.provider('anthropic')!.name, 'Claude');
    });
    test('a new key replaces the stored one', () {
      final c = ServerConfig.defaults();
      c.applyAdminUpdate({'providers': [{'id': 'anthropic', 'name': 'A', 'kind': 'anthropic', 'apiKey': 'sk-new'}]});
      expect(c.provider('anthropic')!.apiKey, 'sk-new');
      expect(c.routes.map((r) => r.task), containsAll(AiRoute.tasks));
    });
    test('export contains only thumbs-up chats in chat format', () async {
      final s = _server(MockClient((_) async => http.Response(jsonEncode({'content': [{'type': 'text', 'text': _chatJson}]}), 200)));
      final t = await _token(s);
      final ids = <String>[];
      for (final text in ['one', 'two']) {
        final r = await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: {'messages': [{'role': 'user', 'content': text}]});
        ids.add((jsonDecode(await r.readAsString()) as Map)['id'] as String);
      }
      await _call(s, 'POST', '/v1/feedback', bearer: t, body: {'id': ids[0], 'rating': 1});
      await _call(s, 'POST', '/v1/feedback', bearer: t, body: {'id': ids[1], 'rating': -1});
      final out = await (await _call(s, 'GET', '/admin/api/export.jsonl', bearer: 'adm')).readAsString();
      final lines = out.trim().split('\n');
      expect(lines, hasLength(1));
      final ex = jsonDecode(lines.single) as Map;
      expect((ex['messages'] as List).first['content'], 'one');
      expect((ex['messages'] as List).last['role'], 'assistant');
    });
  });

  group('feeds', () {
    test('parses RSS 2.0 with RFC822 dates and strips html', () {
      const xml = '''<?xml version="1.0"?><rss version="2.0"><channel>
        <item><title>Bahn &amp; Streik</title><link>https://ex.de/1</link>
        <description>&lt;p&gt;Die Bahn <b>streikt</b>.&lt;/p&gt;</description>
        <pubDate>Wed, 22 Oct 2026 10:00:00 +0200</pubDate></item></channel></rss>''';
      final items = parseFeed(xml, 'Test');
      expect(items.single.title, 'Bahn & Streik');
      expect(items.single.summary, 'Die Bahn streikt.');
      expect(items.single.published, DateTime.utc(2026, 10, 22, 8));
    });
    test('one broken source does not break the feed', () async {
      final svc = FeedService(
        MockClient((req) async => req.url.host == 'bad.de'
            ? http.Response('x', 500)
            : http.Response('<rss><channel><item><title>A</title><link>l</link></item></channel></rss>', 200)),
        () => [FeedSource(name: 'bad', url: 'https://bad.de/rss'), FeedSource(name: 'good', url: 'https://good.de/rss')],
      );
      expect((await svc.news()).map((n) => n.title), ['A']);
    });
  });
}
