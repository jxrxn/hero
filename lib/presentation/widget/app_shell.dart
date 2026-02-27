import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/screen_sizes/is_handheld.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goTo(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  static const _destinations = <_NavItem>[
    _NavItem(
      label: 'Home',
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield,
    ),
    _NavItem(
      label: 'Heroes',
      icon: Icons.star_border,
      selectedIcon: Icons.star,
    ),
    _NavItem(
      label: 'Search',
      icon: Icons.search,
      selectedIcon: Icons.search,
    ),
    _NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // --- Guard rails: fångar direkt om branches != destinations ---
    final branchCount = navigationShell.route.branches.length;
    assert(
      _destinations.length == branchCount,
      'AppShell: destinations (${_destinations.length}) '
      'måste matcha branches ($branchCount) i app_router.dart',
    );

    if (kDebugMode) {
      debugPrint(
        '🧭 AppShell build: branches=$branchCount currentIndex=${navigationShell.currentIndex}',
      );
    }

    final handheld = isHandheld(context);

    // ---- MOBIL: bottom nav ----
    if (handheld) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goTo,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    // ---- DESKTOP: rail + content ----
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _goTo,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}