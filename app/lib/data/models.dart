const levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

class Word {
  const Word({
    required this.id,
    required this.de,
    required this.en,
    required this.tr,
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
  final String example;
  final String level;
  final String topic;
  final bool custom;

  String gloss(String lang) {
    final g = lang == 'tr' ? tr : en;
    return g.isNotEmpty ? g : (en.isNotEmpty ? en : tr);
  }

  /// "Tisch" for "der Tisch" — used to match words inside free text.
  String get lemma {
    final m = RegExp(r'^(der|die|das)\s+(.+)$', caseSensitive: false).firstMatch(de);
    return (m?.group(2) ?? de).toLowerCase();
  }

  static String idFor(String de) =>
      de.toLowerCase().replaceAll('ä', 'ae').replaceAll('ö', 'oe').replaceAll('ü', 'ue').replaceAll('ß', 'ss').replaceAll(RegExp(r'[^a-z0-9]+'), '_');

  Map<String, dynamic> toJson() => {'id': id, 'de': de, 'en': en, 'tr': tr, 'example': example, 'level': level, 'topic': topic, 'custom': custom};

  factory Word.fromJson(Map<String, dynamic> j) => Word(
        id: j['id'] as String,
        de: j['de'] as String,
        en: (j['en'] ?? '') as String,
        tr: (j['tr'] ?? '') as String,
        example: (j['example'] ?? '') as String,
        level: (j['level'] ?? 'A1') as String,
        topic: (j['topic'] ?? '') as String,
        custom: (j['custom'] ?? false) as bool,
      );
}

/// Spaced-repetition state of one word (SM-2 variant).
class CardState {
  CardState({
    required this.wordId,
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
  double ease;
  int intervalDays;
  int reps;
  int lapses;

  /// Lifetime outcome counts, also fed by tutor chat (word used correctly / corrected).
  int successes;
  int failures;
  DateTime due;
  DateTime? lastReviewed;

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
        'e': ease,
        'i': intervalDays,
        'r': reps,
        'l': lapses,
        's': successes,
        'f': failures,
        'd': due.toIso8601String(),
        'lr': lastReviewed?.toIso8601String(),
      };

  factory CardState.fromJson(Map<String, dynamic> j) => CardState(
        wordId: j['w'] as String,
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

class Profile {
  const Profile({
    this.onboarded = false,
    this.name = '',
    this.nativeLang = 'tr',
    this.level = 'A1',
    this.persona = 'bruno',
    this.dailyGoalXp = 50,
    this.xp = 0,
    this.todayXp = 0,
    this.streak = 0,
    this.lastActiveDay = '',
    this.serverUrl = '',
  });

  final bool onboarded;
  final String name;

  /// 'tr' | 'en' — explanations and translations are shown in this language.
  final String nativeLang;
  final String level;

  /// 'bruno' | 'fuchs' | 'brezel'
  final String persona;
  final int dailyGoalXp;
  final int xp;
  final int todayXp;
  final int streak;

  /// yyyy-MM-dd of the last day with activity.
  final String lastActiveDay;
  final String serverUrl;

  Profile copyWith({
    bool? onboarded,
    String? name,
    String? nativeLang,
    String? level,
    String? persona,
    int? dailyGoalXp,
    int? xp,
    int? todayXp,
    int? streak,
    String? lastActiveDay,
    String? serverUrl,
  }) =>
      Profile(
        onboarded: onboarded ?? this.onboarded,
        name: name ?? this.name,
        nativeLang: nativeLang ?? this.nativeLang,
        level: level ?? this.level,
        persona: persona ?? this.persona,
        dailyGoalXp: dailyGoalXp ?? this.dailyGoalXp,
        xp: xp ?? this.xp,
        todayXp: todayXp ?? this.todayXp,
        streak: streak ?? this.streak,
        lastActiveDay: lastActiveDay ?? this.lastActiveDay,
        serverUrl: serverUrl ?? this.serverUrl,
      );

  Map<String, dynamic> toJson() => {
        'onboarded': onboarded,
        'name': name,
        'nativeLang': nativeLang,
        'level': level,
        'persona': persona,
        'dailyGoalXp': dailyGoalXp,
        'xp': xp,
        'todayXp': todayXp,
        'streak': streak,
        'lastActiveDay': lastActiveDay,
        'serverUrl': serverUrl,
      };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        onboarded: (j['onboarded'] ?? false) as bool,
        name: (j['name'] ?? '') as String,
        nativeLang: (j['nativeLang'] ?? 'tr') as String,
        level: (j['level'] ?? 'A1') as String,
        persona: (j['persona'] ?? 'bruno') as String,
        dailyGoalXp: (j['dailyGoalXp'] ?? 50) as int,
        xp: (j['xp'] ?? 0) as int,
        todayXp: (j['todayXp'] ?? 0) as int,
        streak: (j['streak'] ?? 0) as int,
        lastActiveDay: (j['lastActiveDay'] ?? '') as String,
        serverUrl: (j['serverUrl'] ?? '') as String,
      );
}

/// What the AI "remembers" about the learner besides per-word SRS state.
class LearnerMemory {
  const LearnerMemory({this.facts = const [], this.mistakes = const {}});

  /// e.g. "works as a nurse", "likes football"
  final List<String> facts;

  /// explanation → times seen
  final Map<String, int> mistakes;

  LearnerMemory copyWith({List<String>? facts, Map<String, int>? mistakes}) =>
      LearnerMemory(facts: facts ?? this.facts, mistakes: mistakes ?? this.mistakes);

  List<String> topMistakes([int n = 8]) {
    final e = mistakes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return [for (final x in e.take(n)) x.key];
  }

  Map<String, dynamic> toJson() => {'facts': facts, 'mistakes': mistakes};
  factory LearnerMemory.fromJson(Map<String, dynamic> j) => LearnerMemory(
        facts: [for (final f in (j['facts'] as List? ?? [])) '$f'],
        mistakes: {for (final e in ((j['mistakes'] as Map?) ?? {}).entries) '${e.key}': e.value as int},
      );
}

class Correction {
  const Correction({required this.original, required this.corrected, required this.explanation});
  final String original;
  final String corrected;
  final String explanation;

  Map<String, dynamic> toJson() => {'original': original, 'corrected': corrected, 'explanation': explanation};
  factory Correction.fromJson(Map<String, dynamic> j) =>
      Correction(original: '${j['original'] ?? ''}', corrected: '${j['corrected'] ?? ''}', explanation: '${j['explanation'] ?? ''}');
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
