import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/layout/textara_layout.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/screens/library/library_screen.dart';
import 'package:textara/presentation/screens/settings/settings_screen.dart';
import 'package:textara/presentation/screens/threads/idea_threads_screen.dart';

/// Root destinations: Library, Threads, Settings.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(pendingReaderOpenProvider) != null && _index != 0) {
        setState(() => _index = 0);
      }
    });
  }

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: 'Library',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_tree_outlined),
      selectedIcon: Icon(Icons.account_tree_rounded),
      label: 'Threads',
    ),
    NavigationDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: 'Settings',
    ),
  ];

  bool _paneBlocksPop() {
    if (_index == 0 && ref.watch(libraryReaderPaneOpenProvider)) return true;
    if (_index == 1 && ref.watch(threadDetailPaneOpenProvider)) return true;
    return false;
  }

  void _closeActivePane() {
    if (_index == 0) {
      ref.read(libraryReaderPaneOpenProvider.notifier).state = false;
    } else if (_index == 1) {
      ref.read(threadDetailPaneOpenProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = isTextaraTablet(MediaQuery.sizeOf(context));

    ref.listen<PendingReaderOpen?>(pendingReaderOpenProvider, (previous, next) {
      if (next != null && _index != 0) {
        setState(() => _index = 0);
      }
    });

    final pages = const [
      LibraryScreen(embeddedInShell: true),
      IdeaThreadsScreen(embeddedInShell: true),
      SettingsScreen(embeddedInShell: true),
    ];

    final shell = isTablet
        ? Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book_rounded),
                      label: Text('Library'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.account_tree_outlined),
                      selectedIcon: Icon(Icons.account_tree_rounded),
                      label: Text('Threads'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(index: _index, children: pages),
                ),
              ],
            ),
          )
        : Scaffold(
            body: IndexedStack(index: _index, children: pages),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: _destinations,
            ),
          );

    return PopScope(
      canPop: !_paneBlocksPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeActivePane();
      },
      child: shell,
    );
  }
}
