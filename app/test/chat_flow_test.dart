import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vokabelina/data/curriculum.dart';
import 'package:vokabelina/data/models.dart';
import 'package:vokabelina/services/lessons.dart';
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
          {'original': 'ich gehen', 'corrected': 'ich gehe', 'explanation': 'ich → -e', 'tag': 'verb conjugation'}
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
    expect(sent['targetLang'], 'de');
    expect((sent['memory'] as Map).keys, containsAll(['known', 'weak', 'mistakes', 'facts', 'interests', 'goals']));

    // reinforcement: "gehen" was corrected (failure); "Brot" used correctly (success)
    final cards = c.read(deckProvider).forLang('de');
    expect(cards['gehen']!.failures, 1);
    expect(cards['gehen']!.successes, 0);
    expect(cards['das_brot']!.successes, 1);
    final mistake = c.read(memoryProvider).mistakes['de|verb conjugation']!;
    expect((mistake.count, mistake.explanation), (1, 'ich → -e'));
    expect(mistake.examples, ['ich gehen → ich gehe']);
    expect(c.read(memoryProvider).facts.map((f) => f.text), ['lives in Berlin']);
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

  test('the same tutor teaches English: target language travels with the request and the deck', () async {
    late Map<String, dynamic> sent;
    final client = MockClient((req) async {
      if (req.url.path == '/v1/auth/register') return _json({'token': 'tok'});
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return _json({'id': 'e1', 'reply': 'Nice! Where do you live?', 'usedKnownWords': ['table'], 'mood': 'happy'});
    });
    final c = await _container(client);
    c.read(profileProvider.notifier).setTarget('en');
    c.read(deckProvider.notifier).add([c.read(deckProvider).words['der_tisch']!]);
    await c.read(chatProvider.notifier).send('The table is big');
    expect(sent['targetLang'], 'en');
    expect(c.read(deckProvider).forLang('en')['der_tisch']!.successes, 1);
    expect(c.read(deckProvider).forLang('de'), isEmpty);
    expect(c.read(sharedPrefsProvider).getString('chat_en'), isNotNull);
  });

  test('old decks (no language) migrate to German; lesson outcomes schedule cards', () async {
    SharedPreferences.setMockInitialValues({
      'deck': jsonEncode({
        'words': [],
        'cards': [
          {'w': 'der_tisch', 'e': 2.5, 'i': 0, 'r': 0, 'l': 0, 'd': '2026-10-01T00:00:00.000'}
        ]
      }),
      'memory': jsonEncode({'facts': ['likes tea'], 'mistakes': {'dative after mit': 2}}),
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs), clockProvider.overrideWithValue(() => DateTime(2026, 10, 22, 12))]);
    expect(c.read(deckProvider).cards.keys, ['de:der_tisch']);
    final mem = c.read(memoryProvider);
    expect(mem.facts.single.text, 'likes tea');
    expect(mem.mistakes.values.single.count, 2);

    c.read(deckProvider.notifier).learnFromLesson({'der_tisch': (ok: 2, bad: 0), 'der_stuhl': (ok: 1, bad: 1)});
    final cards = c.read(deckProvider).forLang('de');
    expect(cards['der_tisch']!.reps, 1);
    expect(cards['der_tisch']!.due, DateTime(2026, 10, 23, 12));
    expect(cards['der_stuhl']!.lapses, 0);
    expect(cards['der_stuhl']!.successes, 1);
  });

  test('course progress unlocks lessons in order and units by level', () async {
    final c = await _container(MockClient((_) async => http.Response('', 500)));
    var course = c.read(courseProvider);
    final u1 = units[0], u2 = units[1];
    final l1 = lessonsFor(u1);
    expect(course.lessonUnlocked(u1, l1[0]), isTrue);
    expect(course.lessonUnlocked(u1, l1[1]), isFalse);
    expect(course.unitUnlocked(u2), isFalse);
    expect(course.next()!.$2.id, 'u01_w1');
    for (final l in l1.where((l) => l.required)) {
      c.read(progressProvider.notifier).complete(l.id, correct: 9, total: 10);
    }
    course = c.read(courseProvider);
    expect(course.unitDone(u1), isTrue);
    expect(course.unitUnlocked(u2), isTrue);
    expect(course.next()!.$2.id, 'u02_w1');
    // placement: an A2 learner can open every A1 unit
    c.read(profileProvider.notifier).update((p) => p.copyWith(level: 'A2'));
    expect(c.read(courseProvider).unitUnlocked(units.firstWhere((u) => u.id == 'u14')), isTrue);
    expect(c.read(courseProvider).unitUnlocked(units.firstWhere((u) => u.id == 'u15')), isTrue);
    expect(c.read(courseProvider).unitUnlocked(units.firstWhere((u) => u.id == 'u16')), isFalse);
    // best result is kept
    c.read(progressProvider.notifier).complete('u01_w1', correct: 3, total: 10);
    expect(c.read(progressProvider)['de:u01_w1']!.stars, 3);
  });

  test('server memory merge adds summary, episodes, categorised facts and level estimate', () async {
    final c = await _container(MockClient((_) async => http.Response('', 500)));
    c.read(memoryProvider.notifier).mergeServer({
      'summary': 'Nurse from Izmir, loves football.',
      'estimatedLevel': 'A2',
      'focus': ['dative after mit'],
      'interests': ['football'],
      'goals': ['pass B1 exam'],
      'facts': [
        {'text': 'works as a nurse', 'category': 'work'}
      ],
      'episodes': [
        {'d': '2026-10-20T10:00:00.000', 's': 'Talked about the weekend in Hamburg', 't': ['travel']}
      ],
    });
    final m = c.read(memoryProvider);
    expect(m.summary, contains('Nurse'));
    expect(m.estimatedLevel, 'A2');
    expect(m.facts.single.category, 'work');
    expect(m.episodes.single.topics, ['travel']);
    expect(c.read(learnerProvider).toPayload()['summary'], contains('Nurse'));
  });
}
