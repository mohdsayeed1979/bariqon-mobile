import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../domain/entities/inquiry_item.dart';

/// One row on the Inquiry Cart screen — product photo, category, SKU,
/// name, quantity stepper, and a remove action, matching the website's
/// own cart drawer section-for-section (image / category+SKU / name /
/// quantity+remove).
class InquiryCartItemTile extends StatelessWidget {
  const InquiryCartItemTile({
    super.key,
    required this.item,
    required this.title,
    required this.removeLabel,
    this.categoryLabel,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final InquiryItem item;
  final String title;
  final String removeLabel;

  /// Null while categories haven't loaded yet — the row still renders
  /// (SKU/name/quantity aren't blocked on it), just without the category
  /// line until it resolves.
  final String? categoryLabel;

  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sku = item.product.sku;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: ProductImage(
                    imageUrl: item.product.imageUrl,
                    icon: item.product.icon,
                    placeholderColor: item.product.placeholderColor,
                    iconSize: 28,
                    memCacheWidth: 128,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (categoryLabel != null)
                          Expanded(
                            child: Text(
                              categoryLabel!.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        if (sku != null && sku.isNotEmpty) ...[
                          if (categoryLabel != null) const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppColors.gold.withValues(alpha: 0.4),
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                sku,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              QuantityStepper(quantity: item.quantity, onChanged: onQuantityChanged),
              TextButton.icon(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(removeLabel),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
