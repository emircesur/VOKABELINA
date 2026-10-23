import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'data/content.dart';
import 'features/ai/practice_screen.dart';
import 'features/ai/roleplay_screen.dart';
import 'features/ai/story_screen.dart';
import 'features/ai/writing_screen.dart';
import 'features/course/unit_screen.dart';
import 'features/feed/article_screen.dart';
import 'features/home/shell.dart';
import 'features/lesson/lesson_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/review/review_screen.dart';
import 'state/providers.dart';
import 'widgets/anim.dart';

/// Slide-up + fade page transition.
Page<void> _page(GoRouterState s, Widget child) => CustomTransitionPage<void>(
      key: s.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, a, _, c) {
        if (reduceMotion(context)) return c;
        final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(opacity: curved, child: SlideTransition(position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved), child: c));
      },
    );

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
      GoRoute(path: '/review', pageBuilder: (_, s) => _page(s, const ReviewScreen())),
      GoRoute(path: '/practice', pageBuilder: (_, s) => _page(s, const PracticeScreen())),
      GoRoute(path: '/story', pageBuilder: (_, s) => _page(s, const StoryScreen())),
      GoRoute(path: '/unit/:id', pageBuilder: (_, s) => _page(s, UnitScreen(unitId: s.pathParameters['id']!))),
      GoRoute(path: '/lesson/:id', pageBuilder: (_, s) => _page(s, LessonScreen(lessonId: s.pathParameters['id']!))),
      GoRoute(path: '/roleplay/:unit', pageBuilder: (_, s) => _page(s, RoleplayScreen(unitId: s.pathParameters['unit']!))),
      GoRoute(path: '/write/:unit', pageBuilder: (_, s) => _page(s, WritingScreen(unitId: s.pathParameters['unit']!))),
      GoRoute(path: '/article', pageBuilder: (_, s) => _page(s, ArticleScreen(item: s.extra as NewsItem))),
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
