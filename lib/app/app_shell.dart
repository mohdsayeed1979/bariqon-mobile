import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/catalog/presentation/controllers/catalog_providers.dart';
import '../features/inquiry/presentation/controllers/inquiry_cart_controller.dart';
import '../features/wishlist/presentation/controllers/wishlist_controller.dart';
import '../l10n/generated/app_localizations.dart';

/// The permanent app shell — bottom navigation on phones, a
/// [NavigationRail] on wider layouts (tablets/desktop web), per the
/// Phase 2A brief's "responsive layout" requirement. Wraps go_router's
/// [StatefulShellRoute], so each tab keeps its own navigation stack
/// (switching tabs and back doesn't lose where you were in another tab).
///
/// Watches [inquiryCartItemCountProvider] (Phase 3) to badge the Inquiry
/// tab — the one piece of cross-cutting cart state the shell itself needs
/// to know about. Also watches [catalogRealtimeSyncProvider] purely to
/// keep it alive for the app's lifetime — this is the one widget that's
/// always mounted once past the splash screen, so it's the natural place
/// to start the catalog's realtime subscription.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const double _wideBreakpoint = 600;

  List<_Destination> _destinations(AppLocalizations l10n, int cartCount) => [
    _Destination(l10n.navHome, Icons.home_outlined, Icons.home),
    _Destination(l10n.navCategories, Icons.category_outlined, Icons.category),
    _Destination(l10n.navWishlist, Icons.favorite_border, Icons.favorite),
    _Destination(
      l10n.navInquiry,
      Icons.shopping_bag_outlined,
      Icons.shopping_bag,
      badgeCount: cartCount,
    ),
    _Destination(l10n.navProfile, Icons.person_outline, Icons.person),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cartCount = ref.watch(inquiryCartItemCountProvider);
    final destinations = _destinations(l10n, cartCount);
    ref.watch(catalogRealtimeSyncProvider);
    ref.watch(wishlistRealtimeSyncProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _wideBreakpoint;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onSelect,
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: d.badge(Icon(d.icon)),
                        selectedIcon: d.badge(Icon(d.selectedIcon)),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onSelect,
            destinations: [
              for (final d in destinations)
                NavigationDestination(
                  icon: d.badge(Icon(d.icon)),
                  selectedIcon: d.badge(Icon(d.selectedIcon)),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Destination {
  const _Destination(
    this.label,
    this.icon,
    this.selectedIcon, {
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badgeCount;

  Widget badge(Widget child) => Badge(
    isLabelVisible: badgeCount > 0,
    label: Text('$badgeCount'),
    child: child,
  );
}
