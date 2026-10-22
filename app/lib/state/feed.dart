import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content.dart';
import '../data/local_memes.dart';
import 'providers.dart';

final newsProvider = FutureProvider.autoDispose<List<NewsItem>>((ref) => ref.watch(apiProvider).news());

/// Daily memes from the AI server; falls back to the bundled set when it is unavailable.
final memesProvider = FutureProvider.autoDispose<({List<Meme> memes, bool offline})>((ref) async {
  final p = ref.watch(profileProvider);
  try {
    final list = await ref.watch(apiProvider).memes(level: p.level, nativeLang: p.nativeLang);
    if (list.isNotEmpty) return (memes: list, offline: false);
  } on Object {
    // fall through to the bundled memes
  }
  return (memes: localMemes, offline: true);
});

typedef ArticleKey = ({NewsItem item, String level, String lang});

final articleProvider = FutureProvider.autoDispose.family<SimplifiedArticle, ArticleKey>(
  (ref, k) => ref.watch(apiProvider).simplify(k.item, level: k.level, nativeLang: k.lang),
);
