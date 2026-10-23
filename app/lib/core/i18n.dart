import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// UI strings are written inline as (English, Turkish, [German]) triples.
/// German UI is used by German speakers learning English or Turkish; strings
/// without a German version fall back to English.
extension I18n on WidgetRef {
  String get uiLang => watch(profileProvider.select((p) => p.nativeLang));
  bool get isTr => uiLang == 'tr';
  String t(String en, String tr, [String? de]) => switch (uiLang) { 'tr' => tr, 'de' => de ?? en, _ => en };
}

String tr3(String lang, String en, String tr, [String? de]) => switch (lang) { 'tr' => tr, 'de' => de ?? en, _ => en };
