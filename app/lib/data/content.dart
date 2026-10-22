import 'models.dart';

Word _wordFromJson(Map<String, dynamic> j, {String level = 'A1', String topic = ''}) {
  final de = '${j['de'] ?? ''}'.trim();
  return Word(id: Word.idFor(de), de: de, en: '${j['en'] ?? ''}', tr: '${j['tr'] ?? ''}', level: level, topic: topic, custom: true);
}

List<Word> _words(Object? v, {String level = 'A1', String topic = ''}) => [
      for (final w in (v as List? ?? []))
        if (w is Map && '${w['de'] ?? ''}'.trim().isNotEmpty) _wordFromJson(Map<String, dynamic>.from(w), level: level, topic: topic)
    ];

class ChatReply {
  const ChatReply({
    required this.id,
    required this.reply,
    this.replyNative = '',
    this.corrections = const [],
    this.newWords = const [],
    this.usedKnownWords = const [],
    this.suggestions = const [],
    this.newFacts = const [],
    this.mood = 'happy',
    this.offline = false,
  });

  final String id;
  final String reply;
  final String replyNative;
  final List<Correction> corrections;
  final List<Word> newWords;
  final List<String> usedKnownWords;
  final List<String> suggestions;
  final List<String> newFacts;
  final String mood;
  final bool offline;

  factory ChatReply.fromJson(Map<String, dynamic> j, {String level = 'A1'}) => ChatReply(
        id: '${j['id'] ?? DateTime.now().microsecondsSinceEpoch}',
        reply: '${j['reply'] ?? ''}',
        replyNative: '${j['replyNative'] ?? ''}',
        corrections: [
          for (final c in (j['corrections'] as List? ?? []))
            if (c is Map) Correction.fromJson(Map<String, dynamic>.from(c))
        ],
        newWords: _words(j['newWords'], level: level, topic: 'chat'),
        usedKnownWords: [for (final w in (j['usedKnownWords'] as List? ?? [])) '$w'],
        suggestions: [for (final s in (j['suggestions'] as List? ?? [])) '$s'],
        newFacts: [for (final s in (j['newFacts'] as List? ?? [])) '$s'],
        mood: '${j['mood'] ?? 'happy'}',
      );
}

class Translation {
  const Translation({required this.translation, this.notes = '', this.words = const []});
  final String translation;
  final String notes;
  final List<Word> words;

  factory Translation.fromJson(Map<String, dynamic> j) =>
      Translation(translation: '${j['translation'] ?? ''}', notes: '${j['notes'] ?? ''}', words: _words(j['words'], topic: 'translator'));
}

class NewsItem {
  const NewsItem({required this.id, required this.source, required this.title, required this.summary, required this.link, this.published});
  final String id;
  final String source;
  final String title;
  final String summary;
  final String link;
  final DateTime? published;

  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
        id: '${j['id']}',
        source: '${j['source'] ?? ''}',
        title: '${j['title'] ?? ''}',
        summary: '${j['summary'] ?? ''}',
        link: '${j['link'] ?? ''}',
        published: DateTime.tryParse('${j['published'] ?? ''}'),
      );
}

class SimplifiedArticle {
  const SimplifiedArticle({required this.german, required this.translation, this.cultureNote = '', this.keywords = const []});
  final String german;
  final String translation;
  final String cultureNote;
  final List<Word> keywords;

  factory SimplifiedArticle.fromJson(Map<String, dynamic> j, {String level = 'A2'}) => SimplifiedArticle(
        german: '${j['german'] ?? ''}',
        translation: '${j['translation'] ?? ''}',
        cultureNote: '${j['cultureNote'] ?? ''}',
        keywords: _words(j['keywords'], level: level, topic: 'news'),
      );
}

class Meme {
  const Meme({required this.id, required this.top, required this.bottom, this.theme = '', this.emoji = '🥨', this.explanation = '', this.explanationTr = '', this.vocab = const []});
  final String id;
  final String top;
  final String bottom;
  final String theme;
  final String emoji;
  final String explanation;

  /// Only set for bundled memes; server memes are already written in the learner's language.
  final String explanationTr;
  final List<Word> vocab;

  String explain(String lang) => lang == 'tr' && explanationTr.isNotEmpty ? explanationTr : explanation;

  factory Meme.fromJson(Map<String, dynamic> j, {String level = 'A2'}) => Meme(
        id: '${j['id']}',
        top: '${j['top'] ?? ''}',
        bottom: '${j['bottom'] ?? ''}',
        theme: '${j['theme'] ?? ''}',
        emoji: '${j['emoji'] ?? '🥨'}',
        explanation: '${j['explanation'] ?? ''}',
        vocab: _words(j['vocab'], level: level, topic: 'meme'),
      );
}
