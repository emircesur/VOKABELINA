import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../data/curriculum.dart';
import '../data/models.dart';
import '../data/seed_words.dart';
import '../services/api.dart';
import '../services/learner.dart';
import '../services/lessons.dart';
import '../services/offline_tutor.dart';
import '../services/srs.dart';
import '../services/streak.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('override in main()'));
final httpClientProvider = Provider<http.Client>((ref) => http.Client());
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final apiProvider = Provider<ApiClient>((ref) {
  final url = ref.watch(profileProvider.select((p) => p.serverUrl));
  return ApiClient(ref.watch(httpClientProvider), ref.watch(sharedPrefsProvider), baseUrl: url);
});

Map<String, dynamic>? _readJson(SharedPreferences p, String key) {
  final s = p.getString(key);
  if (s == null) return null;
  try {
    return jsonDecode(s) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

// ------------------------------------------------------------------ profile

final profileProvider = NotifierProvider<ProfileNotifier, Profile>(ProfileNotifier.new);

class ProfileNotifier extends Notifier<Profile> {
  @override
  Profile build() {
    final j = _readJson(ref.read(sharedPrefsProvider), 'profile');
    return j == null ? const Profile() : Profile.fromJson(j);
  }

  void set(Profile p) {
    state = p;
    ref.read(sharedPrefsProvider).setString('profile', jsonEncode(p.toJson()));
  }

  void update(Profile Function(Profile) f) => set(f(state));

  void addXp(int xp) {
    final p = awardXp(state, xp, ref.read(clockProvider)());
    set(p.streak > p.bestStreak ? p.copyWith(bestStreak: p.streak) : p);
  }

  /// Switches the language being learned; the native language can't equal it.
  void setTarget(String lang) {
    if (lang == state.nativeLang) return;
    set(state.copyWith(targetLang: lang));
  }

  /// Native/UI language; if it collides with the target, the target moves to German or English.
  void setNative(String lang) {
    var target = state.targetLang;
    if (target == lang) target = lang == 'de' ? 'en' : 'de';
    set(state.copyWith(nativeLang: lang, targetLang: target));
  }
}

// --------------------------------------------------------------------- deck

class DeckState {
  const DeckState({this.customWords = const {}, this.cards = const {}});
  final Map<String, Word> customWords;

  /// cardKey(lang, wordId) → card
  final Map<String, CardState> cards;

  Map<String, Word> get words => {for (final w in seedWords) w.id: w, ...customWords};

  /// Cards of one target language keyed by word id.
  Map<String, CardState> forLang(String lang) => {for (final c in cards.values) if (c.lang == lang) c.wordId: c};

  List<CardState> due(DateTime now, String lang) =>
      [for (final c in cards.values) if (c.lang == lang && c.isDue(now)) c]..sort((a, b) => a.due.compareTo(b.due));

  bool has(String lang, String wordId) => cards.containsKey(cardKey(lang, wordId));
}

final deckProvider = NotifierProvider<DeckNotifier, DeckState>(DeckNotifier.new);

class DeckNotifier extends Notifier<DeckState> {
  String get _lang => ref.read(profileProvider).targetLang;

  @override
  DeckState build() {
    final j = _readJson(ref.read(sharedPrefsProvider), 'deck');
    if (j == null) return const DeckState();
    final words = [for (final w in (j['words'] as List? ?? [])) Word.fromJson(Map<String, dynamic>.from(w as Map))];
    final cards = [for (final c in (j['cards'] as List? ?? [])) CardState.fromJson(Map<String, dynamic>.from(c as Map))];
    return DeckState(customWords: {for (final w in words) w.id: w}, cards: {for (final c in cards) c.key: c});
  }

  void _save() {
    ref.read(sharedPrefsProvider).setString(
        'deck',
        jsonEncode({
          'words': [for (final w in state.customWords.values) w.toJson()],
          'cards': [for (final c in state.cards.values) c.toJson()],
        }));
  }

  void _emit() {
    state = DeckState(customWords: state.customWords, cards: Map.of(state.cards));
    _save();
  }

  /// Adds words to the deck of [lang] (default: current target). Returns how many were new.
  int add(Iterable<Word> ws, {String? lang}) {
    final l = lang ?? _lang;
    final custom = Map.of(state.customWords);
    final cards = Map.of(state.cards);
    final seedIds = {for (final w in seedWords) w.id};
    var added = 0;
    for (final w in ws) {
      if (w.de.trim().isEmpty && w.inLang(l).trim().isEmpty) continue;
      final key = cardKey(l, w.id);
      if (cards.containsKey(key)) continue;
      if (!seedIds.contains(w.id)) custom[w.id] = w;
      cards[key] = CardState(wordId: w.id, lang: l, due: ref.read(clockProvider)());
      added++;
    }
    state = DeckState(customWords: custom, cards: cards);
    _save();
    return added;
  }

  void review(String wordId, Grade g, {String? lang}) {
    final c = state.cards[cardKey(lang ?? _lang, wordId)];
    if (c == null) return;
    schedule(c, g, now: ref.read(clockProvider)());
    _emit();
  }

  /// Reinforcement signal from lessons and the tutor: +1 success or +1 failure.
  void signal(Iterable<String> wordIds, {required bool success, String? lang}) {
    final l = lang ?? _lang;
    var changed = false;
    for (final id in wordIds) {
      final c = state.cards[cardKey(l, id)];
      if (c == null) continue;
      success ? c.successes++ : c.failures++;
      changed = true;
    }
    if (changed) _emit();
  }

  /// After a lesson: every practised word enters the SRS, graded by how it went.
  void learnFromLesson(Map<String, ({int ok, int bad})> outcomes) {
    add([for (final id in outcomes.keys) if (state.words[id] != null) state.words[id]!]);
    final now = ref.read(clockProvider)();
    for (final e in outcomes.entries) {
      final c = state.cards[cardKey(_lang, e.key)];
      if (c == null) continue;
      c.successes += e.value.ok;
      c.failures += e.value.bad;
      // only (re)schedule cards that are due or new, so lessons don't inflate intervals
      if (c.reps == 0 || c.isDue(now)) {
        // schedule() also counts an outcome; the lesson counts above are the real ones
        final (s0, f0) = (c.successes, c.failures);
        schedule(c, e.value.bad == 0 ? Grade.good : (e.value.ok >= e.value.bad ? Grade.hard : Grade.again), now: now);
        c
          ..successes = s0
          ..failures = f0;
      }
    }
    _emit();
  }

  /// Catalogue words not yet in the deck, in course order, starting near [level].
  List<Word> newWordsFor(String level, int n) {
    final lang = _lang;
    final order = levels.indexOf(level);
    final out = <Word>[];
    for (final u in units.where((u) => levels.indexOf(u.level) >= order - 1)) {
      for (final w in u.words) {
        if (!state.has(lang, w.id)) out.add(w);
        if (out.length >= n) return out;
      }
    }
    return out;
  }

  void reset() {
    state = const DeckState();
    _save();
  }
}

// ------------------------------------------------------------------- memory

final memoryProvider = NotifierProvider<MemoryNotifier, LearnerMemory>(MemoryNotifier.new);

class MemoryNotifier extends Notifier<LearnerMemory> {
  DateTime get _now => ref.read(clockProvider)();

  @override
  LearnerMemory build() {
    final j = _readJson(ref.read(sharedPrefsProvider), 'memory');
    return j == null ? const LearnerMemory() : LearnerMemory.fromJson(j);
  }

  void _set(LearnerMemory m) {
    state = m.copyWith(updatedAt: _now);
    ref.read(sharedPrefsProvider).setString('memory', jsonEncode(state.toJson()));
  }

  /// Adds or refreshes facts (case-insensitive de-duplication; max 40, oldest dropped).
  void addFacts(Iterable<String> facts, {String category = 'other'}) {
    final now = _now;
    final cur = [...state.facts];
    for (final f in facts.map((f) => f.trim()).where((f) => f.isNotEmpty)) {
      final i = cur.indexWhere((x) => x.text.toLowerCase() == f.toLowerCase());
      if (i >= 0) {
        cur[i] = cur[i].seenAgain(now);
      } else {
        cur.add(MemoryFact(text: f, category: category, firstSeen: now, lastSeen: now));
      }
    }
    cur.sort((a, b) => a.lastSeen.compareTo(b.lastSeen));
    _set(state.copyWith(facts: cur.length > 40 ? cur.sublist(cur.length - 40) : cur));
  }

  void removeFact(String text) => _set(state.copyWith(facts: state.facts.where((f) => f.text != text).toList()));

  /// Folds corrections into decaying mistake patterns keyed by grammar tag.
  void addCorrections(String lang, Iterable<Correction> cs) {
    final now = _now;
    final m = Map.of(state.mistakes);
    for (final c in cs) {
      final tag = (c.tag.isNotEmpty ? c.tag : c.explanation).trim();
      if (tag.isEmpty) continue;
      final example = c.original.isEmpty ? '' : '${c.original} → ${c.corrected}';
      final key = '$lang|${tag.toLowerCase()}';
      final prev = m[key];
      m[key] = prev == null
          ? MistakePattern(lang: lang, tag: tag, explanation: c.explanation, examples: [if (example.isNotEmpty) example], lastSeen: now)
          : prev.merge(explanation: c.explanation, example: example, now: now);
    }
    // keep memory bounded: drop the weakest patterns beyond 60
    if (m.length > 60) {
      final keep = m.values.toList()..sort((a, b) => b.weight(now).compareTo(a.weight(now)));
      _set(state.copyWith(mistakes: {for (final p in keep.take(60)) p.key: p}));
    } else {
      _set(state.copyWith(mistakes: m));
    }
  }

  void removeMistake(String key) => _set(state.copyWith(mistakes: Map.of(state.mistakes)..remove(key)));

  void setInterests(List<String> interests) => _set(state.copyWith(interests: interests.take(12).toList()));

  /// Merges the server's consolidated memory (summary, episodes, level estimate, tags …).
  void mergeServer(Map<String, dynamic> j) {
    final now = _now;
    var m = state.copyWith(
      summary: (j['summary'] as String?)?.trim().isNotEmpty == true ? j['summary'] as String : null,
      estimatedLevel: (j['estimatedLevel'] as String?)?.isNotEmpty == true ? j['estimatedLevel'] as String : null,
      focus: j['focus'] is List ? [for (final x in j['focus'] as List) '$x'] : null,
      interests: j['interests'] is List ? {...state.interests, for (final x in j['interests'] as List) '$x'}.take(12).toList() : null,
      goals: j['goals'] is List ? {...state.goals, for (final x in j['goals'] as List) '$x'}.take(8).toList() : null,
      episodes: j['episodes'] is List
          ? ([for (final e in j['episodes'] as List) if (e is Map) Episode.fromJson(Map<String, dynamic>.from(e))]..sort((a, b) => b.date.compareTo(a.date))).take(20).toList()
          : null,
    );
    // facts with categories from the server
    if (j['facts'] is List) {
      final cur = [...m.facts];
      for (final f in j['facts'] as List) {
        final text = f is Map ? '${f['text'] ?? ''}' : '$f';
        final cat = f is Map ? '${f['category'] ?? 'other'}' : 'other';
        if (text.trim().isEmpty) continue;
        final i = cur.indexWhere((x) => x.text.toLowerCase() == text.toLowerCase());
        if (i < 0) {
          cur.add(MemoryFact(text: text, category: cat, firstSeen: now, lastSeen: now));
        } else if (cur[i].category == 'other' && cat != 'other') {
          final f = cur[i];
          cur[i] = MemoryFact(text: f.text, category: cat, firstSeen: f.firstSeen, lastSeen: f.lastSeen, mentions: f.mentions);
        }
      }
      m = m.copyWith(facts: cur);
    }
    _set(m);
  }

  void clear() => _set(const LearnerMemory());

  /// Pushes the memory to the server (if allowed) and merges what comes back.
  Future<bool> sync() async {
    final p = ref.read(profileProvider);
    if (!p.cloudMemory) return false;
    try {
      final res = await ref.read(apiProvider).syncMemory(state, profile: p);
      mergeServer(res);
      return true;
    } on ApiException {
      return false;
    }
  }
}

final learnerProvider = Provider<Learner>((ref) {
  final deck = ref.watch(deckProvider);
  final lang = ref.watch(profileProvider.select((p) => p.targetLang));
  return Learner(deck.words, deck.forLang(lang), ref.watch(memoryProvider), lang: lang, now: ref.watch(clockProvider)());
});

// ----------------------------------------------------------------- progress

/// Best result per lesson, keyed `lang:lessonId`.
final progressProvider = NotifierProvider<ProgressNotifier, Map<String, LessonResult>>(ProgressNotifier.new);

class ProgressNotifier extends Notifier<Map<String, LessonResult>> {
  @override
  Map<String, LessonResult> build() {
    final j = _readJson(ref.read(sharedPrefsProvider), 'progress');
    if (j == null) return {};
    return {for (final e in j.entries) e.key: LessonResult.fromJson(Map<String, dynamic>.from(e.value as Map))};
  }

  /// Records a lesson; keeps the best stars/score. Returns the stars earned.
  int complete(String lessonId, {required int correct, required int total, String? lang}) {
    final l = lang ?? ref.read(profileProvider).targetLang;
    final stars = starsFor(correct, total);
    final score = total == 0 ? 100 : (correct * 100 / total).round();
    final key = '$l:$lessonId';
    final prev = state[key];
    final best = LessonResult(
      stars: prev == null ? stars : (stars > prev.stars ? stars : prev.stars),
      score: prev == null ? score : (score > prev.score ? score : prev.score),
      completedAt: ref.read(clockProvider)(),
    );
    state = {...state, key: best};
    ref.read(sharedPrefsProvider).setString('progress', jsonEncode({for (final e in state.entries) e.key: e.value.toJson()}));
    return stars;
  }

  void reset() {
    state = {};
    ref.read(sharedPrefsProvider).remove('progress');
  }
}

/// Course map logic for the current target language.
class CourseStatus {
  CourseStatus(this.lang, this.level, this.results);
  final String lang;
  final String level;
  final Map<String, LessonResult> results;

  LessonResult? result(LessonSpec l) => results['$lang:${l.id}'];
  bool done(LessonSpec l) => result(l) != null;

  bool unitDone(Unit u) => lessonsFor(u).where((l) => l.required).every(done);
  int unitStars(Unit u) => lessonsFor(u).fold(0, (s, l) => s + (result(l)?.stars ?? 0));

  /// Units below the placement level are open; otherwise the previous unit must be done.
  bool unitUnlocked(Unit u) {
    if (levels.indexOf(u.level) < levels.indexOf(level)) return true;
    final i = units.indexOf(u);
    return i == 0 || unitDone(units[i - 1]) || units.sublist(0, i).every((x) => levels.indexOf(x.level) < levels.indexOf(level));
  }

  /// Lessons inside a unit open one after another; AI lessons open with the dialogue.
  bool lessonUnlocked(Unit u, LessonSpec l) {
    if (!unitUnlocked(u)) return false;
    final ls = lessonsFor(u);
    if (l.isAi) return ls.where((x) => x.kind == LessonKind.dialogue).every(done);
    final i = ls.indexOf(l);
    return ls.take(i).where((x) => x.required).every(done);
  }

  /// The next lesson to do (first unlocked, not done, required).
  (Unit, LessonSpec)? next() {
    for (final u in units) {
      if (!unitUnlocked(u)) continue;
      for (final l in lessonsFor(u)) {
        if (l.required && !done(l) && lessonUnlocked(u, l)) return (u, l);
      }
    }
    return null;
  }

  int get lessonsDone => results.keys.where((k) => k.startsWith('$lang:')).length;
}

final courseProvider = Provider<CourseStatus>((ref) {
  final p = ref.watch(profileProvider);
  return CourseStatus(p.targetLang, p.level, ref.watch(progressProvider));
});

// --------------------------------------------------------------------- chat

class ChatState {
  const ChatState({this.messages = const [], this.sending = false, this.mood = 'happy', this.notice, this.scenario = ''});
  final List<ChatMessage> messages;
  final bool sending;
  final String mood;

  /// Non-fatal info shown above the chat (e.g. "offline mode").
  final String? notice;

  /// Role-play brief for lesson conversations ('' = free chat).
  final String scenario;

  int get userTurns => messages.where((m) => m.fromUser).length;

  ChatState copyWith({List<ChatMessage>? messages, bool? sending, String? mood, String? notice, bool clearNotice = false, String? scenario}) => ChatState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      mood: mood ?? this.mood,
      notice: clearNotice ? null : (notice ?? this.notice),
      scenario: scenario ?? this.scenario);
}

/// Free tutor chat (persisted per target language).
final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() => ChatNotifier());

/// Lesson role-play (not persisted).
final roleplayProvider = NotifierProvider<ChatNotifier, ChatState>(() => ChatNotifier(persist: false));

class ChatNotifier extends Notifier<ChatState> {
  ChatNotifier({this.persist = true});
  final bool persist;
  final _offline = OfflineTutor();

  String get _key => 'chat_${ref.read(profileProvider).targetLang}';

  @override
  ChatState build() {
    ref.watch(profileProvider.select((p) => p.targetLang));
    if (!persist) return const ChatState();
    final prefs = ref.read(sharedPrefsProvider);
    // migrate the single pre-multilanguage chat to German
    if (prefs.getString('chat') != null && prefs.getString('chat_de') == null) {
      prefs.setString('chat_de', prefs.getString('chat')!);
      prefs.remove('chat');
    }
    final j = _readJson(prefs, _key);
    if (j == null) return const ChatState();
    return ChatState(messages: [for (final m in (j['messages'] as List? ?? [])) ChatMessage.fromJson(Map<String, dynamic>.from(m as Map))]);
  }

  void _save() {
    if (!persist) return;
    ref.read(sharedPrefsProvider).setString(_key, jsonEncode({'messages': [for (final m in state.messages.reversed.take(60).toList().reversed) m.toJson()]}));
  }

  /// Starts a lesson role-play: the tutor opens the scene.
  Future<void> startScenario(String scenario, {String opener = ''}) async {
    state = ChatState(scenario: scenario);
    if (opener.isNotEmpty) {
      state = state.copyWith(messages: [ChatMessage(id: 'open', fromUser: false, text: opener)]);
    }
  }

  Future<void> send(String text) async {
    text = text.trim();
    if (text.isEmpty || state.sending) return;
    final profile = ref.read(profileProvider);
    final learner = ref.read(learnerProvider);
    final now = ref.read(clockProvider)();
    final userMsg = ChatMessage(id: 'u${now.microsecondsSinceEpoch}', fromUser: true, text: text);
    state = state.copyWith(messages: [...state.messages, userMsg], sending: true, mood: 'thinking', clearNotice: true);
    _save();

    final tracked = learner.trackedWordIdsIn(text);
    ChatReply reply;
    try {
      reply = await ref.read(apiProvider).chat(profile: profile, history: state.messages, memory: learner.toPayload(), scenario: state.scenario);
    } on ApiException catch (e) {
      reply = _offline.reply(profile: profile, learner: learner, userText: text, firstTurn: state.messages.length <= 1);
      state = state.copyWith(
          notice: e.noProvider
              ? 'noProvider'
              : e.code == 'not_configured'
                  ? 'notConfigured'
                  : 'unreachable');
    }

    // --- reinforcement: feed the outcome back into the learner model ---
    final deck = ref.read(deckProvider.notifier);
    final correctedWords = {for (final c in reply.corrections) ...learner.trackedWordIdsIn(c.original)};
    final usedOk = {...tracked, for (final w in reply.usedKnownWords) ...learner.trackedWordIdsIn(w)}..removeAll(correctedWords);
    deck.signal(usedOk, success: true);
    deck.signal(correctedWords, success: false);
    final mem = ref.read(memoryProvider.notifier);
    mem.addCorrections(profile.targetLang, reply.corrections);
    mem.addFacts(reply.newFacts);
    ref.read(profileProvider.notifier).addXp(reply.corrections.isEmpty ? 6 : 4);

    final msg = ChatMessage(
      id: reply.id,
      fromUser: false,
      text: reply.reply,
      native: reply.replyNative,
      corrections: reply.corrections,
      newWords: reply.newWords,
      suggestions: reply.suggestions,
      offline: reply.offline,
    );
    state = state.copyWith(messages: [...state.messages, msg], sending: false, mood: reply.mood);
    _save();

    // every few turns let the server consolidate long-term memory (episodes, summary)
    if (!reply.offline && state.userTurns % 5 == 0) mem.sync();
  }

  /// Thumbs up/down — also logged server-side (prompt bandit + fine-tuning data).
  Future<void> rate(String id, int rating) async {
    state = state.copyWith(messages: [for (final m in state.messages) m.id == id ? m.copyWith(rating: rating) : m]);
    _save();
    try {
      await ref.read(apiProvider).feedback(id, rating);
    } on ApiException {
      // best effort
    }
  }

  void clear() {
    state = ChatState(scenario: state.scenario);
    _save();
  }
}
