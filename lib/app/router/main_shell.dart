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
    final destinations = <_AppDestination>[
      _AppDestination(l10n.navMap, Icons.map_outlined, Icons.map_rounded),
      _AppDestination(
        l10n.navReports,
        Icons.add_location_alt_outlined,
        Icons.add_location_alt_rounded,
      ),
      _AppDestination(
        l10n.navNews,
        Icons.newspaper_outlined,
        Icons.newspaper_rounded,
      ),
      _AppDestination(
        l10n.navDocuments,
        Icons.folder_copy_outlined,
        Icons.folder_copy_rounded,
      ),
      _AppDestination(
        l10n.navProfile,
        Icons.person_outline_rounded,
        Icons.person_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = Theme.of(context).colorScheme;
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
                    labelType: NavigationRailLabelType.all,
                    groupAlignment: -0.35,
                    leading: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 24),
                      child: Semantics(
                        label: l10n.appTitle,
                        image: true,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.location_city_rounded,
                            size: 27,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    destinations: [
                      for (final item in destinations)
                        NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, color: colors.outlineVariant),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.08),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: NavigationBar(
              key: const ValueKey('main-navigation-bar'),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _select,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (var index = 0; index < destinations.length; index++)
                  NavigationDestination(
                    icon: Semantics(
                      selected: navigationShell.currentIndex == index,
                      child: Icon(destinations[index].icon),
                    ),
                    selectedIcon: Icon(destinations[index].selectedIcon),
                    label: destinations[index].label,
                    tooltip: destinations[index].label,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppDestination {
  const _AppDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
