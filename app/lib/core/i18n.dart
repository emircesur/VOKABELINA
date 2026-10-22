import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';

/// UI strings are written inline as (English, Turkish) pairs; German is the
/// language being learned, so it is used for brand/section names only.
extension I18n on WidgetRef {
  bool get isTr => watch(profileProvider.select((p) => p.nativeLang)) == 'tr';
  String t(String en, String tr) => isTr ? tr : en;
}
