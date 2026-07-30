import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/price_tag.dart';
import '../../../core/widgets/product_image_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../inquiry/presentation/controllers/inquiry_cart_controller.dart';
import '../domain/entities/category.dart';
import 'controllers/catalog_providers.dart';
import 'utils/product_filter_utils.dart';
import 'widgets/product_section.dart';

/// Product Detail screen, per the Phase 2D brief — image gallery, title,
/// description, category, price, mock specifications, Send Inquiry, and
/// a Related Products rail. Pushed outside the bottom-nav shell, reached
/// from any [ProductCard] tap (Home, Category Detail, Product Listing,
/// Related Products itself).
///
/// Product/category/related-products data come from [productByIdProvider]/
/// [categoriesProvider]/[productsProvider] as of Phase 5 (Supabase when
/// configured, mock otherwise — see catalog_providers.dart).
///
/// Reuses [AutoCarousel] (built for Home's hero banner) for the gallery
/// when a product has no real photo, and [ProductSection] (built for
/// Home's product rails) for Related Products, rather than
/// re-implementing either — per the Phase 2D reusability requirement.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final productAsync = ref.watch(productByIdProvider(productId));
    final categoriesAsync = ref.watch(categoriesProvider);
    final allProductsAsync = ref.watch(productsProvider);

    final loading = productAsync.isLoading ||
        categoriesAsync.isLoading ||
        allProductsAsync.isLoading;
    final error = productAsync.error ?? categoriesAsync.error ?? allProductsAsync.error;

    if (loading) {
      return Scaffold(
        appBar: BrandedAppBar(title: l10n.productsTitle, showSearchAction: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: BrandedAppBar(title: l10n.productsTitle, showSearchAction: false),
        body: Center(
          child: ErrorStateView(
            onRetry: () {
              ref.invalidate(productByIdProvider(productId));
              ref.invalidate(categoriesProvider);
              ref.invalidate(productsProvider);
            },
          ),
        ),
      );
    }

    final product = productAsync.value;

    if (product == null) {
      return Scaffold(
        appBar: BrandedAppBar(title: l10n.productsTitle, showSearchAction: false),
        body: Center(
          child: ErrorStateView(
            title: l10n.productNotFoundTitle,
            message: l10n.productNotFoundMessage,
            actionLabel: MaterialLocalizations.of(context).backButtonTooltip,
            onRetry: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
        ),
      );
    }

    Category? category;
    for (final c in categoriesAsync.value!) {
      if (c.id == product.categoryId) {
        category = c;
        break;
      }
    }
    final specs = mockSpecificationValues(product.categoryId, locale);
    final related = relatedProducts(allProductsAsync.value!, product);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: BrandedAppBar(title: product.name(locale), showSearchAction: false),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          SizedBox(
            height: 280,
            width: double.infinity,
            child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                ? const ProductImagePlaceholder()
                : CachedNetworkImage(
                    imageUrl: product.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const ProductImagePlaceholder(),
                    errorWidget: (context, url, error) =>
                        const ProductImagePlaceholder(),
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
                              context.push('/category/${category!.id}'),
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
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.productDetailSpecificationsHeading,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                _SpecRow(label: l10n.productSpecMaterial, value: specs.material),
                _SpecRow(label: l10n.productSpecOrigin, value: specs.origin),
                _SpecRow(label: l10n.productSpecPackaging, value: specs.packaging),
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
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
