import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content.dart';
import '../data/models.dart';
import '../data/seed_words.dart';
import '../services/api.dart';
import '../services/learner.dart';
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

  void addXp(int xp) => set(awardXp(state, xp, ref.read(clockProvider)()));
}

// --------------------------------------------------------------------- deck

class DeckState {
  const DeckState({this.customWords = const {}, this.cards = const {}});
  final Map<String, Word> customWords;
  final Map<String, CardState> cards;

  Map<String, Word> get words => {for (final w in seedWords) w.id: w, ...customWords};

  List<CardState> due(DateTime now) => [for (final c in cards.values) if (c.isDue(now)) c]..sort((a, b) => a.due.compareTo(b.due));
}

final deckProvider = NotifierProvider<DeckNotifier, DeckState>(DeckNotifier.new);

class DeckNotifier extends Notifier<DeckState> {
  @override
  DeckState build() {
    final j = _readJson(ref.read(sharedPrefsProvider), 'deck');
    if (j == null) return const DeckState();
    return DeckState(
      customWords: {
        for (final w in (j['words'] as List? ?? [])) Word.fromJson(Map<String, dynamic>.from(w as Map)).id: Word.fromJson(Map<String, dynamic>.from(w))
      },
      cards: {
        for (final c in (j['cards'] as List? ?? [])) (c as Map)['w'] as String: CardState.fromJson(Map<String, dynamic>.from(c))
      },
    );
  }

  void _save() {
    ref.read(sharedPrefsProvider).setString(
        'deck',
        jsonEncode({
          'words': [for (final w in state.customWords.values) w.toJson()],
          'cards': [for (final c in state.cards.values) c.toJson()],
        }));
  }

  /// Adds words (new AI-found or catalogue) to the learner's deck. Returns how many were new.
  int add(Iterable<Word> ws) {
    final custom = Map.of(state.customWords);
    final cards = Map.of(state.cards);
    final seedIds = {for (final w in seedWords) w.id};
    var added = 0;
    for (final w in ws) {
      if (cards.containsKey(w.id)) continue;
      if (!seedIds.contains(w.id)) custom[w.id] = w;
      cards[w.id] = CardState(wordId: w.id, due: ref.read(clockProvider)());
      added++;
    }
    state = DeckState(customWords: custom, cards: cards);
    _save();
    return added;
  }

  void review(String wordId, Grade g) {
    final c = state.cards[wordId];
    if (c == null) return;
    schedule(c, g, now: ref.read(clockProvider)());
    state = DeckState(customWords: state.customWords, cards: Map.of(state.cards));
    _save();
  }

  /// Reinforcement signal from the tutor chat: +1 success (used correctly) or +1 failure (corrected).
  void signal(Iterable<String> wordIds, {required bool success}) {
    var changed = false;
    for (final id in wordIds) {
      final c = state.cards[id];
      if (c == null) continue;
      success ? c.successes++ : c.failures++;
      changed = true;
    }
    if (!changed) return;
    state = DeckState(customWords: state.customWords, cards: Map.of(state.cards));
    _save();
  }

  /// Catalogue words not yet in the deck, easiest level first.
  List<Word> newWordsFor(String level, int n) {
    final order = levels.indexOf(level);
    final fresh = [for (final w in seedWords) if (!state.cards.containsKey(w.id)) w];
    fresh.sort((a, b) {
      final da = (levels.indexOf(a.level) - order).abs();
      final db = (levels.indexOf(b.level) - order).abs();
      return da.compareTo(db);
    });
    return fresh.take(n).toList();
  }

  void reset() {
    state = const DeckState();
    _save();
  }
}

// ------------------------------------------------------------------- memory

final memoryProvider = NotifierProvider<MemoryNotifier, LearnerMemory>(MemoryNotifier.new);

class MemoryNotifier extends Notifier<LearnerMemory> {
  @override
  LearnerMemory build() {
    final j = _readJson(ref.read(sharedPrefsProvider), 'memory');
    return j == null ? const LearnerMemory() : LearnerMemory.fromJson(j);
  }

  void _set(LearnerMemory m) {
    state = m;
    ref.read(sharedPrefsProvider).setString('memory', jsonEncode(m.toJson()));
  }

  void addFacts(Iterable<String> facts) {
    final cur = [...state.facts];
    for (final f in facts.map((f) => f.trim()).where((f) => f.isNotEmpty)) {
      if (!cur.any((x) => x.toLowerCase() == f.toLowerCase())) cur.add(f);
    }
    _set(state.copyWith(facts: cur.length > 40 ? cur.sublist(cur.length - 40) : cur));
  }

  void removeFact(String f) => _set(state.copyWith(facts: [...state.facts]..remove(f)));

  void addMistakes(Iterable<String> explanations) {
    final m = Map.of(state.mistakes);
    for (final e in explanations.map((e) => e.trim()).where((e) => e.isNotEmpty)) {
      m[e] = (m[e] ?? 0) + 1;
    }
    // keep memory bounded: drop the rarest when over 60
    if (m.length > 60) {
      final keep = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      _set(state.copyWith(mistakes: {for (final e in keep.take(60)) e.key: e.value}));
    } else {
      _set(state.copyWith(mistakes: m));
    }
  }

  void clear() => _set(const LearnerMemory());
}

final learnerProvider = Provider<Learner>((ref) {
  final deck = ref.watch(deckProvider);
  return Learner(deck.words, deck.cards, ref.watch(memoryProvider));
});

// --------------------------------------------------------------------- chat

class ChatState {
  const ChatState({this.messages = const [], this.sending = false, this.mood = 'happy', this.notice});
  final List<ChatMessage> messages;
  final bool sending;
  final String mood;

  /// Non-fatal info shown above the chat (e.g. "offline mode").
  final String? notice;

  ChatState copyWith({List<ChatMessage>? messages, bool? sending, String? mood, String? notice, bool clearNotice = false}) => ChatState(
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      mood: mood ?? this.mood,
      notice: clearNotice ? null : (notice ?? this.notice));
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

class ChatNotifier extends Notifier<ChatState> {
  final _offline = OfflineTutor();

  @override
  ChatState build() {
    final j = _readJson(ref.read(sharedPrefsProvider), 'chat');
    if (j == null) return const ChatState();
    return ChatState(messages: [for (final m in (j['messages'] as List? ?? [])) ChatMessage.fromJson(Map<String, dynamic>.from(m as Map))]);
  }

  void _save() => ref
      .read(sharedPrefsProvider)
      .setString('chat', jsonEncode({'messages': [for (final m in state.messages.reversed.take(60).toList().reversed) m.toJson()]}));

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
      reply = await ref.read(apiProvider).chat(profile: profile, history: state.messages, memory: learner.toPayload());
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
    ref.read(memoryProvider.notifier)
      ..addMistakes([for (final c in reply.corrections) c.explanation])
      ..addFacts(reply.newFacts);
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
  }

  /// Thumbs up/down — also logged server-side to build the fine-tuning set.
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
    state = const ChatState();
    _save();
  }
}
