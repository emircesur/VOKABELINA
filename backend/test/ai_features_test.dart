import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';
import 'package:vokabelina_server/src/bandit.dart';
import 'package:vokabelina_server/src/config.dart';
import 'package:vokabelina_server/src/server.dart';
import 'package:vokabelina_server/src/store.dart';

/// Fake Anthropic: answers according to which prompt it receives and records every system prompt.
class FakeLlm {
  final systems = <String>[];
  final bodies = <Map<String, dynamic>>[];
  int calls = 0;
  bool breakJsonOnce = false;

  http.Response _reply(Object o) => http.Response(
      jsonEncode({
        'content': [
          {'type': 'text', 'text': o is String ? o : jsonEncode(o)}
        ],
        'usage': {'input_tokens': 100, 'output_tokens': 20},
      }),
      200,
      headers: {'content-type': 'application/json'});

  Future<http.Response> handle(http.Request req) async {
    if (req.url.path.endsWith('/images/generations')) {
      return http.Response(jsonEncode({'data': [{'b64_json': base64Encode([137, 80, 78, 71, 1, 2, 3])}]}), 200);
    }
    calls++;
    final b = jsonDecode(req.body) as Map<String, dynamic>;
    bodies.add(b);
    final sys = '${b['system']}';
    systems.add(sys);
    if (breakJsonOnce) {
      breakJsonOnce = false;
      return _reply('Sorry, here you go: not json');
    }
    if (sys.contains('long-term memory of a language tutor')) {
      return _reply({
        'summary': 'Ayşe is a nurse from Izmir who loves football.',
        'facts': [
          {'text': 'works as a nurse', 'category': 'work'}
        ],
        'interests': ['football'],
        'goals': ['pass the B1 exam'],
        'mistakeTags': [
          {'tag': 'verb conjugation', 'explanation': 'ich gehe, not ich gehen'}
        ],
        'episode': {'summary': 'Talked about a football match in Hamburg.', 'topics': ['football', 'Hamburg']},
        'estimatedLevel': 'A2',
        'focus': ['verb endings in present tense'],
      });
    }
    if (sys.contains('word coach')) {
      return _reply({'mnemonic': 'Tisch sounds like "dish" — a dish stands on the table.', 'examples': [{'text': 'Der Tisch ist rund.', 'translation': 'Masa yuvarlak.'}], 'notes': 'der Tisch, die Tische', 'related': [{'de': 'der Stuhl', 'en': 'chair', 'tr': 'sandalye'}], 'imagePrompt': 'a wooden table'});
    }
    if (sys.contains('answer judge')) return _reply({'accepted': true, 'explanation': 'Synonym.'});
    if (sys.contains('gap-fill')) {
      return _reply({'items': [{'sentence': 'Ich fahre mit ___ Bus.', 'answer': 'dem', 'options': ['den', 'der'], 'translation': 'Otobüsle gidiyorum.', 'hint': 'mit + Dativ'}, {'sentence': 'no gap here', 'answer': 'x', 'options': []}]});
    }
    if (sys.contains('graded-reader')) {
      return _reply({'title': 'Der Bus', 'text': 'Ali wartet auf den Bus.', 'translation': 'Ali otobüsü bekliyor.', 'glossary': [], 'questions': [{'question': 'Wer wartet?', 'options': ['Ali', 'Tom', 'Eva'], 'answer': 0}]});
    }
    if (sys.contains('correct short texts')) {
      return _reply({'score': 72, 'corrected': 'Ich gehe nach Hause.', 'items': [{'original': 'ich gehen', 'corrected': 'ich gehe', 'explanation': '-e', 'tag': 'verb conjugation'}], 'praise': 'Gut!', 'tip': 'Endungen', 'level': 'A1', 'newWords': []});
    }
    if (sys.contains('explain') && sys.contains('grammar')) {
      return _reply({'title': 'Dativ', 'explanation': 'mit + Dativ', 'examples': [{'text': 'mit dem Bus', 'translation': 'otobüsle'}]});
    }
    // chat
    return _reply({
      'reply': 'Schön! Was machst du gern?',
      'replyNative': 'Güzel!',
      'corrections': [
        {'original': 'ich gehen', 'corrected': 'ich gehe', 'explanation': '-e', 'tag': 'verb conjugation'}
      ],
      'newWords': [],
      'usedKnownWords': [],
      'suggestions': [],
      'newFacts': [],
      'mood': 'happy'
    });
  }
}

VokabelinaServer _server(FakeLlm llm, {Directory? dir}) {
  final store = Store(dir);
  store.config.provider('anthropic')!.apiKey = 'sk-test-1234567890';
  return VokabelinaServer(store: store, httpClient: MockClient(llm.handle), adminToken: 'adm');
}

Future<Response> _call(VokabelinaServer s, String method, String path, {Object? body, String? bearer}) {
  final req = Request(method, Uri.parse('http://x$path'), body: body == null ? null : jsonEncode(body), headers: {if (bearer != null) 'authorization': 'Bearer $bearer'});
  return Future.sync(() => s.handler(req));
}

Future<Map<String, dynamic>> _json(Response r) async => jsonDecode(await r.readAsString()) as Map<String, dynamic>;

Future<String> _token(VokabelinaServer s, [String id = 'device-12345678']) async =>
    (await _json(await _call(s, 'POST', '/v1/auth/register', body: {'deviceId': id})))['token'] as String;

Map<String, dynamic> _chatBody(String text, {String target = 'de'}) => {
      'level': 'A2',
      'nativeLang': 'tr',
      'targetLang': target,
      'persona': 'bruno',
      'memory': {'known': [], 'weak': []},
      'messages': [
        {'role': 'user', 'content': text}
      ],
    };

void main() {
  test('chat teaches the requested target language and honours role-play scenarios', () async {
    final llm = FakeLlm();
    final s = _server(llm);
    final t = await _token(s);
    await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: {
      ..._chatBody('Hello', target: 'en'),
      'scenario': 'You are a waiter in a café.',
      'messages': [
        {'role': 'assistant', 'content': 'Hi! What would you like?'},
        {'role': 'user', 'content': 'A coffee please'}
      ],
    });
    expect(llm.systems.last, allOf(contains('learning English'), contains('ROLE-PLAY: You are a waiter'), contains('Turkish')));
    // Anthropic needs the first message to be from the user: the tutor opener is dropped
    expect(((llm.bodies.last['messages'] as List).first as Map)['role'], 'user');
    // target == native falls back to German
    await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: {..._chatBody('Hallo'), 'nativeLang': 'en', 'targetLang': 'en'});
    expect(llm.systems.last, contains('learning German'));
  });

  test('server memory: chat turns are consolidated in the background and recalled in later prompts', () async {
    final llm = FakeLlm();
    final s = _server(llm);
    s.memory.toString(); // ensure created
    final t = await _token(s);
    for (var i = 0; i < 8; i++) {
      await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: _chatBody('Ich war beim Fußball in Hamburg $i'));
    }
    await s.idle;
    expect(llm.systems.where((x) => x.contains('long-term memory of a language tutor')), hasLength(1));
    final hash = VokabelinaServer.deviceHash('device-12345678');
    final m = s.memory.publicView(hash);
    expect(m['summary'], contains('nurse'));
    expect((m['episodes'] as List).single['t'], ['football', 'Hamburg']);
    expect(m['estimatedLevel'], 'A2');

    // a related message retrieves the episode + profile into the chat prompt
    await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: _chatBody('Morgen spiele ich wieder Football'));
    expect(llm.systems.last, allOf(contains('LONG-TERM MEMORY'), contains('football match in Hamburg'), contains('nurse from Izmir')));

    // opting out keeps the prompt free of server memory
    await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: {..._chatBody('Hallo'), 'cloudMemory': false});
    expect(llm.systems.last, isNot(contains('LONG-TERM MEMORY')));
  });

  test('memory sync merges app facts and returns the consolidated view; delete forgets everything', () async {
    final llm = FakeLlm();
    final s = _server(llm);
    final t = await _token(s);
    await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: _chatBody('Ich bin Krankenschwester'));
    final res = await _json(await _call(s, 'POST', '/v1/memory/sync', bearer: t, body: {
      'level': 'A2',
      'nativeLang': 'tr',
      'targetLang': 'de',
      'memory': {
        'facts': [
          {'t': 'has a cat', 'c': 'personal'}
        ],
        'interests': ['cooking']
      },
    }));
    expect((res['facts'] as List).map((f) => f['text']), containsAll(['has a cat', 'works as a nurse']));
    expect(res['interests'], containsAll(['cooking', 'football']));
    expect(res['summary'], isNotEmpty);

    final del = await _json(await _call(s, 'POST', '/v1/memory/delete', bearer: t));
    expect(del['removedLogEntries'], greaterThan(0));
    final hash = VokabelinaServer.deviceHash('device-12345678');
    expect(s.memory.publicView(hash)['summary'], '');
    expect(s.store.readLog().where((e) => e['device'] == hash), isEmpty);
  });

  test('prompt bandit: feedback shifts traffic to the preferred teaching style', () async {
    final store = Store(null);
    final bandit = PromptBandit(store, rng: Random(3));
    final vs = [PromptVariant(id: 'a', text: 'A'), PromptVariant(id: 'b', text: 'B'), PromptVariant(id: 'off', text: 'X', enabled: false)];
    for (var i = 0; i < 30; i++) {
      bandit.reward('a', -1);
      bandit.reward('b', 1);
    }
    var b = 0;
    for (var i = 0; i < 100; i++) {
      final v = bandit.choose('chat', vs)!;
      expect(v.id, isNot('off'));
      if (v.id == 'b') b++;
    }
    expect(b, greaterThan(95));
    final report = bandit.report(vs);
    expect(report.firstWhere((r) => r['id'] == 'b')['winRate'], greaterThan(0.9));
  });

  test('thumbs on a chat reply reward the variant that produced it', () async {
    final llm = FakeLlm();
    final s = _server(llm);
    s.store.config.variants
      ..clear()
      ..add(PromptVariant(id: 'only', text: 'Be brief.'));
    final t = await _token(s);
    final r = await _json(await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: _chatBody('Hallo')));
    expect(llm.systems.last, contains('Teaching style for this reply: Be brief.'));
    await _call(s, 'POST', '/v1/feedback', bearer: t, body: {'id': r['id'], 'rating': 1});
    expect(s.bandit.report(s.store.config.variants).single['up'], 1);
  });

  test('JSON repair: a broken model reply is retried once and usage is tracked', () async {
    final llm = FakeLlm()..breakJsonOnce = true;
    final s = _server(llm);
    final t = await _token(s);
    final r = await _call(s, 'POST', '/v1/ai/grammar', bearer: t, body: {'level': 'A2', 'nativeLang': 'tr', 'targetLang': 'de', 'topic': 'Dativ'});
    expect(r.statusCode, 200);
    expect((await _json(r))['explanation'], 'mit + Dativ');
    expect(llm.calls, 2);
    expect(llm.systems.last, contains('Output ONLY one valid JSON object'));
    final usage = s.usage.report();
    expect(usage.single['key'], 'anthropic/claude-haiku-5-5/grammar');
    expect((usage.single['calls'], usage.single['in'], usage.single['out']), (2, 200, 40));
  });

  test('word coach is cached for everybody; judge, practice, story and writing endpoints', () async {
    final llm = FakeLlm();
    final s = _server(llm);
    final t = await _token(s);
    final body = {'level': 'A1', 'nativeLang': 'tr', 'targetLang': 'de', 'word': {'de': 'der Tisch', 'en': 'table', 'tr': 'masa', 'plural': 'Tische'}};
    final w1 = await _json(await _call(s, 'POST', '/v1/ai/word', bearer: t, body: body));
    final t2 = await _token(s, 'device-other-0001');
    final w2 = await _json(await _call(s, 'POST', '/v1/ai/word', bearer: t2, body: body));
    expect(w1['mnemonic'], contains('dish'));
    expect(w2, w1);
    expect(llm.systems.where((x) => x.contains('word coach')), hasLength(1));

    final j = await _json(await _call(s, 'POST', '/v1/ai/judge', bearer: t, body: {'targetLang': 'en', 'nativeLang': 'tr', 'prompt': 'merhaba', 'expected': 'hello', 'answer': 'hi'}));
    expect(j['accepted'], isTrue);

    final p = await _json(await _call(s, 'POST', '/v1/ai/practice', bearer: t, body: {'targetLang': 'de', 'nativeLang': 'tr', 'level': 'A2', 'words': ['der Bus'], 'mistakes': ['dative']}));
    final items = p['items'] as List;
    expect(items, hasLength(1)); // the item without a gap is dropped
    expect(items.single['options'], containsAll(['dem', 'den', 'der']));
    expect(llm.systems.last, contains('Turkish'));

    final st = await _json(await _call(s, 'POST', '/v1/ai/story', bearer: t, body: {'targetLang': 'de', 'nativeLang': 'tr', 'level': 'A1', 'words': ['der Bus']}));
    expect((st['questions'] as List).single['answer'], 0);

    final wr = await _json(await _call(s, 'POST', '/v1/ai/check', bearer: t, body: {'targetLang': 'de', 'nativeLang': 'tr', 'level': 'A1', 'task': 'Dein Tag', 'text': 'ich gehen nach Hause'}));
    expect(wr['score'], 72);
    expect((wr['items'] as List).single['tag'], 'verb conjugation');
  });

  test('AI picture cards are generated once, cached on disk and served', () async {
    final dir = Directory.systemTemp.createTempSync('vk');
    addTearDown(() => dir.deleteSync(recursive: true));
    final llm = FakeLlm();
    final s = _server(llm, dir: dir);
    s.store.config
      ..imagesEnabled = true
      ..provider('openai')!.apiKey = 'sk-openai';
    final t = await _token(s);
    final body = {'targetLang': 'de', 'nativeLang': 'tr', 'level': 'A1', 'image': true, 'word': {'de': 'der Tisch', 'en': 'table', 'tr': 'masa'}};
    final w = await _json(await _call(s, 'POST', '/v1/ai/word', bearer: t, body: body));
    final url = w['imageUrl'] as String;
    expect(url, startsWith('/v1/images/'));
    final img = await _call(s, 'GET', url);
    expect(img.statusCode, 200);
    expect(img.headers['content-type'], 'image/png');
    expect(await img.read().expand((x) => x).toList(), [137, 80, 78, 71, 1, 2, 3]);
    expect((await _call(s, 'GET', '/v1/images/../../config.json')).statusCode, 404);
  });

  test('admin insights aggregate mistake tags, levels, variants and usage; KTO export labels ratings', () async {
    final llm = FakeLlm();
    final s = _server(llm);
    final t = await _token(s);
    final ids = <String>[];
    for (final text in ['eins', 'zwei']) {
      ids.add((await _json(await _call(s, 'POST', '/v1/ai/chat', bearer: t, body: _chatBody(text))))['id'] as String);
    }
    await _call(s, 'POST', '/v1/feedback', bearer: t, body: {'id': ids[0], 'rating': 1});
    await _call(s, 'POST', '/v1/feedback', bearer: t, body: {'id': ids[1], 'rating': -1});
    final ins = await _json(await _call(s, 'GET', '/admin/api/insights', bearer: 'adm'));
    expect(ins['learners'], 1);
    expect((ins['topMistakeTags'] as List).first, {'tag': 'verb conjugation', 'count': 2});
    expect(ins['chatTurnsByLevel'], {'A2': 2});
    expect((ins['usage'] as List).single['calls'], 2);
    final kto = (await (await _call(s, 'GET', '/admin/api/export-kto.jsonl', bearer: 'adm')).readAsString()).trim().split('\n');
    expect([for (final l in kto) (jsonDecode(l) as Map)['label']], [true, false]);
    // admin cannot read memory content through insights
    expect(jsonEncode(ins), isNot(contains('eins')));
  });

  test('configs from older versions: new tasks inherit the chat route', () {
    final old = {
      'providers': [
        {'id': 'groq', 'name': 'Groq', 'kind': 'openai', 'baseUrl': 'https://api.groq.com/openai/v1', 'apiKey': 'k'}
      ],
      'routes': [
        {'task': 'chat', 'providerId': 'groq', 'model': 'llama-3.3-70b'}
      ],
    };
    final c = ServerConfig.fromJson(old);
    expect(c.route('word').providerId, 'groq');
    expect(c.route('memory').model, 'llama-3.3-70b');
    expect(c.route('image').providerId, '');
    expect(c.variants, isNotEmpty);
    expect(AiRoute.tasks.every((t) => AiRoute.descriptions.containsKey(t)), isTrue);
  });
}
