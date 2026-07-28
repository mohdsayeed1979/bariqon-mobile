import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/catalog/presentation/category_list_screen.dart';
import '../features/catalog/presentation/home_screen.dart';
import '../features/catalog/presentation/search_results_screen.dart';
import '../features/inquiry/presentation/inquiry_cart_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'app_shell.dart';
import 'splash_screen.dart';

/// go_router setup, per docs/ARCHITECTURE.md §5 and
/// docs/IMPLEMENTATION_ROADMAP.md §4.
///
/// Phase 2A wires the permanent app shell: splash → the four bottom-nav
/// tab roots (each a placeholder today, per the Phase 2A brief) → a pushed
/// search screen outside the shell. Guarded/auth routes, deep links, and
/// the rest of the roadmap's route table land as the screens they point to
/// are actually built.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoryListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inquiry',
                builder: (context, state) => const InquiryCartScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchResultsScreen(),
      ),
    ],
  );
});
