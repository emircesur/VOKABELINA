import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/personas.dart';
import '../../services/lessons.dart';
import '../../services/placement.dart';
import '../../state/providers.dart';
import '../../widgets/anim.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/juice.dart';
import '../../widgets/mascot.dart';
import '../home/shell.dart';

/// Endonyms: every language is offered in its own words, so nobody starts in a language they can't read.
const _ownName = {'de': 'Deutsch', 'en': 'English', 'tr': 'Türkçe'};
const _ownSub = {'de': 'Die App auf Deutsch nutzen', 'en': 'Use the app in English', 'tr': 'Uygulamayı Türkçe kullan'};

enum _Step { language, target, why, level, interests, tutor, goal, name, ready }

class _Pick {
  const _Pick(this.id, this.emoji, this.en, this.tr, this.de);
  final String id, emoji, en, tr, de;
  String label(String lang) => tr3(lang, en, tr, de);
}

const _motivations = [
  _Pick('travel', '✈️', 'Travel', 'Seyahat', 'Reisen'),
  _Pick('work', '💼', 'Career & work', 'Kariyer ve iş', 'Beruf & Karriere'),
  _Pick('abroad', '🏡', 'Living abroad', 'Yurt dışında yaşamak', 'Leben im Ausland'),
  _Pick('family', '💞', 'Family & friends', 'Aile ve arkadaşlar', 'Familie & Freunde'),
  _Pick('culture', '🎬', 'Culture & media', 'Kültür ve medya', 'Kultur & Medien'),
  _Pick('school', '🎓', 'School & exams', 'Okul ve sınavlar', 'Schule & Prüfungen'),
  _Pick('brain', '🧠', 'Brain training', 'Beyin egzersizi', 'Gehirntraining'),
  _Pick('fun', '🎉', 'Just for fun', 'Sadece eğlence', 'Einfach aus Spaß'),
];

const _interestPicks = [
  _Pick('football', '⚽', 'Football', 'Futbol', 'Fußball'),
  _Pick('music', '🎵', 'Music', 'Müzik', 'Musik'),
  _Pick('cooking', '🍳', 'Cooking', 'Yemek', 'Kochen'),
  _Pick('travel', '🌍', 'Travel', 'Gezi', 'Reisen'),
  _Pick('tech', '💻', 'Tech', 'Teknoloji', 'Technik'),
  _Pick('movies', '🎬', 'Movies & series', 'Film ve dizi', 'Filme & Serien'),
  _Pick('history', '🏛️', 'History', 'Tarih', 'Geschichte'),
  _Pick('nature', '🌲', 'Nature', 'Doğa', 'Natur'),
  _Pick('art', '🎨', 'Art', 'Sanat', 'Kunst'),
  _Pick('gaming', '🎮', 'Gaming', 'Oyun', 'Gaming'),
  _Pick('fashion', '👗', 'Fashion', 'Moda', 'Mode'),
  _Pick('science', '🔬', 'Science', 'Bilim', 'Wissenschaft'),
  _Pick('animals', '🐶', 'Animals', 'Hayvanlar', 'Tiere'),
  _Pick('books', '📚', 'Books', 'Kitaplar', 'Bücher'),
];

/// (xp, minutes, emoji, en, tr, de)
const _goals = [
  (20, 5, '☕', 'Casual', 'Rahat', 'Locker'),
  (50, 10, '🚶', 'Regular', 'Düzenli', 'Regelmäßig'),
  (100, 15, '🏃', 'Serious', 'Ciddi', 'Ernsthaft'),
  (150, 20, '🚀', 'Intense', 'Yoğun', 'Intensiv'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingState();
}

class _OnboardingState extends ConsumerState<OnboardingScreen> {
  _Step step = _Step.language;
  bool forward = true;
  String? nativeLang;
  String? targetLang;
  String? level;
  String persona = 'bruno';
  int goal = 50;
  final why = <String>{};
  final interests = <String>{};
  final _name = TextEditingController();
  final _tutorPager = PageController(viewportFraction: 0.82);
  Timer? _advance;

  // placement check
  List<PlacementQuestion>? quiz;
  int qi = 0;
  String? picked;
  final correct = <String, int>{};
  String? placed;

  String get ui => nativeLang ?? 'en';
  String t(String en, String trk, [String? de]) => tr3(ui, en, trk, de);
  String get target => targetLang ?? 'de';
  Persona get tutor => personaOf(persona);

  @override
  void dispose() {
    _advance?.cancel();
    _name.dispose();
    _tutorPager.dispose();
    super.dispose();
  }

  void _go(_Step s) {
    _advance?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      forward = s.index > step.index;
      step = s;
    });
  }

  void _next() {
    HapticFeedback.lightImpact();
    _go(_Step.values[step.index + 1]);
  }

  void _back() {
    if (quiz != null && placed == null) {
      setState(() => quiz = null);
      return;
    }
    if (step.index > 0) _go(_Step.values[step.index - 1]);
  }

  /// Choosing a language moves on by itself after a short beat, so the choice can be seen.
  void _autoNext() {
    _advance?.cancel();
    _advance = Timer(const Duration(milliseconds: 380), () {
      if (mounted) _next();
    });
  }

  void _finish({required bool startLesson}) {
    HapticFeedback.mediumImpact();
    final old = ref.read(profileProvider);
    final lvl = level ?? 'A1';
    final mem = ref.read(memoryProvider.notifier);
    if (why.isNotEmpty) mem.setGoals([for (final m in _motivations) if (why.contains(m.id)) m.label(ui)]);
    if (interests.isNotEmpty) mem.setInterests([for (final i in _interestPicks) if (interests.contains(i.id)) i.label(ui)]);
    final next = startLesson ? CourseStatus(target, lvl, ref.read(progressProvider)).next()?.$2 : null;
    if (next != null) {
      // the router leaves onboarding by itself once the profile is set; the shell then opens this
      ref.read(launchProvider.notifier).set(switch (next.kind) {
        LessonKind.speak => '/roleplay/${next.unitId}',
        LessonKind.write => '/write/${next.unitId}',
        _ => '/lesson/${next.id}',
      });
    }
    ref.read(profileProvider.notifier).set(Profile(
          onboarded: true,
          name: _name.text.trim(),
          nativeLang: ui,
          targetLang: target,
          level: lvl,
          persona: persona,
          dailyGoalXp: goal,
          serverUrl: old.serverUrl,
          cloudMemory: old.cloudMemory,
        ));
  }

  List<Color> get _bgColors => switch (step) {
    _Step.tutor || _Step.name => [tutor.body, tutor.accent, tutor.belly],
    _Step.ready => const [Brand.gold, Brand.green, Brand.teal, Brand.red],
    _ => const [Brand.gold, Brand.teal, Brand.red],
  };

  @override
  Widget build(BuildContext context) {
    final quizRunning = step == _Step.level && quiz != null && placed == null;
    return PopScope(
      canPop: step == _Step.language,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: FloatingBackground(
          colors: _bgColors,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    if (step != _Step.language) _header(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, ?cur]),
                        transitionBuilder: (c, a) {
                          final incoming = c.key == ValueKey(step);
                          final dx = (incoming == forward) ? 0.25 : -0.25;
                          return FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(a),
                              child: c,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(step),
                          child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: _page()),
                        ),
                      ),
                    ),
                    if (!quizRunning) _bottom(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final total = _Step.values.length - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 20, 0),
      child: Row(
        children: [
          IconButton(onPressed: _back, tooltip: t('Back', 'Geri', 'Zurück'), icon: const Icon(Icons.arrow_back_rounded)),
          Expanded(
            child: Semantics(
              label: t('Step ${step.index} of $total', 'Adım ${step.index} / $total', 'Schritt ${step.index} von $total'),
              child: ExcludeSemantics(
                child: MascotProgress(
                  value: step.index / total,
                  color: step == _Step.tutor || step == _Step.name ? tutor.accent : Brand.gold,
                  mascot: Mascot(personaId: persona, mood: step == _Step.ready ? 'cheer' : 'happy', size: 40),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottom() {
    final turkish = ui == 'tr';
    Widget button(String label, VoidCallback? onTap) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: SizedBox(
        width: double.infinity,
        child: ChunkyButton(turkishCase: turkish, label: label, onPressed: onTap),
      ),
    );
    return switch (step) {
      // language choices advance by themselves
      _Step.language || _Step.target => const SizedBox(height: 16),
      _Step.why => button(why.isEmpty ? t('Skip', 'Geç', 'Überspringen') : t('Continue', 'Devam', 'Weiter'), _next),
      _Step.level => button(t('Continue', 'Devam', 'Weiter'), level == null ? null : _next),
      _Step.interests => button(interests.isEmpty ? t('Skip', 'Geç', 'Überspringen') : t('Continue', 'Devam', 'Weiter'), _next),
      _Step.name => button(_name.text.trim().isEmpty ? t('Skip', 'Geç', 'Überspringen') : t('Continue', 'Devam', 'Weiter'), _next),
      _Step.ready => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ChunkyButton(
                turkishCase: turkish,
                icon: Icons.play_arrow_rounded,
                color: Brand.green,
                label: t('Start my first lesson', 'İlk dersime başla', 'Erste Lektion starten'),
                onPressed: () => _finish(startLesson: true),
              ),
            ),
            TextButton(onPressed: () => _finish(startLesson: false), child: Text(t('Look around first', 'Önce etrafa bakayım', 'Erst mal umschauen'))),
          ],
        ),
      ),
      _ => button(t('Continue', 'Devam', 'Weiter'), _next),
    };
  }

  Widget _page() => switch (step) {
    _Step.language => _languagePage(),
    _Step.target => _targetPage(),
    _Step.why => _whyPage(),
    _Step.level => quiz == null ? _levelPage() : (placed == null ? _quizPage() : _placedPage()),
    _Step.interests => _interestsPage(),
    _Step.tutor => _tutorPage(),
    _Step.goal => _goalPage(),
    _Step.name => _namePage(),
    _Step.ready => _readyPage(),
  };

  Widget _title(String text, [String? sub]) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 18),
    child: Column(
      children: [
        SlideFadeIn(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, height: 1.15),
          ),
        ),
        if (sub != null)
          SlideFadeIn(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                sub,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).hintColor, fontSize: 15),
              ),
            ),
          ),
      ],
    ),
  );

  /// Mascot with a speech bubble — the tutor "talks" through onboarding.
  Widget _says(String text, {String mood = 'happy', double size = 76, bool type = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Mascot(personaId: persona, mood: mood, size: size),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(text),
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18), bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: type
                  ? Typewriter(
                      text: text,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    )
                  : Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ],
    ),
  );

  // ------------------------------------------------------------------ steps

  Widget _languagePage() => Column(
    children: [
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, p) in personas.values.indexed)
            PopIn(
              delay: Duration(milliseconds: 120 * i),
              child: Mascot(personaId: p.id, mood: nativeLang == null ? 'wave' : 'cheer', size: i == 1 ? 120 : 92),
            ),
        ],
      ),
      const SizedBox(height: 14),
      const SizedBox(
        height: 46,
        child: RotatingText(
          texts: ['Hallo!', 'Hello!', 'Merhaba!'],
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
      ),
      SizedBox(
        height: 26,
        child: RotatingText(
          texts: const ['Welche Sprache sprichst du?', 'Which language do you speak?', 'Hangi dili konuşuyorsun?'],
          style: TextStyle(fontSize: 16, color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 22),
      for (final (i, l) in const ['de', 'en', 'tr'].indexed)
        SlideFadeIn(
          index: i + 2,
          child: _Tile(
            selected: nativeLang == l,
            leading: Wiggle(
              enabled: nativeLang == l,
              child: Text(langFlags[l]!, style: const TextStyle(fontSize: 34)),
            ),
            title: _ownName[l]!,
            sub: _ownSub[l]!,
            onTap: () {
              setState(() {
                nativeLang = l;
                if (targetLang == l) targetLang = null;
              });
              _autoNext();
            },
          ),
        ),
      const SizedBox(height: 6),
      PopIn(
        delay: const Duration(milliseconds: 600),
        child: Text(
          '🇩🇪 · 🇬🇧 · 🇹🇷   Vokabelina',
          style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ),
    ],
  );

  Widget _targetPage() {
    final facts = {
      'de': t("≈130 million speakers · the EU's most spoken mother tongue", "≈130 milyon konuşan · AB'nin en çok konuşulan ana dili", 'ca. 130 Mio. Sprecher · meistgesprochene Muttersprache der EU'),
      'en': t("≈1.5 billion speakers · the world's common language", '≈1,5 milyar konuşan · dünyanın ortak dili', 'ca. 1,5 Mrd. Sprecher · die Weltsprache'),
      'tr': t('≈90 million speakers · about 3 million in Germany', "≈90 milyon konuşan · Almanya'da yaklaşık 3 milyon", 'ca. 90 Mio. Sprecher · rund 3 Mio. in Deutschland'),
    };
    final options = [
      for (final l in targetLangs)
        if (l != nativeLang) l,
    ];
    return Column(
      children: [
        _title(
          t('I want to learn…', 'Öğrenmek istiyorum…', 'Ich möchte lernen…'),
          t('You can switch or learn more later.', 'Sonra değiştirebilir ya da başka dil ekleyebilirsin.', 'Du kannst später wechseln oder mehr lernen.'),
        ),
        for (final (i, l) in options.indexed)
          SlideFadeIn(
            index: i,
            child: _Tile(
              selected: targetLang == l,
              big: true,
              leading: Wiggle(child: Text(langFlags[l]!, style: const TextStyle(fontSize: 44))),
              title: _ownName[l]!,
              badge: langNames[l]![ui],
              sub: facts[l],
              onTap: () {
                setState(() => targetLang = l);
                _autoNext();
              },
            ),
          ),
      ],
    );
  }

  Widget _whyPage() => Column(
    children: [
      _title(
        t('Why are you learning ${langNames[target]![ui]}?', '${langNames[target]![ui]} neden öğreniyorsun?', 'Warum lernst du ${langNames[target]![ui]}?'),
        t('Pick as many as you like.', 'İstediğin kadar seç.', 'Wähle so viele du willst.'),
      ),
      _says(
        why.isEmpty
            ? t("Tell me — I'll tailor lessons and chats to it.", 'Söyle bana — dersleri ve sohbetleri buna göre ayarlarım.', 'Sag es mir – ich passe Lektionen und Chats daran an.')
            : t("Noted! I'll remember that 🧠", 'Not ettim! Bunu hatırlayacağım 🧠', 'Notiert! Das merke ich mir 🧠'),
        mood: why.isEmpty ? 'thinking' : 'happy',
      ),
      _grid(_motivations, why),
    ],
  );

  Widget _grid(List<_Pick> picks, Set<String> chosen) => LayoutBuilder(
    builder: (context, box) {
      final w = (box.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (i, p) in picks.indexed)
            SizedBox(
              width: w,
              child: SlideFadeIn(
                index: i,
                child: _Chip(emoji: p.emoji, label: p.label(ui), selected: chosen.contains(p.id), onTap: () => setState(() => chosen.contains(p.id) ? chosen.remove(p.id) : chosen.add(p.id))),
              ),
            ),
        ],
      );
    },
  );

  Widget _levelPage() {
    final options = [
      ('A1', '🌱', t("I'm new to it", 'Yeni başlıyorum', 'Ich fange neu an'), t('I know a few words at most', 'En fazla birkaç kelime biliyorum', 'Ich kenne höchstens ein paar Wörter')),
      (
        'A2',
        '🌿',
        t('I know the basics', 'Temelleri biliyorum', 'Ich kenne die Grundlagen'),
        t('Simple sentences about everyday life', 'Günlük hayatla ilgili basit cümleler', 'Einfache Sätze über den Alltag'),
      ),
      (
        'B1',
        '🌳',
        t('I can have conversations', 'Sohbet edebiliyorum', 'Ich kann mich unterhalten'),
        t('Travel, work and my opinions', 'Seyahat, iş ve fikirlerim', 'Reisen, Arbeit und meine Meinung'),
      ),
      ('B2', '🏔️', t("I'm quite fluent", 'Oldukça akıcıyım', 'Ich bin ziemlich fließend'), t('I want to polish and keep it up', 'Cilalamak ve korumak istiyorum', 'Ich will feilen und dranbleiben')),
    ];
    return Column(
      children: [
        _title(
          t('How much ${langNames[target]![ui]} do you know?', 'Ne kadar ${langNames[target]![ui]} biliyorsun?', 'Wie viel ${langNames[target]![ui]} kannst du?'),
          t(
            'Easier units stay open, and the AI keeps adapting.',
            'Kolay üniteler açık kalır, yapay zekâ uyum sağlamaya devam eder.',
            'Leichtere Einheiten bleiben offen, die KI passt sich laufend an.',
          ),
        ),
        for (final (i, o) in options.indexed)
          SlideFadeIn(
            index: i,
            child: _Tile(
              selected: level == o.$1,
              leading: Text(o.$2, style: const TextStyle(fontSize: 30)),
              title: o.$3,
              sub: o.$4,
              badge: o.$1,
              onTap: () => setState(() => level = o.$1),
            ),
          ),
        SlideFadeIn(
          index: 5,
          child: _Tile(
            selected: false,
            accent: Brand.teal,
            leading: const Pulse(child: Text('🎯', style: TextStyle(fontSize: 30))),
            title: t('Not sure? Take the 1-minute test', 'Emin değil misin? 1 dakikalık test', 'Unsicher? 1-Minuten-Test'),
            sub: t('9 quick words, from easy to hard', 'Kolaydan zora 9 hızlı kelime', '9 schnelle Wörter, von leicht bis schwer'),
            onTap: () => setState(() {
              quiz = buildPlacement(target: target, native: ui, seed: DateTime.now().millisecondsSinceEpoch);
              qi = 0;
              picked = null;
              placed = null;
              correct.clear();
            }),
          ),
        ),
      ],
    );
  }

  void _answer(String? option) {
    if (picked != null) return;
    final q = quiz![qi];
    final ok = option == q.answer;
    if (ok) correct[q.level] = (correct[q.level] ?? 0) + 1;
    ok ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
    setState(() => picked = option ?? '');
    _advance = Timer(Duration(milliseconds: ok ? 550 : 1000), () {
      if (!mounted) return;
      setState(() {
        picked = null;
        if (qi + 1 < quiz!.length) {
          qi++;
        } else {
          placed = placementLevel(correct);
          level = placed;
          HapticFeedback.mediumImpact();
        }
      });
    });
  }

  Widget _quizPage() {
    final q = quiz![qi];
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < quiz!.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == qi ? 22 : 9,
                height: 9,
                decoration: BoxDecoration(color: i <= qi ? Brand.teal : cs.outlineVariant, borderRadius: BorderRadius.circular(6)),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          t('What does this mean?', 'Bu ne demek?', 'Was bedeutet das?'),
          style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        PopIn(
          key: ValueKey('q$qi'),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: Brand.teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(
                  q.level,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Brand.teal, fontSize: 12),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                q.prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final (i, o) in q.options.indexed)
          SlideFadeIn(
            key: ValueKey('o$qi-$i'),
            index: i,
            child: Shake(
              trigger: picked == o && o != q.answer ? 1 : 0,
              child: _Tile(selected: picked != null && o == q.answer, wrong: picked == o && o != q.answer, title: o, onTap: picked == null ? () => _answer(o) : null),
            ),
          ),
        TextButton(onPressed: picked == null ? () => _answer(null) : null, child: Text(t("I don't know", 'Bilmiyorum', 'Weiß ich nicht'))),
      ],
    );
  }

  Widget _placedPage() {
    final right = correct.values.fold(0, (a, b) => a + b);
    final msg = switch (placed) {
      'B1' => t(
        "Impressive! We'll start you at B1 — the easier units stay open.",
        'Etkileyici! B1’den başlıyorsun — kolay üniteler açık kalıyor.',
        'Beeindruckend! Du startest bei B1 – leichtere Einheiten bleiben offen.',
      ),
      'A2' => t('Nice! You already know the basics — starting at A2.', 'Güzel! Temelleri biliyorsun — A2’den başlıyoruz.', 'Super! Du kennst die Grundlagen – wir starten bei A2.'),
      _ => t("Perfect place to start — we'll build it up from A1 together.", 'Başlamak için harika bir yer — A1’den birlikte kuracağız.', 'Perfekter Start – wir bauen es ab A1 gemeinsam auf.'),
    };
    return Confetti(
      play: placed != 'A1',
      child: Column(
        children: [
          const SizedBox(height: 12),
          PopIn(
            child: Mascot(personaId: persona, mood: 'cheer', size: 130),
          ),
          const SizedBox(height: 8),
          PopIn(
            delay: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Brand.teal, Brand.green]),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: Brand.teal.withValues(alpha: 0.4), blurRadius: 18, offset: const Offset(0, 6))],
              ),
              child: Text(
                placed!,
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 12),
          CountUp(
            value: right,
            suffix: ' / ${quiz!.length} ${t('correct', 'doğru', 'richtig')}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          SlideFadeIn(
            index: 3,
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => setState(() => quiz = null), child: Text(t('Choose myself instead', 'Kendim seçeyim', 'Lieber selbst wählen'))),
        ],
      ),
    );
  }

  Widget _interestsPage() => Column(
    children: [
      _title(
        t('What do you love?', 'Nelerden hoşlanırsın?', 'Was magst du?'),
        t(
          'Your tutor talks about these, and stories and practice use them.',
          'Öğretmenin bunlardan konuşur; hikâyeler ve alıştırmalar bunları kullanır.',
          'Dein Tutor spricht darüber, Geschichten und Übungen nutzen sie.',
        ),
      ),
      _grid(_interestPicks, interests),
    ],
  );

  Widget _tutorPage() {
    final list = personas.values.toList();
    return Column(
      children: [
        _title(
          t('Pick your tutor', 'Öğretmenini seç', 'Wähle deinen Tutor'),
          t('Swipe — you can switch any time.', 'Kaydır — istediğin zaman değiştirebilirsin.', 'Wische – du kannst jederzeit wechseln.'),
        ),
        SizedBox(
          height: 390,
          child: PageView.builder(
            controller: _tutorPager,
            itemCount: list.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => persona = list[i].id);
            },
            itemBuilder: (_, i) {
              final p = list[i];
              final sel = p.id == persona;
              return AnimatedScale(
                scale: sel ? 1 : 0.88,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                child: BounceTap(
                  onTap: () => _tutorPager.animateToPage(i, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic),
                  child: Semantics(
                    button: true,
                    selected: sel,
                    label: '${p.name}, ${p.tagline(ui)}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.belly, p.body.withValues(alpha: 0.85)]),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: sel ? p.accent : Colors.transparent, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: p.body.withValues(alpha: sel ? 0.45 : 0.15),
                            blurRadius: sel ? 22 : 8,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Mascot(personaId: p.id, mood: sel ? 'wave' : 'idle', size: 140),
                          Text(
                            p.name,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Brand.ink),
                          ),
                          Text(
                            p.tagline(ui),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Brand.ink, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: SingleChildScrollView(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
                                  child: sel
                                      ? Typewriter(
                                          text: '${langFlags[target]} ${p.greeting(target)}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, color: Brand.ink),
                                        )
                                      : Text(
                                          '${langFlags[target]} ${p.greeting(target)}',
                                          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black38),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final p in list)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4),
                width: p.id == persona ? 24 : 9,
                height: 9,
                decoration: BoxDecoration(color: p.id == persona ? p.accent : Theme.of(context).colorScheme.outlineVariant, borderRadius: BorderRadius.circular(6)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _goalPage() {
    final g = _goals.firstWhere((x) => x.$1 == goal, orElse: () => _goals[1]);
    return Column(
      children: [
        _title(
          t('Pick a daily goal', 'Günlük hedefini seç', 'Wähle dein Tagesziel'),
          t('Small and daily beats long and rare.', 'Az ama her gün, çok ama nadirden iyidir.', 'Klein und täglich schlägt lang und selten.'),
        ),
        AnimatedScale(scale: 0.7 + _goals.indexOf(g) * 0.22, duration: const Duration(milliseconds: 450), curve: Curves.elasticOut, child: const FlameIcon(size: 64)),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            key: ValueKey(goal),
            t('${g.$2} min a day ≈ ${goal * 3} new words a month', 'Günde ${g.$2} dk ≈ ayda ${goal * 3} yeni kelime', '${g.$2} Min. am Tag ≈ ${goal * 3} neue Wörter im Monat'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
        const SizedBox(height: 16),
        for (final (i, o) in _goals.indexed)
          SlideFadeIn(
            index: i,
            child: _Tile(
              selected: goal == o.$1,
              leading: Text(o.$3, style: const TextStyle(fontSize: 28)),
              title: tr3(ui, o.$4, o.$5, o.$6),
              sub: t('${o.$2} min / day', 'Günde ${o.$2} dk', '${o.$2} Min. / Tag'),
              badge: '${o.$1} XP',
              onTap: () => setState(() => goal = o.$1),
            ),
          ),
      ],
    );
  }

  Widget _namePage() {
    final name = _name.text.trim();
    final nice = switch (target) {
      'en' => 'Nice to meet you, $name!',
      'tr' => 'Memnun oldum, $name!',
      _ => 'Freut mich, $name!',
    };
    return Column(
      children: [
        const SizedBox(height: 16),
        PopIn(
          child: Mascot(personaId: persona, mood: name.isEmpty ? 'wave' : 'love', size: 150),
        ),
        const SizedBox(height: 4),
        _title(
          name.isEmpty ? t('What should I call you?', 'Sana nasıl hitap edeyim?', 'Wie soll ich dich nennen?') : '${langFlags[target]} $nice',
          name.isEmpty ? t('Optional — your tutor uses it in chats.', 'İsteğe bağlı — öğretmenin sohbetlerde kullanır.', 'Optional – dein Tutor benutzt ihn im Chat.') : null,
        ),
        TextField(
          controller: _name,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _next(),
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          decoration: InputDecoration(
            hintText: t('Your name', 'Adın', 'Dein Name'),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: tutor.accent, width: 2.5)),
          ),
        ),
      ],
    );
  }

  Widget _readyPage() {
    final name = _name.text.trim();
    final g = _goals.firstWhere((x) => x.$1 == goal, orElse: () => _goals[1]);
    final items = [
      (
        '${langFlags[target]}',
        t('Learning ${langNames[target]![ui]} from ${level ?? 'A1'}', '${level ?? 'A1'} seviyesinden ${langNames[target]![ui]}', '${langNames[target]![ui]} ab ${level ?? 'A1'}'),
      ),
      ('🔥', t('${g.$2} minutes a day', 'Günde ${g.$2} dakika', '${g.$2} Minuten am Tag')),
      ('🐾', t('${tutor.name} is your tutor', 'Öğretmenin ${tutor.name}', '${tutor.name} ist dein Tutor')),
      if (interests.isNotEmpty || why.isNotEmpty)
        (
          '🧠',
          t('${tutor.name} will remember: ', '${tutor.name} hatırlayacak: ', '${tutor.name} merkt sich: ') +
              [
                for (final m in _motivations)
                  if (why.contains(m.id)) m.emoji,
                for (final i in _interestPicks)
                  if (interests.contains(i.id)) i.emoji,
              ].join(' '),
        ),
      ('🖼️', t('29 units, 740+ picture cards, AI chats', '29 ünite, 740+ resimli kart, yapay zekâ sohbetleri', '29 Einheiten, 740+ Bildkarten, KI-Chats')),
    ];
    return Confetti(
      child: Column(
        children: [
          const SizedBox(height: 10),
          PopIn(
            child: Mascot(personaId: persona, mood: 'love', size: 150),
          ),
          _title(
            name.isEmpty ? t("You're all set!", 'Her şey hazır!', 'Alles bereit!') : t("You're all set, $name!", 'Her şey hazır, $name!', 'Alles bereit, $name!'),
            t('Here is your plan:', 'İşte planın:', 'Dein Plan:'),
          ),
          for (final (i, it) in items.indexed)
            SlideFadeIn(
              index: i * 2 + 2,
              offset: 30,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Text(it.$1, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(it.$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Big tappable option card with a springy press, a glow when selected and a popping check.
class _Tile extends StatelessWidget {
  const _Tile({required this.selected, required this.title, required this.onTap, this.sub, this.leading, this.badge, this.accent, this.big = false, this.wrong = false});
  final bool selected, big, wrong;
  final String title;
  final String? sub, badge;
  final Widget? leading;
  final Color? accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = wrong ? Brand.red : (selected ? Brand.green : (accent ?? cs.primary));
    final on = selected || wrong;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: [title, ?sub, ?badge].join('. '),
        child: ExcludeSemantics(
          child: BounceTap(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: big ? 18 : 14),
              decoration: BoxDecoration(
                color: on ? Color.alphaBlend(c.withValues(alpha: 0.14), cs.surface) : cs.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: on ? c : (accent?.withValues(alpha: 0.6) ?? cs.outlineVariant), width: on ? 2.5 : 2),
                boxShadow: [BoxShadow(color: on ? c.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.06), blurRadius: on ? 16 : 6, offset: Offset(0, on ? 6 : 3))],
              ),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 14)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(fontSize: big ? 22 : 17, fontWeight: FontWeight.w900),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  badge!,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: c),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (sub != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              sub!,
                              style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: on ? 1 : 0,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.elasticOut,
                    child: Icon(wrong ? Icons.cancel_rounded : Icons.check_circle_rounded, color: c, size: 28),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Multi-select tile for motivations and interests.
class _Chip extends StatelessWidget {
  const _Chip({required this.emoji, required this.label, required this.selected, required this.onTap});
  final String emoji, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: BounceTap(
          onTap: onTap,
          scale: 0.9,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? Color.alphaBlend(Brand.gold.withValues(alpha: 0.18), cs.surface) : cs.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? Brand.gold : cs.outlineVariant, width: selected ? 2.5 : 2),
              boxShadow: [BoxShadow(color: selected ? Brand.gold.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05), blurRadius: selected ? 14 : 5, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                AnimatedScale(
                  scale: selected ? 1.25 : 1,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(label, maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
