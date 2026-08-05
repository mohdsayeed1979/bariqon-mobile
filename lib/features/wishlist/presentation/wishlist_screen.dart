import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/product_results_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/sign_in_prompt_view.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/entities/auth_session.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../catalog/presentation/controllers/catalog_providers.dart';
import 'controllers/wishlist_controller.dart';

/// Wishlist tab root — a signed-in customer's saved products, cross-
/// referenced from [wishlistControllerProvider]'s ids against the
/// already-fetched [productsProvider] list (same "derive client-side"
/// pattern every other screen uses — no second product-fetching path).
/// A Guest/Signed Out session sees a sign-in prompt instead, per the
/// brief ("If user not logged in, Ask user to Login").
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final session = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.wishlistTitle, showSearchAction: false),
      body: SafeArea(
        child: session is! SignedInSession
            ? SignInPromptView(
                message: l10n.wishlistSignInRequiredMessage,
                icon: Icons.favorite_border,
              )
            : Builder(
                builder: (context) {
                  final wishlistAsync = ref.watch(wishlistControllerProvider);
                  final productsAsync = ref.watch(productsProvider);
                  ref.watch(wishlistRealtimeSyncProvider);

                  return AsyncValueView(
                    value: wishlistAsync,
                    onRetry: () => ref.invalidate(wishlistControllerProvider),
                    data: (wishlistedIds) => AsyncValueView(
                      value: productsAsync,
                      onRetry: () => ref.invalidate(productsProvider),
                      data: (products) => ResponsiveCenter(
                        width: ContentWidth.grid,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ProductResultsView(
                            loading: false,
                            products: products
                                .where((p) => wishlistedIds.contains(p.id))
                                .toList(),
                            locale: locale,
                            sendInquiryLabel: l10n.homeSendInquiry,
                            sendInquirySnackbarText: l10n.homeSendInquirySnackbar,
                            onProductTap: (product) =>
                                context.push('/product/${product.id}'),
                            emptyIcon: Icons.favorite_border,
                            emptyMessage: l10n.wishlistEmptyMessage,
                            emptyActionLabel: l10n.inquiryCartEmptyCta,
                            onEmptyAction: () => context.push('/products'),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
