import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/quantity_stepper.dart';
import '../../domain/entities/inquiry_item.dart';

/// One row on the Inquiry Cart screen — product placeholder image, name,
/// price, quantity stepper, remove action. Feature-specific composition
/// of core widgets ([QuantityStepper], [PriceTag]) rather than a bespoke
/// one-off layout.
class InquiryCartItemTile extends StatelessWidget {
  const InquiryCartItemTile({
    super.key,
    required this.item,
    required this.title,
    required this.removeTooltip,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final InquiryItem item;
  final String title;
  final String removeTooltip;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.product.placeholderColor.withValues(alpha: 0.85),
                  item.product.placeholderColor.withValues(alpha: 0.55),
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.product.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                PriceTag(price: item.product.price),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          QuantityStepper(quantity: item.quantity, onChanged: onQuantityChanged),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: removeTooltip,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
