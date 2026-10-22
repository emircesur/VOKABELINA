import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n.dart';
import '../feed/feed_screen.dart';
import '../profile/profile_screen.dart';
import '../tutor/tutor_screen.dart';
import 'home_screen.dart';
import '../review/cards_screen.dart';

final tabProvider = NotifierProvider<TabNotifier, int>(TabNotifier.new);

class TabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void go(int i) => state = i;
}

class Shell extends ConsumerWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: IndexedStack(index: tab, children: const [HomeScreen(), CardsScreen(), TutorScreen(), FeedScreen(), ProfileScreen()]),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: ref.read(tabProvider.notifier).go,
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: ref.t('Learn', 'Lernen')),
          NavigationDestination(icon: const Icon(Icons.style_outlined), selectedIcon: const Icon(Icons.style), label: ref.t('Cards', 'Karten')),
          NavigationDestination(icon: const Icon(Icons.chat_bubble_outline), selectedIcon: const Icon(Icons.chat_bubble), label: ref.t('Tutor', 'Tutor')),
          NavigationDestination(icon: const Icon(Icons.newspaper_outlined), selectedIcon: const Icon(Icons.newspaper), label: ref.t('Culture', 'Kultur')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: ref.t('Me', 'Ben')),
        ],
      ),
    );
  }
}
