import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_product_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/product.dart';
import 'product_section.dart';

/// Home's Featured Products / New Arrivals / Best Sellers rails — same
/// [SectionHeader] + horizontal row shape as [ProductSection], but backed
/// by a [FutureProvider] (see catalog_providers.dart) instead of an
/// already-in-hand list, so it needs its own loading/error rendering
/// around [ProductCardRow] rather than [ProductSection]'s synchronous one.
class AsyncProductRail extends StatelessWidget {
  const AsyncProductRail({
    super.key,
    required this.title,
    required this.productsAsync,
  });

  final String title;
  final AsyncValue<List<Product>> productsAsync;

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
        productsAsync.when(
          data: (products) => ProductCardRow(products: products),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                SkeletonProductCard(),
                SizedBox(width: AppSpacing.md),
                SkeletonProductCard(),
              ],
            ),
          ),
          error: (error, stackTrace) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              l10n.genericErrorMessage,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}
