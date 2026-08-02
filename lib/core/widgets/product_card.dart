import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'price_tag.dart';
import 'product_image.dart';

/// Product tile for horizontally-scrolling product rails, per
/// docs/DESIGN_SYSTEM.md §8 and docs/SCREEN_SPECIFICATIONS.md §3/§18.
/// Shows the product's real photo ([imageUrl], Supabase Storage) via
/// [ProductImage]; [icon]/[placeholderColor] are its loading/error
/// fallback.
///
/// Sizes itself to its own content (`mainAxisSize.min` throughout,
/// `maxLines`/fixed heights on every text row) rather than depending on a
/// parent handing it a specific height — that's what let a mismatched
/// guessed height overflow in the first Phase 2B pass. The scroller that
/// hosts this card (see product_section.dart) sizes itself to this card's
/// natural height instead of the other way around.
///
/// Sized to [_width] deliberately narrow enough that [ProductResultsView]'s
/// `Wrap` (All Products/Category Detail) naturally shows two per row on a
/// typical ~360dp-wide phone, rather than one oversized card at a time —
/// a UI-polish fix, not a layout-container change (still the same `Wrap`).
/// Wrapped in a [RepaintBoundary] by its callers so repainting one card
/// (e.g. its shimmer/fade-in) doesn't force neighboring cards to repaint.
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
    this.imageUrl,
    this.onSendInquiry,
    this.onTap,
  });

  final String title;
  final String description;
  final double price;
  final IconData icon;
  final Color placeholderColor;
  final String? imageUrl;
  final String sendInquiryLabel;
  final VoidCallback? onSendInquiry;
  final VoidCallback? onTap;

  /// Card width and image aspect ratio — narrower/shorter than the
  /// previous pass so two fit per row in `Wrap` on a ~360dp screen
  /// instead of one, and so each card is cheaper to build/layout/paint
  /// (smaller image decode target, less text) — a direct, low-risk
  /// contributor to smoother scrolling on a long product list.
  static const double _width = 156;
  static const double _imageAspectRatio = 1.4;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: _width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: _imageAspectRatio,
                child: ProductImage(
                  imageUrl: imageUrl,
                  icon: icon,
                  placeholderColor: placeholderColor,
                  // Decode target sized to roughly the card's rendered
                  // pixel size (times ~2 for hi-dpi screens) rather than
                  // the source photo's full resolution — real product
                  // photos can be large, and decoding/holding a
                  // full-resolution bitmap in memory for a ~156×111
                  // logical-pixel tile wastes both CPU and memory on
                  // every card in view.
                  memCacheWidth: (_width * 2).round(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    PriceTag(price: price),
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: FilledButton.tonal(
                        onPressed: onSendInquiry,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: Text(
                          sendInquiryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium,
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
