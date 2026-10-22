import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vokabelina/data/models.dart';
import 'package:vokabelina/state/providers.dart';

Future<ProviderContainer> _container(MockClient client, {String serverUrl = 'http://test'}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    sharedPrefsProvider.overrideWithValue(prefs),
    httpClientProvider.overrideWithValue(client),
    clockProvider.overrideWithValue(() => DateTime(2026, 10, 22, 12)),
  ]);
  c.read(profileProvider.notifier).set(Profile(onboarded: true, level: 'A1', nativeLang: 'tr', serverUrl: serverUrl));
  c.read(deckProvider.notifier).add(c.read(deckProvider.notifier).newWordsFor('A1', 0));
  return c;
}

http.Response _json(Object o, [int status = 200]) => http.Response(jsonEncode(o), status, headers: {'content-type': 'application/json'});

void main() {
  test('AI reply feeds the learner model: corrections, facts, new words, rewards', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((req) async {
      if (req.url.path == '/v1/auth/register') return _json({'token': 'tok'});
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      expect(req.headers['authorization'], 'Bearer tok');
      return _json({
        'id': 'm1',
        'reply': 'Super! Was machst du beruflich?',
        'replyNative': 'Harika! Mesleğin ne?',
        'corrections': [
          {'original': 'ich gehen', 'corrected': 'ich gehe', 'explanation': 'Verb conjugation: ich → -e'}
        ],
        'newWords': [
          {'de': 'der Beruf', 'en': 'profession', 'tr': 'meslek'}
        ],
        'usedKnownWords': ['Brot'],
        'suggestions': ['Ich bin Lehrerin.'],
        'newFacts': ['lives in Berlin'],
        'mood': 'cheer',
      });
    });
    final c = await _container(client);
    final deck = c.read(deckProvider.notifier);
    deck.add(c.read(deckProvider).words.values.where((w) => ['gehen', 'das_brot'].contains(w.id)));

    await c.read(chatProvider.notifier).send('ich gehen zum Brot');

    final chat = c.read(chatProvider);
    expect(chat.messages.map((m) => m.fromUser), [true, false]);
    expect(chat.messages.last.newWords.single.de, 'der Beruf');
    expect(chat.messages.last.suggestions, ['Ich bin Lehrerin.']);
    expect(chat.notice, isNull);
    expect(chat.mood, 'cheer');

    // request carried level, persona, native language and the memory payload
    expect(sent['level'], 'A1');
    expect(sent['nativeLang'], 'tr');
    expect(sent['persona'], 'bruno');
    expect((sent['memory'] as Map).keys, containsAll(['known', 'weak', 'mistakes', 'facts']));

    // reinforcement: "gehen" was corrected (failure); "Brot" used correctly (success)
    final cards = c.read(deckProvider).cards;
    expect(cards['gehen']!.failures, 1);
    expect(cards['gehen']!.successes, 0);
    expect(cards['das_brot']!.successes, 1);
    expect(c.read(memoryProvider).mistakes, {'Verb conjugation: ich → -e': 1});
    expect(c.read(memoryProvider).facts, ['lives in Berlin']);
    expect(c.read(profileProvider).xp, 4);
  });

  test('falls back to offline tutor when the server has no AI key', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/v1/auth/register') return _json({'token': 'tok'});
      return _json({'error': 'no_provider', 'message': 'No AI provider configured.'}, 503);
    });
    final c = await _container(client);
    await c.read(chatProvider.notifier).send('Hallo');
    final chat = c.read(chatProvider);
    expect(chat.notice, 'noProvider');
    expect(chat.messages.last.offline, isTrue);
    expect(chat.messages.last.text, isNotEmpty);
    expect(chat.sending, isFalse);
  });

  test('offline tutor without any server configured', () async {
    final c = await _container(MockClient((_) async => http.Response('', 500)), serverUrl: '');
    await c.read(chatProvider.notifier).send('Hallo');
    expect(c.read(chatProvider).notice, 'notConfigured');
    expect(c.read(chatProvider).messages, hasLength(2));
  });

  test('chat history survives a restart and thumbs ratings persist', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/v1/auth/register') return _json({'token': 'tok'});
      if (req.url.path == '/v1/feedback') return _json({'ok': true});
      return _json({'id': 'm9', 'reply': 'Hallo!', 'mood': 'happy'});
    });
    final c = await _container(client);
    await c.read(chatProvider.notifier).send('Hi');
    await c.read(chatProvider.notifier).rate('m9', 1);
    final prefs = c.read(sharedPrefsProvider);

    final c2 = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    final restored = c2.read(chatProvider).messages;
    expect(restored.map((m) => m.text), ['Hi', 'Hallo!']);
    expect(restored.last.rating, 1);
  });
}
