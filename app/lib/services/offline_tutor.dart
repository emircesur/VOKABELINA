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
    final pool = learner.pickWeak(3, rng: r).isNotEmpty ? learner.pickWeak(3, rng: r) : learner.words.values.where((w) => w.level == profile.level).toList();
    final word = pool.isEmpty ? null : pool[r.nextInt(pool.length)];
    final tr = profile.nativeLang == 'tr';

    if (firstTurn || word == null) {
      return ChatReply(
        id: 'off-${DateTime.now().microsecondsSinceEpoch}',
        reply: persona.hello,
        replyNative: tr ? '(Çevrimdışı mod) Merhaba! Adın ne?' : '(Offline mode) Hello! What is your name?',
        suggestions: const ['Ich heiße Anna.', 'Ich bin neu hier.'],
        mood: 'happy',
        offline: true,
      );
    }
    final ask = 'Kennst du das Wort „${word.de}“? Bilde einen Satz damit!';
    return ChatReply(
      id: 'off-${DateTime.now().microsecondsSinceEpoch}',
      reply: ask,
      replyNative: tr ? '(Çevrimdışı) „${word.de}“ = ${word.tr}. Onunla bir cümle kur!' : '(Offline) "${word.de}" = ${word.en}. Make a sentence with it!',
      suggestions: [if (word.example.isNotEmpty) word.example],
      mood: 'thinking',
      offline: true,
    );
  }
}
