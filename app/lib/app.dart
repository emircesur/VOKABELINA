import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'data/content.dart';
import 'features/feed/article_screen.dart';
import 'features/home/learn_screen.dart';
import 'features/home/shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/review/review_screen.dart';
import 'state/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(profileProvider.select((p) => p.onboarded), (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    refreshListenable: refresh,
    redirect: (context, state) {
      final done = ref.read(profileProvider).onboarded;
      final atOnboarding = state.matchedLocation == '/onboarding';
      if (!done && !atOnboarding) return '/onboarding';
      if (done && atOnboarding) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Shell()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/review', builder: (_, _) => const ReviewScreen()),
      GoRoute(path: '/learn', builder: (_, _) => const LearnScreen()),
      GoRoute(path: '/article', builder: (_, s) => ArticleScreen(item: s.extra as NewsItem)),
    ],
  );
});

class VokabelinaApp extends ConsumerWidget {
  const VokabelinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vokabelina',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
