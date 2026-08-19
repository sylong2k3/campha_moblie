import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _select(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      (l10n.navMap, Icons.map_outlined, Icons.map),
      (l10n.navReports, Icons.campaign_outlined, Icons.campaign),
      (l10n.navNews, Icons.newspaper_outlined, Icons.newspaper),
      (l10n.navDocuments, Icons.folder_copy_outlined, Icons.folder_copy),
      (l10n.navProfile, Icons.person_outline, Icons.person),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    key: const ValueKey('main-navigation-rail'),
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.none,
                    groupAlignment: -0.35,
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 28),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          Icons.location_city,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    destinations: [
                      for (final item in destinations)
                        NavigationRailDestination(
                          icon: Icon(item.$2),
                          selectedIcon: Icon(item.$3),
                          label: Text(item.$1),
                        ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: NavigationBar(
              key: const ValueKey('main-navigation-bar'),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
              destinations: [
                for (final item in destinations)
                  NavigationDestination(
                    icon: Icon(item.$2),
                    selectedIcon: Icon(item.$3),
                    label: item.$1,
                    tooltip: item.$1,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
