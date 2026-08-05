import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/coming_soon_screen.dart';
import '../features/auth/domain/entities/app_user.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/registration_screen.dart';
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
import '../features/inquiry/presentation/inquiry_history_screen.dart';
import '../features/profile/domain/entities/saved_address.dart';
import '../features/profile/presentation/address_form_screen.dart';
import '../features/profile/presentation/addresses_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/wishlist/presentation/wishlist_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/settings/presentation/app_lock_settings_screen.dart';
import '../features/settings/presentation/contact_screen.dart';
import '../features/settings/presentation/legal_content_screen.dart';
import '../features/settings/presentation/notification_preferences_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../l10n/generated/app_localizations.dart';
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
                path: '/wishlist',
                builder: (context, state) => const WishlistScreen(),
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
      GoRoute(path: '/auth/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) =>
            EditProfileScreen(user: state.extra as AppUser?),
      ),
      GoRoute(
        path: '/profile/orders',
        builder: (context, state) => const InquiryHistoryScreen(),
      ),
      GoRoute(
        path: '/profile/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/profile/addresses/form',
        builder: (context, state) =>
            AddressFormScreen(existing: state.extra as SavedAddress?),
      ),
      GoRoute(
        path: '/profile/faq',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return ComingSoonScreen(
            title: l10n.profileFaqTitle,
            icon: Icons.help_outline,
          );
        },
      ),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
      GoRoute(
        path: '/settings/about',
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: '/settings/contact',
        builder: (context, state) => const ContactScreen(),
      ),
      GoRoute(
        path: '/settings/security',
        builder: (context, state) => const AppLockSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return LegalContentScreen(
            title: l10n.settingsPrivacyTitle,
            body: l10n.legalPrivacyPolicyBody,
          );
        },
      ),
      GoRoute(
        path: '/settings/terms',
        builder: (context, state) {
          final l10n = AppLocalizations.of(context);
          return LegalContentScreen(
            title: l10n.settingsTermsTitle,
            body: l10n.legalTermsBody,
          );
        },
      ),
    ],
  );
});
