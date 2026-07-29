import 'package:flutter/material.dart';

/// `cms_categories` has no icon column — this is a presentation-only,
/// best-effort mapping from a category's `key`/name to a reasonable icon,
/// so real categories still get a distinct visual instead of one generic
/// glyph everywhere. Matched case-insensitively against known business
/// lines; anything unrecognized (including future categories added in the
/// CMS) falls back to a generic storefront icon rather than guessing.
IconData iconForCategoryKey(String key) {
  final normalized = key.toLowerCase();

  if (normalized.contains('gift')) return Icons.card_giftcard_outlined;
  if (normalized.contains('hospitality')) return Icons.hotel_outlined;
  if (normalized.contains('perfum') || normalized.contains('cosmetic')) {
    return Icons.spa_outlined;
  }
  if (normalized.contains('toiletr') || normalized.contains('bath')) {
    return Icons.soap_outlined;
  }
  if (normalized.contains('trading') || normalized.contains('general')) {
    return Icons.storefront_outlined;
  }

  return Icons.storefront_outlined;
}
