import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/product_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../inquiry/presentation/controllers/inquiry_cart_controller.dart';
import '../../domain/entities/product.dart';

/// The horizontally-scrolling row of [ProductCard]s itself, with no
/// [SectionHeader] — split out from [ProductSection] so
/// [AsyncProductRail] (Home's Supabase-backed rails) can reuse the exact
/// same row rendering while supplying its own loading/error states around
/// it, instead of duplicating this loop.
///
/// Deliberately no fixed-height container around the row: [ProductCard]
/// sizes itself to its own content, and [IntrinsicHeight] sizes this
/// scroller to whatever that turns out to be. A guessed pixel height here
/// was the exact cause of the RenderFlex overflow flagged in the first
/// Phase 2B pass — this shape can't drift out of sync with the card again.
class ProductCardRow extends ConsumerWidget {
  const ProductCardRow({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return SingleChildScrollView(
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
                  return ProductCard(
                    title: product.name(locale),
                    description: product.description(locale),
                    price: product.price,
                    icon: product.icon,
                    placeholderColor: product.placeholderColor,
                    imageUrl: product.imageUrl,
                    sendInquiryLabel: l10n.homeSendInquiry,
                    onTap: () => context.push('/product/${product.id}'),
                    onSendInquiry: () {
                      ref.read(inquiryCartProvider.notifier).addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.homeSendInquirySnackbar)),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Generic horizontally-scrolling product rail — used for Related Products
/// on Product Detail (a synchronous, already-fetched list; see
/// product_filter_utils.dart's `relatedProducts`). Home's three rails use
/// [AsyncProductRail] instead, since those are backed by their own
/// [FutureProvider]s.
class ProductSection extends StatelessWidget {
  const ProductSection({super.key, required this.title, required this.products});

  final String title;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          actionLabel: l10n.homeViewAll,
          onAction: () => context.push('/products'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ProductCardRow(products: products),
      ],
    );
  }
}
