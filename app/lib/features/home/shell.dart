import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../../state/providers.dart';
import '../course/course_screen.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';
import '../review/cards_screen.dart';
import '../tutor/tutor_screen.dart';

final tabProvider = NotifierProvider<TabNotifier, int>(TabNotifier.new);

class TabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void go(int i) => state = i;
}

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});
  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  @override
  void initState() {
    super.initState();
    // refresh the server-side memory once per app start (no-op when offline/disabled)
    Future.microtask(() => ref.read(memoryProvider.notifier).sync());
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: IndexedStack(index: tab, children: const [CourseScreen(), CardsScreen(), TutorScreen(), FeedScreen(), ProfileScreen()]),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: ref.read(tabProvider.notifier).go,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: ref.t('Learn', 'Öğren', 'Lernen')),
          NavigationDestination(icon: const Icon(Icons.style_outlined), selectedIcon: const Icon(Icons.style), label: ref.t('Cards', 'Kartlar', 'Karten')),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: 'Tutor'),
          NavigationDestination(icon: const Icon(Icons.newspaper_outlined), selectedIcon: const Icon(Icons.newspaper), label: ref.t('Culture', 'Kültür', 'Kultur')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: ref.t('Me', 'Ben', 'Ich')),
        ],
      ),
    );
  }
}
