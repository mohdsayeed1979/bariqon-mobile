import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../inquiry/presentation/controllers/inquiry_cart_controller.dart';
import '../../../wishlist/presentation/controllers/wishlist_controller.dart';
import '../../../wishlist/presentation/utils/wishlist_toggle.dart';
import '../../domain/entities/product.dart';

/// Generic horizontally-scrolling product rail — reused for Featured
/// Products, New Arrivals, and Best Sellers on Home, and for Related
/// Products on Product Detail (same shape, per the Phase 2B/2D briefs,
/// just different mock data/title each time).
///
/// Deliberately no fixed-height container around the row: [ProductCard]
/// sizes itself to its own content, and [IntrinsicHeight] sizes this
/// scroller to whatever that turns out to be. A guessed pixel height here
/// was the exact cause of the RenderFlex overflow flagged in the first
/// Phase 2B pass — this shape can't drift out of sync with the card again.
class ProductSection extends ConsumerWidget {
  const ProductSection({
    super.key,
    required this.title,
    required this.products,
  });

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final wishlistedIds = ref.watch(wishlistControllerProvider).value ?? const {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionLabel: l10n.homeViewAll,
          onAction: () => context.push('/products'),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < products.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Builder(
                    builder: (context) {
                      final product = products[i];
                      // See ProductResultsView for why each card gets its
                      // own RepaintBoundary.
                      return RepaintBoundary(
                        key: ValueKey(product.id),
                        child: ProductCard(
                          title: product.name(locale),
                          description: product.description(locale),
                          price: product.effectivePrice,
                          originalPrice: product.hasActiveDiscount ? product.price : null,
                          discountBadgePercent: product.discountBadgePercent,
                          stockStatus: product.stockStatus,
                          icon: product.icon,
                          placeholderColor: product.placeholderColor,
                          imageUrl: product.imageUrl,
                          sendInquiryLabel: l10n.homeSendInquiry,
                          isWishlisted: wishlistedIds.contains(product.id),
                          onToggleWishlist: () => toggleWishlist(context, ref, product),
                          onTap: () => context.push('/product/${product.id}'),
                          onSendInquiry: () {
                            ref
                                .read(inquiryCartProvider.notifier)
                                .addProduct(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.homeSendInquirySnackbar),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
