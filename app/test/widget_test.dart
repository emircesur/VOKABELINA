import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vokabelina/app.dart';
import 'package:vokabelina/state/providers.dart';

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  tester.view.physicalSize = const Size(900, 1800);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(overrides: [sharedPrefsProvider.overrideWithValue(prefs)], child: const VokabelinaApp()));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('onboarding → home → review a card', (tester) async {
    await _pump(tester);
    expect(find.text('Vokabelina'), findsOneWidget);

    // welcome → language (Turkish default) → level → persona → goal
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('DEVAM'));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.tap(find.text('BAŞLAYALIM!'));
    await tester.pump(const Duration(milliseconds: 600));

    // home shows the review CTA with the 8 starter cards
    expect(find.text('8 KARTI TEKRAR ET'), findsOneWidget);
    expect(find.text('Lernen'), findsOneWidget);

    await tester.tap(find.text('8 KARTI TEKRAR ET'));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('1 / 8'), findsOneWidget);
    await tester.tap(find.text('CEVABI GÖSTER'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('İYİ'), findsOneWidget); // Turkish-aware upper-casing
    await tester.tap(find.text('İYİ'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('2 / 8'), findsOneWidget);
  });

  testWidgets('English users get English UI and can open every tab without errors', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('DEVAM'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('🇬🇧  English'));
    await tester.pump(const Duration(milliseconds: 200));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('CONTINUE'));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.tap(find.text("LET'S GO!"));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('REVIEW 8 CARDS'), findsOneWidget);

    for (final tab in ['Cards', 'Tutor', 'Culture', 'Me', 'Learn']) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)));
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(tester.takeException(), isNull);
  });
}
