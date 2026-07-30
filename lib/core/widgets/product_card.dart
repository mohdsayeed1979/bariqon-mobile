import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'price_tag.dart';
import 'product_image_placeholder.dart';

/// Product tile for horizontally-scrolling product rails, per
/// docs/DESIGN_SYSTEM.md §8 and docs/SCREEN_SPECIFICATIONS.md §3/§18.
///
/// Shows the real photo at [imageUrl] (a Supabase Storage URL, per
/// docs/BACKEND_MAPPING_REPORT.md §2) when present, via
/// [CachedNetworkImage] — falling back to [ProductImagePlaceholder] while
/// it loads, on error, or when there's no image at all (the mock
/// repository, or a real product missing a photo). [icon]/
/// [placeholderColor] are kept for API compatibility but no longer drive
/// the image slot — a generic icon+color tile risked reading as a broken
/// image rather than deliberate branding, so it was replaced with the
/// premium [ProductImagePlaceholder].
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

  /// Card width and image aspect ratio — deliberately smaller/wider than
  /// the first pass per the "cards feel oversized, image area too large"
  /// polish request: a narrower card fits more per row, and a wider
  /// (shorter) image area leaves more of the card's height for content
  /// instead of empty photo space.
  static const double _width = 168;
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
                // Empty-string URLs (a real data-quality case in
                // `cms_products.img` — see docs/BACKEND_MAPPING_REPORT.md)
                // are treated as "no image" at the repository mapping
                // boundary, but the null-check stays defensive here too.
                child: (imageUrl == null || imageUrl!.isEmpty)
                    ? const ProductImagePlaceholder()
                    : CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            const ProductImagePlaceholder(),
                        errorWidget: (context, url, error) =>
                            const ProductImagePlaceholder(),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
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
