import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/catalog/presentation/category_detail_screen.dart';
import '../features/catalog/presentation/category_list_screen.dart';
import '../features/catalog/presentation/home_screen.dart';
import '../features/catalog/presentation/product_detail_screen.dart';
import '../features/catalog/presentation/product_listing_screen.dart';
import '../features/catalog/presentation/search_results_screen.dart';
import '../features/inquiry/domain/entities/inquiry.dart';
import '../features/inquiry/presentation/inquiry_cart_screen.dart';
import '../features/inquiry/presentation/inquiry_confirmation_screen.dart';
import '../features/inquiry/presentation/inquiry_details_form_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'app_shell.dart';
import 'splash_screen.dart';

/// go_router setup, per docs/ARCHITECTURE.md §5 and
/// docs/IMPLEMENTATION_ROADMAP.md §4.
///
/// Permanent app shell: splash → the four bottom-nav tab roots → pushed
/// routes outside the shell for screens that don't belong in the bottom
/// nav (search, category detail). Guarded/auth routes, deep links, and the
/// rest of the roadmap's route table land as the screens they point to are
/// actually built.
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
      GoRoute(
        path: '/category/:id',
        builder: (context, state) => CategoryDetailScreen(
          categoryId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListingScreen(),
      ),
      GoRoute(
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/inquiry/details',
        builder: (context, state) => const InquiryDetailsFormScreen(),
      ),
      GoRoute(
        path: '/inquiry/confirmation',
        builder: (context, state) => InquiryConfirmationScreen(
          inquiry: state.extra as Inquiry?,
        ),
      ),
    ],
  );
});
