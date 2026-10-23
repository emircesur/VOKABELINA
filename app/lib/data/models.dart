import 'dart:math' as math;

const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

const targetLangs = ['de', 'en', 'tr'];
const langNames = {
  'de': {'de': 'Deutsch', 'en': 'German', 'tr': 'Almanca'},
  'en': {'de': 'Englisch', 'en': 'English', 'tr': 'İngilizce'},
  'tr': {'de': 'Türkisch', 'en': 'Turkish', 'tr': 'Türkçe'},
};
const langFlags = {'de': '🇩🇪', 'en': '🇬🇧', 'tr': '🇹🇷'};
const ttsLocales = {'de': 'de-DE', 'en': 'en-GB', 'tr': 'tr-TR'};

/// One concept with its German, English and Turkish forms, so the same card
/// serves learners of all three languages.
class Word {
  const Word({
    required this.id,
    required this.de,
    required this.en,
    required this.tr,
    this.emoji = '',
    this.plural = '',
    this.example = '',
    this.level = 'A1',
    this.topic = '',
    this.custom = false,
  });

  final String id;

  /// German form; nouns include the article ("der Tisch").
  final String de;
  final String en;
  final String tr;

  /// Picture for the card (emoji keeps cards offline and license-free).
  final String emoji;

  /// German plural without article; '-' = no plural / uncountable.
  final String plural;

  /// German example sentence.
  final String example;
  final String level;

  /// Course unit id (e.g. "u05") or a source tag ("chat", "news", "mine").
  final String topic;
  final bool custom;

  /// The word in [lang] ('de' | 'en' | 'tr').
  String inLang(String lang) => switch (lang) {
        'de' => de,
        'tr' => tr.isNotEmpty ? tr : en,
        _ => en.isNotEmpty ? en : tr,
      };

  /// Meaning shown to a learner whose language is [lang].
  String gloss(String lang) {
    if (lang == 'de') return de;
    final g = lang == 'tr' ? tr : en;
    return g.isNotEmpty ? g : (en.isNotEmpty ? en : tr);
  }

  /// 'der' | 'die' | 'das' for German nouns, otherwise null.
  String? get article {
    final m = RegExp(r'^(der|die|das)\s', caseSensitive: false).firstMatch(de);
    return m?.group(1)?.toLowerCase();
  }

  bool get isNoun => article != null || (de.isNotEmpty && plural.isNotEmpty);

  /// "Tisch" for "der Tisch" — used to match words inside free text.
  String get lemma {
    final m = RegExp(r'^(der|die|das)\s+(.+)$', caseSensitive: false).firstMatch(de);
    return (m?.group(2) ?? de).toLowerCase();
  }

  /// "die Tische" — or null if there is no useful plural.
  String? get pluralForm => plural.isEmpty || plural == '-' ? null : 'die $plural';

  static String idFor(String de) =>
      de.toLowerCase().replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue').replaceAll('ß', 'ss').replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  Map<String, dynamic> toJson() => {
        'id': id,
        'de': de,
        'en': en,
        'tr': tr,
        if (emoji.isNotEmpty) 'emoji': emoji,
        if (plural.isNotEmpty) 'plural': plural,
        'example': example,
        'level': level,
        'topic': topic,
        'custom': custom,
      };

  factory Word.fromJson(Map<String, dynamic> j) => Word(
        id: j['id'] as String,
        de: j['de'] as String,
        en: (j['en'] ?? '') as String,
        tr: (j['tr'] ?? '') as String,
        emoji: (j['emoji'] ?? '') as String,
        plural: (j['plural'] ?? '') as String,
        example: (j['example'] ?? '') as String,
        level: (j['level'] ?? 'A1') as String,
        topic: (j['topic'] ?? '') as String,
        custom: (j['custom'] ?? false) as bool,
      );
}

/// Spaced-repetition state of one word in one target language (SM-2 variant).
class CardState {
  CardState({
    required this.wordId,
    this.lang = 'de',
    this.ease = 2.5,
    this.intervalDays = 0,
    this.reps = 0,
    this.lapses = 0,
    this.successes = 0,
    this.failures = 0,
    DateTime? due,
    this.lastReviewed,
  }) : due = due ?? DateTime.now();

  final String wordId;

  /// Target language this card trains ('de' | 'en' | 'tr').
  final String lang;
  double ease;
  int intervalDays;
  int reps;
  int lapses;

  /// Lifetime outcome counts, also fed by lessons and tutor chat.
  int successes;
  int failures;
  DateTime due;
  DateTime? lastReviewed;

  String get key => cardKey(lang, wordId);

  bool isDue(DateTime now) => !due.isAfter(now);

  /// 0..1 — how firmly the word is known.
  double get mastery {
    if (reps == 0) return 0;
    final byInterval = (intervalDays / 30).clamp(0.0, 1.0);
    final byRate = (successes + 1) / (successes + failures + 2);
    return (0.6 * byInterval + 0.4 * byRate).clamp(0.0, 1.0);
  }

  bool get isKnown => reps >= 2 && intervalDays >= 7;

  Map<String, dynamic> toJson() => {
        'w': wordId,
        'g': lang,
        'e': ease,
        'i': intervalDays,
        'r': reps,
        'l': lapses,
        's': successes,
        'f': failures,
        'd': due.toIso8601String(),
        'lr': lastReviewed?.toIso8601String(),
      };

  /// Cards saved before multi-language support have no 'g' and are German.
  factory CardState.fromJson(Map<String, dynamic> j) => CardState(
        wordId: j['w'] as String,
        lang: (j['g'] ?? 'de') as String,
        ease: (j['e'] as num).toDouble(),
        intervalDays: j['i'] as int,
        reps: j['r'] as int,
        lapses: j['l'] as int,
        successes: (j['s'] ?? 0) as int,
        failures: (j['f'] ?? 0) as int,
        due: DateTime.parse(j['d'] as String),
        lastReviewed: j['lr'] == null ? null : DateTime.parse(j['lr'] as String),
      );
}

String cardKey(String lang, String wordId) => '$lang:$wordId';

class Profile {
  const Profile({
    this.onboarded = false,
    this.name = '',
    this.nativeLang = 'tr',
    this.targetLang = 'de',
    this.level = 'A1',
    this.persona = 'bruno',
    this.dailyGoalXp = 50,
    this.xp = 0,
    this.todayXp = 0,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastActiveDay = '',
    this.serverUrl = '',
    this.cloudMemory = true,
  });

  final bool onboarded;
  final String name;

  /// 'tr' | 'en' | 'de' — UI, explanations and translations use this language.
  final String nativeLang;

  /// 'de' | 'en' | 'tr' — the language being learned (never equal to [nativeLang]).
  final String targetLang;
  final String level;

  /// 'bruno' | 'fuchs' | 'brezel'
  final String persona;
  final int dailyGoalXp;
  final int xp;
  final int todayXp;
  final int streak;
  final int bestStreak;

  /// yyyy-MM-dd of the last day with activity.
  final String lastActiveDay;
  final String serverUrl;

  /// Let the server keep a consolidated memory (summaries, episodes) for a smarter tutor.
  final bool cloudMemory;

  Profile copyWith({
    bool? onboarded,
    String? name,
    String? nativeLang,
    String? targetLang,
    String? level,
    String? persona,
    int? dailyGoalXp,
    int? xp,
    int? todayXp,
    int? streak,
    int? bestStreak,
    String? lastActiveDay,
    String? serverUrl,
    bool? cloudMemory,
  }) =>
      Profile(
        onboarded: onboarded ?? this.onboarded,
        name: name ?? this.name,
        nativeLang: nativeLang ?? this.nativeLang,
        targetLang: targetLang ?? this.targetLang,
        level: level ?? this.level,
        persona: persona ?? this.persona,
        dailyGoalXp: dailyGoalXp ?? this.dailyGoalXp,
        xp: xp ?? this.xp,
        todayXp: todayXp ?? this.todayXp,
        streak: streak ?? this.streak,
        bestStreak: bestStreak ?? this.bestStreak,
        lastActiveDay: lastActiveDay ?? this.lastActiveDay,
        serverUrl: serverUrl ?? this.serverUrl,
        cloudMemory: cloudMemory ?? this.cloudMemory,
      );

  Map<String, dynamic> toJson() => {
        'onboarded': onboarded,
        'name': name,
        'nativeLang': nativeLang,
        'targetLang': targetLang,
        'level': level,
        'persona': persona,
        'dailyGoalXp': dailyGoalXp,
        'xp': xp,
        'todayXp': todayXp,
        'streak': streak,
        'bestStreak': bestStreak,
        'lastActiveDay': lastActiveDay,
        'serverUrl': serverUrl,
        'cloudMemory': cloudMemory,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        onboarded: (j['onboarded'] ?? false) as bool,
        name: (j['name'] ?? '') as String,
        nativeLang: (j['nativeLang'] ?? 'tr') as String,
        targetLang: (j['targetLang'] ?? 'de') as String,
        level: (j['level'] ?? 'A1') as String,
        persona: (j['persona'] ?? 'bruno') as String,
        dailyGoalXp: (j['dailyGoalXp'] ?? 50) as int,
        xp: (j['xp'] ?? 0) as int,
        todayXp: (j['todayXp'] ?? 0) as int,
        streak: (j['streak'] ?? 0) as int,
        bestStreak: (j['bestStreak'] ?? j['streak'] ?? 0) as int,
        lastActiveDay: (j['lastActiveDay'] ?? '') as String,
        serverUrl: (j['serverUrl'] ?? '') as String,
        cloudMemory: (j['cloudMemory'] ?? true) as bool,
      );
}

// ------------------------------------------------------------------ memory

/// Something durable the tutor learned about the learner ("works as a nurse").
class MemoryFact {
  const MemoryFact({required this.text, this.category = 'other', required this.firstSeen, required this.lastSeen, this.mentions = 1});
  final String text;

  /// 'personal' | 'work' | 'family' | 'hobby' | 'goal' | 'place' | 'other'
  final String category;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int mentions;

  MemoryFact seenAgain(DateTime now) => MemoryFact(text: text, category: category, firstSeen: firstSeen, lastSeen: now, mentions: mentions + 1);

  Map<String, dynamic> toJson() => {'t': text, 'c': category, 'f': firstSeen.toIso8601String(), 'l': lastSeen.toIso8601String(), 'm': mentions};
  factory MemoryFact.fromJson(Map<String, dynamic> j) => MemoryFact(
        text: '${j['t']}',
        category: (j['c'] ?? 'other') as String,
        firstSeen: DateTime.tryParse('${j['f']}') ?? DateTime(2026),
        lastSeen: DateTime.tryParse('${j['l']}') ?? DateTime(2026),
        mentions: (j['m'] ?? 1) as int,
      );
}

/// A recurring error pattern with a decaying weight, so fixed mistakes fade
/// from the tutor's focus (half-life [halfLifeDays]).
class MistakePattern {
  const MistakePattern({
    required this.lang,
    required this.tag,
    required this.explanation,
    this.examples = const [],
    this.count = 1,
    required this.lastSeen,
  });

  static const halfLifeDays = 14.0;

  /// Target language the mistake was made in.
  final String lang;

  /// Short grammar category, e.g. "verb conjugation", "articles", "word order".
  final String tag;
  final String explanation;

  /// "original → corrected", newest first, max 3.
  final List<String> examples;
  final int count;
  final DateTime lastSeen;

  String get key => '$lang|${tag.toLowerCase()}';

  double weight(DateTime now) {
    final days = now.difference(lastSeen).inHours / 24.0;
    return count * math.pow(2, -days / halfLifeDays).toDouble();
  }

  MistakePattern merge({required String explanation, String? example, required DateTime now}) => MistakePattern(
        lang: lang,
        tag: tag,
        explanation: explanation.isNotEmpty ? explanation : this.explanation,
        examples: [if (example != null && example.isNotEmpty) example, ...examples.where((e) => e != example)].take(3).toList(),
        count: count + 1,
        lastSeen: now,
      );

  Map<String, dynamic> toJson() => {'g': lang, 't': tag, 'x': explanation, 'e': examples, 'n': count, 'l': lastSeen.toIso8601String()};
  factory MistakePattern.fromJson(Map<String, dynamic> j) => MistakePattern(
        lang: (j['g'] ?? 'de') as String,
        tag: '${j['t']}',
        explanation: '${j['x'] ?? ''}',
        examples: [for (final e in (j['e'] as List? ?? [])) '$e'],
        count: (j['n'] ?? 1) as int,
        lastSeen: DateTime.tryParse('${j['l']}') ?? DateTime(2026),
      );
}

/// Summary of one past conversation, produced by the server's memory consolidation.
class Episode {
  const Episode({required this.date, required this.summary, this.topics = const []});
  final DateTime date;
  final String summary;
  final List<String> topics;

  Map<String, dynamic> toJson() => {'d': date.toIso8601String(), 's': summary, 't': topics};
  factory Episode.fromJson(Map<String, dynamic> j) =>
      Episode(date: DateTime.tryParse('${j['d']}') ?? DateTime(2026), summary: '${j['s']}', topics: [for (final t in (j['t'] as List? ?? [])) '$t']);
}

/// Long-term learner memory. Semantic (facts, interests, goals), procedural
/// (mistake patterns), episodic (conversation summaries) and a profile summary
/// written by the server-side consolidation.
class LearnerMemory {
  const LearnerMemory({
    this.facts = const [],
    this.mistakes = const {},
    this.interests = const [],
    this.goals = const [],
    this.episodes = const [],
    this.summary = '',
    this.estimatedLevel = '',
    this.focus = const [],
    this.updatedAt,
  });

  final List<MemoryFact> facts;

  /// MistakePattern.key → pattern
  final Map<String, MistakePattern> mistakes;
  final List<String> interests;
  final List<String> goals;
  final List<Episode> episodes;

  /// One-paragraph learner profile from the server.
  final String summary;

  /// CEFR level the server estimates from recent writing ('' = unknown).
  final String estimatedLevel;

  /// What the tutor should focus on next (server suggestion).
  final List<String> focus;
  final DateTime? updatedAt;

  bool get isEmpty => facts.isEmpty && mistakes.isEmpty && interests.isEmpty && goals.isEmpty && episodes.isEmpty && summary.isEmpty;

  LearnerMemory copyWith({
    List<MemoryFact>? facts,
    Map<String, MistakePattern>? mistakes,
    List<String>? interests,
    List<String>? goals,
    List<Episode>? episodes,
    String? summary,
    String? estimatedLevel,
    List<String>? focus,
    DateTime? updatedAt,
  }) =>
      LearnerMemory(
        facts: facts ?? this.facts,
        mistakes: mistakes ?? this.mistakes,
        interests: interests ?? this.interests,
        goals: goals ?? this.goals,
        episodes: episodes ?? this.episodes,
        summary: summary ?? this.summary,
        estimatedLevel: estimatedLevel ?? this.estimatedLevel,
        focus: focus ?? this.focus,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Strongest current mistake patterns for [lang] (decayed by recency).
  List<MistakePattern> topMistakes(String lang, DateTime now, [int n = 8]) {
    final list = mistakes.values.where((m) => m.lang == lang).toList()..sort((a, b) => b.weight(now).compareTo(a.weight(now)));
    return list.take(n).toList();
  }

  Map<String, dynamic> toJson() => {
        'v': 2,
        'facts': [for (final f in facts) f.toJson()],
        'mistakes': [for (final m in mistakes.values) m.toJson()],
        'interests': interests,
        'goals': goals,
        'episodes': [for (final e in episodes) e.toJson()],
        'summary': summary,
        'estimatedLevel': estimatedLevel,
        'focus': focus,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// Reads v2 and migrates v1 (facts as strings, mistakes as {explanation: count}).
  factory LearnerMemory.fromJson(Map<String, dynamic> j) {
    final now = DateTime.now();
    final rawFacts = j['facts'] as List? ?? [];
    final facts = [
      for (final f in rawFacts)
        if (f is Map) MemoryFact.fromJson(Map<String, dynamic>.from(f)) else MemoryFact(text: '$f', firstSeen: now, lastSeen: now)
    ];
    final mistakes = <String, MistakePattern>{};
    final rawM = j['mistakes'];
    if (rawM is List) {
      for (final m in rawM) {
        final p = MistakePattern.fromJson(Map<String, dynamic>.from(m as Map));
        mistakes[p.key] = p;
      }
    } else if (rawM is Map) {
      for (final e in rawM.entries) {
        final p = MistakePattern(lang: 'de', tag: '${e.key}', explanation: '${e.key}', count: (e.value as num).toInt(), lastSeen: now);
        mistakes[p.key] = p;
      }
    }
    return LearnerMemory(
      facts: facts,
      mistakes: mistakes,
      interests: [for (final x in (j['interests'] as List? ?? [])) '$x'],
      goals: [for (final x in (j['goals'] as List? ?? [])) '$x'],
      episodes: [for (final e in (j['episodes'] as List? ?? [])) Episode.fromJson(Map<String, dynamic>.from(e as Map))],
      summary: (j['summary'] ?? '') as String,
      estimatedLevel: (j['estimatedLevel'] ?? '') as String,
      focus: [for (final x in (j['focus'] as List? ?? [])) '$x'],
      updatedAt: DateTime.tryParse('${j['updatedAt']}'),
    );
  }
}

// ---------------------------------------------------------------- progress

/// Best result of one lesson.
class LessonResult {
  const LessonResult({required this.stars, required this.score, required this.completedAt});

  /// 1..3
  final int stars;

  /// 0..100 accuracy
  final int score;
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {'s': stars, 'p': score, 'd': completedAt.toIso8601String()};
  factory LessonResult.fromJson(Map<String, dynamic> j) =>
      LessonResult(stars: j['s'] as int, score: j['p'] as int, completedAt: DateTime.tryParse('${j['d']}') ?? DateTime(2026));
}

class Correction {
  const Correction({required this.original, required this.corrected, required this.explanation, this.tag = ''});
  final String original;
  final String corrected;
  final String explanation;

  /// Short grammar category from the AI ("articles", "word order", …).
  final String tag;

  Map<String, dynamic> toJson() => {'original': original, 'corrected': corrected, 'explanation': explanation, if (tag.isNotEmpty) 'tag': tag};
  factory Correction.fromJson(Map<String, dynamic> j) => Correction(
      original: '${j['original'] ?? ''}', corrected: '${j['corrected'] ?? ''}', explanation: '${j['explanation'] ?? ''}', tag: '${j['tag'] ?? ''}');
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromUser,
    required this.text,
    this.native = '',
    this.corrections = const [],
    this.newWords = const [],
    this.suggestions = const [],
    this.rating = 0,
    this.offline = false,
  });

  final String id;
  final bool fromUser;
  final String text;

  /// Native-language translation of an assistant message.
  final String native;
  final List<Correction> corrections;
  final List<Word> newWords;
  final List<String> suggestions;

  /// -1, 0, 1 (thumbs)
  final int rating;
  final bool offline;

  ChatMessage copyWith({int? rating}) => ChatMessage(
      id: id,
      fromUser: fromUser,
      text: text,
      native: native,
      corrections: corrections,
      newWords: newWords,
      suggestions: suggestions,
      rating: rating ?? this.rating,
      offline: offline);

  Map<String, dynamic> toJson() => {
        'id': id,
        'u': fromUser,
        't': text,
        'n': native,
        'c': [for (final c in corrections) c.toJson()],
        'w': [for (final w in newWords) w.toJson()],
        's': suggestions,
        'r': rating,
        'o': offline,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        fromUser: j['u'] as bool,
        text: j['t'] as String,
        native: (j['n'] ?? '') as String,
        corrections: [for (final c in (j['c'] as List? ?? [])) Correction.fromJson(Map<String, dynamic>.from(c as Map))],
        newWords: [for (final w in (j['w'] as List? ?? [])) Word.fromJson(Map<String, dynamic>.from(w as Map))],
        suggestions: [for (final s in (j['s'] as List? ?? [])) '$s'],
        rating: (j['r'] ?? 0) as int,
        offline: (j['o'] ?? false) as bool,
      );
}
