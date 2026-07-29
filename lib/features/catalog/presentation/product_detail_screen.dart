import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/auto_carousel.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/price_tag.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inquiry/presentation/controllers/inquiry_cart_controller.dart';
import 'controllers/catalog_providers.dart';
import 'utils/catalog_selectors.dart';
import 'widgets/product_section.dart';

/// Product Detail screen, per the Phase 2D brief — image gallery, title,
/// description, category, price, real product features, Send Inquiry, and
/// a Related Products rail, backed by [catalogProvider] since the
/// Supabase connection pass. Pushed outside the bottom-nav shell, reached
/// from any [ProductCard] tap (Home, Category Detail, Product Listing,
/// Related Products itself).
///
/// Reuses [AutoCarousel] (built for Home's hero banner) for the gallery
/// and [ProductSection] (built for Home's product rails) for Related
/// Products, rather than re-implementing either — per the Phase 2D
/// reusability requirement.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final catalogAsync = ref.watch(catalogProvider);

    return AsyncValueView(
      value: catalogAsync,
      onRetry: () {
        ref.invalidate(categoriesProvider);
        ref.invalidate(productsProvider);
      },
      data: (catalog) {
        final (categories, products) = catalog;
        final product = productById(products, productId);

        if (product == null) {
          return Scaffold(
            appBar: BrandedAppBar(
              title: l10n.productsTitle,
              showSearchAction: false,
            ),
            body: Center(
              child: ErrorStateView(
                title: l10n.productNotFoundTitle,
                message: l10n.productNotFoundMessage,
                actionLabel: MaterialLocalizations.of(
                  context,
                ).backButtonTooltip,
                onRetry: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
            ),
          );
        }

        final category = categoryById(categories, product.categoryId);
        final features = product.features(locale);
        final related = relatedProducts(products, product);
        final theme = Theme.of(context);
        final images = product.allImages;

        return Scaffold(
      appBar: BrandedAppBar(title: product.name(locale), showSearchAction: false),
      body: SafeArea(
        child: ResponsiveCenter(
        width: ContentWidth.wide,
        child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          images.isEmpty
              ? SizedBox(
                  height: 280,
                  child: ProductImage(
                    imageUrl: null,
                    icon: product.icon,
                    placeholderColor: product.placeholderColor,
                    iconSize: 96,
                  ),
                )
              : AutoCarousel(
                  itemCount: images.length,
                  height: 280,
                  viewportFraction: 1.0,
                  itemBuilder: (context, index) => ProductImage(
                    imageUrl: images[index],
                    icon: product.icon,
                    placeholderColor: product.placeholderColor,
                    iconSize: 96,
                  ),
                ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name(locale), style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    PriceTag(
                      price: product.price,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // Flexible, not a plain trailing chip: a long
                    // translated category name (Arabic runs longer than
                    // English here) needs to be able to shrink, otherwise
                    // the chip's own minimum width pushes this Row past
                    // its bounds — the exact shape of bug that caused the
                    // Phase 2B overflow. spaceBetween (not Spacer) keeps
                    // price/chip pinned to opposite edges while still
                    // letting the chip's Flexible constraint take effect.
                    if (category != null)
                      Flexible(
                        child: ActionChip(
                          avatar: Icon(category.icon, size: 16),
                          label: Text(
                            category.name(locale),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () =>
                              context.push('/category/${category.id}'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  product.description(locale),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      ref.read(inquiryCartProvider.notifier).addProduct(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.homeSendInquirySnackbar)),
                      );
                    },
                    child: Text(l10n.homeSendInquiry),
                  ),
                ),
                if (features.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l10n.productDetailFeaturesHeading,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final feature in features) _FeatureRow(text: feature),
                ],
              ],
            ),
          ),
          if (related.isNotEmpty)
            ProductSection(
              title: l10n.productDetailRelatedHeading,
              products: related,
            ),
        ],
        ),
        ),
      ),
    );
      },
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
