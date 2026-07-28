import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'price_tag.dart';

/// "Total selected products / estimated total" summary, per the Phase 3
/// brief's Inquiry Summary requirement — display only, no computation
/// beyond a sum of the cart already in memory. Reused on both the Inquiry
/// Cart screen and as a recap on the Inquiry Details Form, rather than
/// each screen laying this out separately.
class InquirySummaryCard extends StatelessWidget {
  const InquirySummaryCard({
    super.key,
    required this.itemsLabel,
    required this.totalLabel,
    required this.estimatedTotal,
  });

  final String itemsLabel;
  final String totalLabel;
  final double estimatedTotal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              itemsLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                totalLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              PriceTag(
                price: estimatedTotal,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
