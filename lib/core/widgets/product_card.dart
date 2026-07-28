import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'price_tag.dart';

/// Product tile for horizontally-scrolling product rails, per
/// docs/DESIGN_SYSTEM.md §8 and docs/SCREEN_SPECIFICATIONS.md §3/§18.
/// [icon]/[placeholderColor] stand in for a product photo — real product
/// imagery is always remote (Supabase Storage) per
/// docs/SUPABASE_INTEGRATION.md §5, and doesn't exist until that's
/// connected in a later phase.
///
/// Sizes itself to its own content (`mainAxisSize.min` throughout,
/// `maxLines`/fixed heights on every text row) rather than depending on a
/// parent handing it a specific height — that's what let a mismatched
/// guessed height overflow in the first Phase 2B pass. The scroller that
/// hosts this card (see product_section.dart) sizes itself to this card's
/// natural height instead of the other way around.
///
/// [onSendInquiry] is UI feedback only in Phase 2B (no cart, no backend) —
/// see home_screen.dart for what it actually does today.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.icon,
    required this.placeholderColor,
    required this.sendInquiryLabel,
    this.onSendInquiry,
    this.onTap,
  });

  final String title;
  final String description;
  final double price;
  final IconData icon;
  final Color placeholderColor;
  final String sendInquiryLabel;
  final VoidCallback? onSendInquiry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 228,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Larger placeholder image area than the first pass, per
              // the polish request — still an honest gradient+icon
              // placeholder, not a stand-in photo (see class doc).
              AspectRatio(
                aspectRatio: 1.15,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        placeholderColor.withValues(alpha: 0.85),
                        placeholderColor.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Icon(icon, size: 48, color: Colors.white),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    PriceTag(price: price),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: FilledButton.tonal(
                        onPressed: onSendInquiry,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          sendInquiryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
