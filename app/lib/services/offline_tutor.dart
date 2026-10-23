import 'dart:math';

import '../data/content.dart';
import '../data/models.dart';
import '../data/personas.dart';
import 'learner.dart';

/// Scripted fallback when no AI server is reachable, so the app stays usable.
/// It drills the learner's own words; it is deliberately simple and labelled offline.
class OfflineTutor {
  ChatReply reply({required Profile profile, required Learner learner, required String userText, required bool firstTurn, Random? rng}) {
    final r = rng ?? Random();
    final persona = personaOf(profile.persona);
    final target = profile.targetLang;
    final native = profile.nativeLang;
    final weak = learner.pickWeak(3, rng: r);
    final pool = weak.isNotEmpty ? weak : learner.words.values.where((w) => w.level == profile.level && !w.custom).toList();
    final word = pool.isEmpty ? null : pool[r.nextInt(pool.length)];
    String n(String en, String tr, String de) => switch (native) { 'tr' => tr, 'de' => de, _ => en };

    if (firstTurn || word == null) {
      final hello = switch (target) {
        'en' => "Hi! I'm ${persona.name}. What's your name?",
        'tr' => 'Merhaba! Ben ${persona.name}. Adın ne?',
        _ => persona.hello,
      };
      return ChatReply(
        id: 'off-${DateTime.now().microsecondsSinceEpoch}',
        reply: hello,
        replyNative: n('(Offline mode) Hello! What is your name?', '(Çevrimdışı mod) Merhaba! Adın ne?', '(Offline-Modus) Hallo! Wie heißt du?'),
        suggestions: switch (target) {
          'en' => const ["I'm Anna.", "I'm new here."],
          'tr' => const ['Ben Anna.', 'Burada yeniyim.'],
          _ => const ['Ich heiße Anna.', 'Ich bin neu hier.'],
        },
        mood: 'happy',
        offline: true,
      );
    }
    final t = word.inLang(target);
    final ask = switch (target) {
      'en' => 'Do you know the word "$t"? Make a sentence with it!',
      'tr' => '"$t" kelimesini biliyor musun? Onunla bir cümle kur!',
      _ => 'Kennst du das Wort „$t“? Bilde einen Satz damit!',
    };
    return ChatReply(
      id: 'off-${DateTime.now().microsecondsSinceEpoch}',
      reply: ask,
      replyNative: n('(Offline) "$t" = ${word.gloss('en')}. Make a sentence with it!', '(Çevrimdışı) „$t“ = ${word.gloss('tr')}. Onunla bir cümle kur!',
          '(Offline) „$t“ = ${word.de}. Bilde einen Satz damit!'),
      suggestions: [if (target == 'de' && word.example.isNotEmpty) word.example],
      mood: 'thinking',
      offline: true,
    );
  }
}
