import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// `cms_products` has no icon/placeholder-color column — these are
/// presentation-only fallbacks shown while a product's real photo
/// ([Product.imageUrl]) loads or if it's missing/fails to load. Picked
/// deterministically from the product id so the same product always shows
/// the same fallback (not random on every rebuild).
const _placeholderColors = [
  AppColors.primary,
  AppColors.gold,
  AppColors.goldLight,
];

Color placeholderColorForProductId(String id) {
  return _placeholderColors[id.hashCode.abs() % _placeholderColors.length];
}

/// One generic "product" glyph — per-category icon would misrepresent an
/// individual product, and `cms_products` has no icon data to draw a more
/// specific one from.
const IconData productPlaceholderIcon = Icons.inventory_2_outlined;
