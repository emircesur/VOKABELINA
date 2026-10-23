import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vokabelina/app.dart';
import 'package:vokabelina/data/curriculum.dart';
import 'package:vokabelina/data/vocab_bank.dart';
import 'package:vokabelina/features/lesson/lesson_screen.dart';
import 'package:vokabelina/state/providers.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(900, 1900);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final container = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const VokabelinaApp()));
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

Future<void> _tap(WidgetTester tester, Finder f, {int ms = 500}) async {
  await tester.ensureVisible(f.first);
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(f.first, warnIfMissed: false);
  await tester.pump(Duration(milliseconds: ms));
}

void main() {
  testWidgets('Turkish learner: onboarding → course map → first lesson runs end to end', (tester) async {
    final c = await _pump(tester);
    // nothing is preselected and every language is offered in its own words
    expect(find.text('Türkçe'), findsOneWidget);
    expect(find.text('Use the app in English'), findsOneWidget);
    expect(find.text('Die App auf Deutsch nutzen'), findsOneWidget);
    expect(find.text('Uygulamayı Türkçe kullan'), findsOneWidget);

    // language choices advance by themselves
    await _tap(tester, find.text('Türkçe'), ms: 900);
    await _tap(tester, find.text('Deutsch'), ms: 900);
    await _tap(tester, find.text('Seyahat'), ms: 200);
    await _tap(tester, find.text('DEVAM'), ms: 600); // why
    await _tap(tester, find.text('Yeni başlıyorum'), ms: 200);
    await _tap(tester, find.text('DEVAM'), ms: 600); // level
    await _tap(tester, find.text('Futbol'), ms: 200);
    await _tap(tester, find.text('DEVAM'), ms: 600); // interests
    await _tap(tester, find.text('DEVAM'), ms: 600); // tutor
    await _tap(tester, find.text('DEVAM'), ms: 600); // goal
    await _tap(tester, find.text('GEÇ'), ms: 600); // name
    expect(find.text('Her şey hazır!'), findsOneWidget);
    await _tap(tester, find.text('Önce etrafa bakayım'), ms: 900);
    expect(c.read(profileProvider).targetLang, 'de');
    expect(c.read(profileProvider).nativeLang, 'tr');
    expect(c.read(memoryProvider).interests, ['Futbol']);
    expect(c.read(memoryProvider).goals, ['Seyahat']);

    // course map with the continue card
    expect(find.text('Öğren'), findsOneWidget);
    expect(find.textContaining('Kelimeler 1'), findsWidgets);
    await _tap(tester, find.text('BAŞLA'), ms: 900);

    // play the whole lesson: continue intros, answer everything with the first option / typed answer
    var guard = 0;
    while (find.textContaining('Ders tamamlandı').evaluate().isEmpty && find.textContaining('Kusursuz ders').evaluate().isEmpty && guard++ < 120) {
      if (find.text('DEVAM').evaluate().isNotEmpty) {
        await _tap(tester, find.text('DEVAM'), ms: 450);
        continue;
      }
      if (find.text('Eşleştir').evaluate().isNotEmpty) {
        // solve the pairs properly: German word → its Turkish gloss
        for (final w in bankWords.values) {
          final left = find.text(w.de);
          final right = find.text(w.tr);
          if (left.evaluate().isNotEmpty && right.evaluate().isNotEmpty && find.text('DEVAM').evaluate().isEmpty) {
            await _tap(tester, left, ms: 60);
            await _tap(tester, right, ms: 350);
          }
        }
        await tester.pump(const Duration(milliseconds: 300));
        continue;
      }
      final field = find.descendant(of: find.byType(LessonScreen), matching: find.byType(TextField));
      if (field.evaluate().isNotEmpty) {
        await tester.enterText(field.first, 'x');
        await tester.pump(const Duration(milliseconds: 50));
        // a fading-out typing exercise can still be in the tree during the transition
        if (find.text('KONTROL ET').evaluate().isNotEmpty) await _tap(tester, find.text('KONTROL ET'));
        await tester.pump(const Duration(milliseconds: 300));
        continue;
      }
      // choices: picture/meaning/listen options are InkWells inside the scroll view; match pairs need two taps
      final inks = find.descendant(of: find.descendant(of: find.byType(LessonScreen), matching: find.byType(SingleChildScrollView)), matching: find.byType(InkWell));
      if (inks.evaluate().length >= 2) {
        await _tap(tester, inks.at(0), ms: 150);
        final again = find.descendant(of: find.descendant(of: find.byType(LessonScreen), matching: find.byType(SingleChildScrollView)), matching: find.byType(InkWell));
        if (find.text('DEVAM').evaluate().isEmpty && again.evaluate().length >= 2) await _tap(tester, again.at(again.evaluate().length ~/ 2), ms: 400);
        continue;
      }
      await tester.pump(const Duration(milliseconds: 300));
    }
    if (guard >= 120) {
      // ignore: avoid_print
      print([for (final e in find.byType(Text).evaluate()) (e.widget as Text).data ?? (e.widget as Text).textSpan?.toPlainText()].join(' | '));
    }
    expect(guard, lessThan(120), reason: 'lesson did not finish');
    expect(tester.takeException(), isNull);
    // progress, XP and SRS were updated
    expect(c.read(progressProvider).keys, contains('de:u01_w1'));
    expect(c.read(profileProvider).xp, greaterThan(0));
    expect(c.read(deckProvider).forLang('de'), isNotEmpty);
  });

  testWidgets('German speaker learning Turkish gets German UI; every tab opens', (tester) async {
    await _pump(tester);
    await _tap(tester, find.text('Deutsch'), ms: 900);
    await _tap(tester, find.text('Türkçe'), ms: 900);
    expect(find.text('Warum lernst du Türkisch?'), findsOneWidget);
    await _tap(tester, find.text('ÜBERSPRINGEN'), ms: 600);
    await _tap(tester, find.text('Ich fange neu an'), ms: 200);
    await _tap(tester, find.text('WEITER'), ms: 600);
    await _tap(tester, find.text('ÜBERSPRINGEN'), ms: 600);
    await _tap(tester, find.text('WEITER'), ms: 600);
    await _tap(tester, find.text('WEITER'), ms: 600);
    await _tap(tester, find.text('ÜBERSPRINGEN'), ms: 600);
    await _tap(tester, find.text('Erst mal umschauen'), ms: 900);
    expect(find.text('Lernen'), findsOneWidget);
    expect(find.textContaining('Türkisch'), findsWidgets);

    for (final tab in ['Karten', 'Tutor', 'Kultur', 'Ich', 'Lernen']) {
      await _tap(tester, find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)), ms: 600);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('placement test puts a strong learner at B1 and starts the first B1 lesson', (tester) async {
    final c = await _pump(tester);
    await _tap(tester, find.text('English'), ms: 900);
    await _tap(tester, find.text('Deutsch'), ms: 900);
    await _tap(tester, find.text('SKIP'), ms: 600);
    await _tap(tester, find.text('Not sure? Take the 1-minute test'), ms: 600);
    for (var q = 0; q < 9; q++) {
      final prompt = tester.widget<Text>(find.byWidgetPredicate((w) => w is Text && w.style?.fontSize == 32)).data!;
      final answer = bankWords.values.firstWhere((w) => w.de == prompt).en;
      await _tap(tester, find.text(answer), ms: 800);
    }
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('B1'), findsWidgets);
    expect(find.textContaining('9 / 9'), findsOneWidget);
    await _tap(tester, find.text('CONTINUE'), ms: 600); // level
    await _tap(tester, find.text('SKIP'), ms: 600); // interests
    await _tap(tester, find.text('CONTINUE'), ms: 600); // tutor
    await _tap(tester, find.text('CONTINUE'), ms: 600); // goal
    await tester.enterText(find.byType(TextField), 'Alex');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Freut mich, Alex!'), findsOneWidget);
    await _tap(tester, find.text('CONTINUE'), ms: 600); // name
    await _tap(tester, find.text('START MY FIRST LESSON'), ms: 300);
    // the course map shows for a beat, then the first lesson slides in
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 600));
    final p = c.read(profileProvider);
    expect((p.level, p.nativeLang, p.name), ('B1', 'en', 'Alex'));
    final lesson = tester.widget<LessonScreen>(find.byType(LessonScreen));
    expect(unitsById[lesson.lessonId!.split('_').first]!.level, 'B1');
  });
}
