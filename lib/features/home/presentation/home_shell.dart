import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../items/data/item_repository.dart';
import '../../items/presentation/report_item_screen.dart';
import '../../items/presentation/browse_screen.dart';
import '../../profile/presentation/my_listings_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'home_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  Future<void> _report() async {
    final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const ReportItemScreen()));
    if (created == true) ref.invalidate(listingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      HomeScreen(),
      BrowseScreen(),
      MyListingsScreen(),
      ProfileScreen()
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _report,
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report item',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search_rounded), label: 'Browse'),
          NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'My posts'),
          NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile'),
        ],
      ),
    );
  }
}
