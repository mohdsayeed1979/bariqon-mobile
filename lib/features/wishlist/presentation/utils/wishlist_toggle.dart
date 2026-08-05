import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../catalog/domain/entities/product.dart';
import '../controllers/wishlist_controller.dart';

/// Shared handler for every wishlist heart icon in the app — a guest gets
/// asked to sign in (per the brief: "If user not logged in, ask user to
/// Login") rather than the toggle silently failing; a signed-in user gets
/// an optimistic toggle with a SnackBar on failure. One place, so
/// ProductCard call sites (Home rails, Product Listing, Category Detail,
/// Wishlist itself) never re-implement this branching.
Future<void> toggleWishlist(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final l10n = AppLocalizations.of(context);
  final session = ref.read(authControllerProvider);

  if (session is! SignedInSession) {
    final shouldSignIn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wishlistSignInRequiredTitle),
        content: Text(l10n.wishlistSignInRequiredMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.authSignInCta),
          ),
        ],
      ),
    );
    if (shouldSignIn == true && context.mounted) context.push('/auth/login');
    return;
  }

  final wasWishlisted =
      (ref.read(wishlistControllerProvider).value ?? const {}).contains(product.id);
  try {
    await ref.read(wishlistControllerProvider.notifier).toggle(product.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasWishlisted ? l10n.wishlistRemovedSnackbar : l10n.wishlistAddedSnackbar,
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
  }
}
