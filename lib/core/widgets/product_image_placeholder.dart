import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The single "no photo available" visual for product imagery — used for
/// [ProductCard] and Product Detail's gallery slot whenever a product has
/// no `imageUrl`, its image is still loading, or it failed to load. Shows
/// the Bariqon brand mark on the brand gradient rather than a generic
/// Material icon or (worse) Flutter's default broken-image glyph, per the
/// "premium Bariqon placeholder, never a broken-image icon" bug fix.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // The brand mark's source file has an opaque white background (it's
    // the launcher-icon source), not a transparent one — a light tile
    // here lets it sit naturally instead of showing as a white box on
    // top of a dark one. A thin gold edge keeps it feeling like a
    // deliberate brand moment rather than empty white space.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.5,
          heightFactor: 0.5,
          child: Image.asset(
            'assets/icons/app_icon_source.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
