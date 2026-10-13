import 'package:flutter/material.dart';
import '../history/journal_screen.dart';
import '../home/home_screen.dart';
import '../insights/insights_screen.dart';
import '../toolkit/toolkit_screen.dart';

/// Signed-in app frame: four tabs behind a bottom NavigationBar. Tabs live
/// in an IndexedStack so scroll position and loaded data survive switching.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Lets a descendant (e.g. Today's "See all") switch tabs.
  static void goToTab(BuildContext context, int index) {
    context.findAncestorStateOfType<_MainShellState>()?._select(index);
  }

  static const today = 0;
  static const journal = 1;
  static const insights = 2;
  static const toolkit = 3;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          JournalScreen(),
          InsightsScreen(),
          ToolkitScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Journal',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_outline),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Toolkit',
            ),
          ],
        ),
      ),
    );
  }
}
