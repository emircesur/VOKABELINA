part of 'server.dart';

extension LearningRoutes on VokabelinaServer {
  Future<Response> _chat(Request req, String deviceId) async {
    final b = await _body(req);
    final c = VokabelinaServer._ctx(b);
    final persona = personas.containsKey(b['persona']) ? '${b['persona']}' : 'bruno';
    final scenario = '${b['scenario'] ?? ''}'.trim();
    final cloud = b['cloudMemory'] != false;
    final raw = (b['messages'] as List? ?? []).takeLast(20);
    final turns = [
      for (final m in raw) ChatTurn((m as Map)['role'] == 'assistant' ? 'assistant' : 'user', '${m['content']}'.trim()),
    ].where((t) => t.content.isNotEmpty).toList();
    if (turns.isEmpty || turns.last.role != 'user') return errorResponse(400, 'bad_request', 'Last message must be from the user.');
    // Anthropic requires the conversation to start with the user: drop a leading tutor opener.
    while (turns.isNotEmpty && turns.first.role == 'assistant') {
      turns.removeAt(0);
    }
    final clientMemory = Map<String, dynamic>.from((b['memory'] as Map?) ?? {});
    final hash = VokabelinaServer.deviceHash(deviceId);
    final variant = bandit.choose('chat', store.config.variants);
    final longTerm = cloud ? memory.promptContext(hash, turns.last.content, lang: c.target) : '';
    try {
      final out = await ai.run(
        'chat',
        system: chatSystemPrompt(
          persona: persona,
          level: c.level,
          nativeLang: c.native,
          targetLang: c.target,
          memory: clientMemory,
          scenario: scenario,
          style: variant?.text ?? '',
          longTerm: longTerm,
        ),
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
        'device': hash,
        'level': c.level,
        'target': c.target,
        'native': c.native,
        'persona': persona,
        'variant': variant?.id,
        'scenario': scenario.isEmpty ? null : scenario,
        'model': out.used,
        'messages': [for (final t in turns) {'role': t.role, 'content': t.content}],
        'response': result,
      });
      if (variant != null) {
        if (_variantOf.length > 5000) _variantOf.remove(_variantOf.keys.first);
        _variantOf[id] = variant.id;
      }
      if (cloud && memory.noteTurn(hash)) {
        _background(() => memory.consolidate(hash, target: c.target, native: c.native, level: c.level));
      }
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
      'corrections': maps(p['corrections'], ['original', 'corrected', 'explanation', 'tag']),
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
    final from = VokabelinaServer._lng(b['from'], 'de');
    final to = VokabelinaServer._lng(b['to'], 'en');
    final level = VokabelinaServer._level(b['level']);
    final native = b['nativeLang'] == null ? null : VokabelinaServer._lng(b['nativeLang']);
    final key = 'tr|$from|$to|$level|$native|$text';
    if (_cache[key] case final hit?) return jsonResponse(hit);
    try {
      final out = await ai.run('translate',
          system: translateSystemPrompt(from: from, to: to, level: level, nativeLang: native), messages: [ChatTurn('user', text)], json: true, temperature: 0.2);
      final p = extractJsonObject(out.text);
      final res = {
        'translation': '${p?['translation'] ?? out.text.trim()}',
        'notes': '${p?['notes'] ?? ''}',
        'words': VokabelinaServer._words(p?['words']),
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
    final c = VokabelinaServer._ctx(b);
    final item = feeds.byId('${b['id'] ?? ''}');
    final text = item != null ? '${item.title}. ${item.summary}' : '${b['text'] ?? ''}'.trim();
    if (text.isEmpty || text.length > 3000) return errorResponse(400, 'bad_request', 'unknown article id or empty text');
    final key = 'simp|${sha1.convert(utf8.encode(text))}|${c.level}|${c.native}|${c.target}';
    if (_cache[key] case final hit?) return jsonResponse(hit);
    try {
      final out = await ai.runJson('simplify',
          system: simplifySystemPrompt(level: c.level, nativeLang: c.native, targetLang: c.target),
          messages: [ChatTurn('user', text)],
          temperature: 0.3,
          valid: (j) => j['text'] is String || j['german'] is String);
      final p = out.json;
      final t = '${p['text'] ?? p['german']}';
      final res = {
        'text': t,
        'german': t, // older app versions
        'translation': '${p['translation'] ?? ''}',
        'cultureNote': '${p['cultureNote'] ?? ''}',
        'keywords': VokabelinaServer._words(p['keywords']),
      };
      _remember(key, res);
      return jsonResponse(res);
    } catch (e) {
      return _aiError(e);
    }
  }

  Future<Response> _memes(Request req, String deviceId) async {
    final q = req.url.queryParameters;
    final level = VokabelinaServer._level(q['level']);
    final native = VokabelinaServer._lng(q['lang']);
    var target = VokabelinaServer._lng(q['target'], 'de');
    if (target == native) target = native == 'de' ? 'en' : 'de';
    final count = (int.tryParse(q['count'] ?? '') ?? 5).clamp(1, 8);
    final day = VokabelinaServer._today();
    final key = 'memes|$day|$level|$native|$target|$count';
    if (_cache[key] case final hit?) return jsonResponse(hit);
    try {
      final out = await ai.runJson('memes',
          system: memesSystemPrompt(level: level, nativeLang: native, count: count, targetLang: target),
          messages: [ChatTurn('user', 'Date: $day. Create today\'s memes.')],
          temperature: 0.95,
          maxTokens: 1800,
          valid: (j) => j['memes'] is List && (j['memes'] as List).isNotEmpty);
      final list = out.json['memes'] as List;
      final res = {
        'date': day,
        'memes': [
          for (var i = 0; i < list.length; i++)
            if (list[i] is Map)
              {
                'id': '$day-$level-$target-$i',
                'top': '${list[i]['top'] ?? ''}',
                'bottom': '${list[i]['bottom'] ?? ''}',
                'theme': '${list[i]['theme'] ?? ''}',
                'emoji': '${list[i]['emoji'] ?? '🥨'}',
                'explanation': '${list[i]['explanation'] ?? ''}',
                'vocab': VokabelinaServer._words(list[i]['vocab']),
              }
        ],
      };
      _remember(key, res);
      return jsonResponse(res);
    } catch (e) {
      return _aiError(e);
    }
  }

  /// Word coach (Memrise-style mnemonic, examples, notes) + optional AI picture.
  Future<Response> _word(Request req, String deviceId) async {
    final b = await _body(req);
    final c = VokabelinaServer._ctx(b);
    final w = Map<String, dynamic>.from((b['word'] as Map?) ?? {});
    final de = '${w['de'] ?? ''}'.trim(), en = '${w['en'] ?? ''}'.trim(), tr = '${w['tr'] ?? ''}'.trim();
    if ('$de$en$tr'.isEmpty) return errorResponse(400, 'bad_request', 'word missing');
    final key = 'word|$de|$en|$tr|${c.target}|${c.native}|${c.level}';
    var res = _diskCache(key);
    if (res == null) {
      try {
        final out = await ai.runJson('word',
            system: wordCoachPrompt(targetLang: c.target, nativeLang: c.native, level: c.level),
            messages: [ChatTurn('user', 'Word: German "$de", English "$en", Turkish "$tr"${w['plural'] != null && '${w['plural']}'.isNotEmpty ? ', German plural "${w['plural']}"' : ''}.')],
            temperature: 0.6,
            valid: (j) => j['mnemonic'] is String);
        final p = out.json;
        res = {
          'mnemonic': '${p['mnemonic'] ?? ''}',
          'examples': [
            for (final e in (p['examples'] as List? ?? []))
              if (e is Map) {'text': '${e['text'] ?? ''}', 'translation': '${e['translation'] ?? ''}'}
          ],
          'notes': '${p['notes'] ?? ''}',
          'related': VokabelinaServer._words(p['related']),
          'imagePrompt': '${p['imagePrompt'] ?? ''}',
        };
        _diskCachePut(key, res);
      } catch (e) {
        return _aiError(e);
      }
    }
    var imageUrl = '';
    if (b['image'] == true && store.config.imagesEnabled) {
      imageUrl = await _ensureImage(en.isNotEmpty ? en : de, '${res['imagePrompt'] ?? ''}');
    }
    return jsonResponse({...res, 'imageUrl': imageUrl});
  }

  /// One picture per concept, generated once and shared by every learner.
  Future<String> _ensureImage(String concept, String prompt) async {
    final name = '${sha1.convert(utf8.encode(concept.toLowerCase())).toString().substring(0, 16)}.png';
    final f = store.blobFile('images/$name');
    if (f == null) return '';
    if (f.existsSync()) return '/v1/images/$name';
    final route = store.config.route('image');
    final p = store.config.provider(route.providerId);
    if (p == null || !p.enabled) return '';
    try {
      final bytes = await client.image(
          p, route.model.isEmpty ? 'gpt-image-1' : route.model, 'Cute flat sticker-style illustration for a language-learning flashcard, no text, white background: ${prompt.isEmpty ? concept : prompt}');
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(bytes);
      usage.record(p.id, route.model, 'image', 0, 0);
      return '/v1/images/$name';
    } catch (_) {
      return '';
    }
  }

  Future<Response> _image(Request req, String file) async {
    if (!RegExp(r'^[0-9a-f]{16}\.png$').hasMatch(file)) return Response.notFound('not found');
    final f = store.blobFile('images/$file');
    if (f == null || !f.existsSync()) return Response.notFound('not found');
    return Response.ok(f.readAsBytesSync(), headers: {'content-type': 'image/png', 'cache-control': 'public, max-age=31536000, immutable'});
  }

  /// Writing correction; mistakes also feed the server memory.
  Future<Response> _check(Request req, String deviceId) async {
    final b = await _body(req);
    final c = VokabelinaServer._ctx(b);
    final text = '${b['text'] ?? ''}'.trim();
    final task = '${b['task'] ?? ''}'.trim();
    if (text.length < 3 || text.length > 4000) return errorResponse(400, 'bad_request', 'text must be 3-4000 chars');
    try {
      final out = await ai.runJson('check',
          system: writingCheckPrompt(targetLang: c.target, nativeLang: c.native, level: c.level, memory: Map<String, dynamic>.from((b['memory'] as Map?) ?? {})),
          messages: [ChatTurn('user', 'TASK: $task\n\nLEARNER TEXT:\n$text')],
          temperature: 0.3,
          maxTokens: 1500,
          valid: (j) => j['corrected'] is String);
      final p = out.json;
      final res = {
        'score': ((p['score'] ?? 0) as num).toInt().clamp(0, 100),
        'corrected': '${p['corrected']}',
        'items': [
          for (final i in (p['items'] as List? ?? []))
            if (i is Map) {'original': '${i['original'] ?? ''}', 'corrected': '${i['corrected'] ?? ''}', 'explanation': '${i['explanation'] ?? ''}', 'tag': '${i['tag'] ?? ''}'}
        ],
        'praise': '${p['praise'] ?? ''}',
        'tip': '${p['tip'] ?? ''}',
        'level': '${p['level'] ?? ''}',
        'newWords': VokabelinaServer._words(p['newWords']),
      };
      store.logInteraction({'kind': 'writing', 'device': VokabelinaServer.deviceHash(deviceId), 'target': c.target, 'level': c.level, 'score': res['score'], 'tags': [for (final i in res['items'] as List) (i as Map)['tag']]});
      return jsonResponse(res);
    } catch (e) {
      return _aiError(e);
    }
  }

  Future<Response> _judge(Request req, String deviceId) async {
    final b = await _body(req);
    final c = VokabelinaServer._ctx(b);
    final expected = '${b['expected'] ?? ''}'.trim(), answer = '${b['answer'] ?? ''}'.trim(), prompt = '${b['prompt'] ?? ''}'.trim();
    if (expected.isEmpty || answer.isEmpty || answer.length > 300) return errorResponse(400, 'bad_request', 'expected and answer required');
    final key = 'judge|${c.target}|${c.native}|$prompt|$expected|${answer.toLowerCase()}';
    if (_cache[key] case final hit?) return jsonResponse(hit);
    try {
      final out = await ai.runJson('judge',
          system: judgePrompt(targetLang: c.target, nativeLang: c.native),
          messages: [ChatTurn('user', 'Prompt (meaning): "$prompt"\nExpected answer: "$expected"\nLearner answer: "$answer"')],
          temperature: 0,
          maxTokens: 200,
          valid: (j) => j['accepted'] is bool);
      final res = {'accepted': out.json['accepted'] == true, 'explanation': '${out.json['explanation'] ?? ''}'};
      _remember(key, res);
      return jsonResponse(res);
    } catch (e) {
      return _aiError(e);
    }
  }

  Future<Response> _practice(Request req, String deviceId) async {
    final b = await _body(req);
    final c = VokabelinaServer._ctx(b);
    final words = [for (final w in (b['words'] as List? ?? [])) '$w'].take(10).toList();
    final mistakes = [for (final m in (b['mistakes'] as List? ?? [])) '$m'].take(5).toList();
    final interests = [for (final m in (b['interests'] as List? ?? [])) '$m'].take(5).toList();
    try {
      final out = await ai.runJson('practice',
          system: practicePrompt(targetLang: c.target, nativeLang: c.native, level: c.level),
          messages: [ChatTurn('user', 'Weak words: ${words.join(', ')}\nRecurring mistakes: ${mistakes.join('; ')}\nInterests: ${interests.join(', ')}')],
          temperature: 0.7,
          maxTokens: 1500,
          valid: (j) => j['items'] is List);
      final items = [
        for (final i in out.json['items'] as List)
          if (i is Map && '${i['sentence']}'.contains('___'))
            () {
              final answer = '${i['answer'] ?? ''}'.trim();
              final options = {answer, for (final o in (i['options'] as List? ?? [])) '$o'.trim()}.where((o) => o.isNotEmpty).toList();
              return {'sentence': '${i['sentence']}', 'answer': answer, 'options': options, 'translation': '${i['translation'] ?? ''}', 'hint': '${i['hint'] ?? ''}'};
            }()
      ];
      return jsonResponse({'items': items});
    } catch (e) {
      return _aiError(e);
    }
  }

  Future<Response> _story(Request req, String deviceId) async {
    final b = await _body(req);
    final c = VokabelinaServer._ctx(b);
    final words = [for (final w in (b['words'] as List? ?? [])) '$w'].take(14).toList();
    final interests = [for (final m in (b['interests'] as List? ?? [])) '$m'].take(5).toList();
    try {
      final out = await ai.runJson('story',
          system: storyPrompt(targetLang: c.target, nativeLang: c.native, level: c.level),
          messages: [ChatTurn('user', 'Words to use: ${words.join(', ')}\nInterests: ${interests.join(', ')}')],
          temperature: 0.9,
          maxTokens: 1800,
          valid: (j) => j['text'] is String && j['title'] is String);
      final p = out.json;
      return jsonResponse({
        'title': p['title'],
        'text': p['text'],
        'translation': '${p['translation'] ?? ''}',
        'glossary': VokabelinaServer._words(p['glossary']),
        'questions': [
          for (final q in (p['questions'] as List? ?? []))
            if (q is Map && q['options'] is List)
              {'question': '${q['question'] ?? ''}', 'options': [for (final o in q['options'] as List) '$o'], 'answer': ((q['answer'] ?? 0) as num).toInt()}
        ],
      });
    } catch (e) {
      return _aiError(e);
    }
  }

  Future<Response> _grammar(Request req, String deviceId) async {
    final b = await _body(req);
    final c = VokabelinaServer._ctx(b);
    final topic = '${b['topic'] ?? ''}'.trim(), question = '${b['question'] ?? ''}'.trim();
    if (topic.isEmpty || topic.length > 200 || question.length > 500) return errorResponse(400, 'bad_request', 'topic required');
    final key = 'grammar|${c.target}|${c.native}|${c.level}|$topic|$question';
    final cached = question.isEmpty ? _diskCache(key) : null;
    if (cached != null) return jsonResponse(cached);
    try {
      final out = await ai.runJson('grammar',
          system: grammarPrompt(targetLang: c.target, nativeLang: c.native, level: c.level),
          messages: [ChatTurn('user', 'Topic: $topic${question.isEmpty ? '' : '\nQuestion: $question'}')],
          temperature: 0.4,
          valid: (j) => j['explanation'] is String);
      final p = out.json;
      final res = {
        'title': '${p['title'] ?? topic}',
        'explanation': p['explanation'],
        'examples': [
          for (final e in (p['examples'] as List? ?? []))
            if (e is Map) {'text': '${e['text'] ?? ''}', 'translation': '${e['translation'] ?? ''}'}
        ],
      };
      if (question.isEmpty) _diskCachePut(key, res);
      return jsonResponse(res);
    } catch (e) {
      return _aiError(e);
    }
  }

  /// Thumbs up/down: trains the prompt bandit and labels the fine-tuning data.
  Future<Response> _feedback(Request req, String deviceId) async {
    final b = await _body(req);
    final rating = b['rating'];
    if (rating != 1 && rating != -1 && rating != 0) return errorResponse(400, 'bad_request', 'rating must be 1, 0 or -1');
    final id = '${b['id']}';
    store.logInteraction({'kind': 'feedback', 'id': id, 'rating': rating, 'device': VokabelinaServer.deviceHash(deviceId), 'note': '${b['note'] ?? ''}'});
    final variant = _variantOf[id] ?? _lookupVariant(id);
    if (variant != null && rating != 0) bandit.reward(variant, rating as int);
    return jsonResponse({'ok': true});
  }

  String? _lookupVariant(String id) {
    for (final e in store.readLog().reversed) {
      if (e['kind'] == 'chat' && e['id'] == id) return e['variant'] as String?;
    }
    return null;
  }
}

/// Reply id → prompt variant (recent replies; older ones are looked up in the log).
final _variantOf = <String, String>{};
