import 'package:flutter/material.dart';

/// Plain domain entity for the mock-data Home/Categories screens. Field
/// shape mirrors what's confirmed (and left open) in
/// docs/API_CONTRACT.md §2 — bilingual name pair, price, and now
/// [categoryId] (the unconfirmed real linkage field is flagged there too;
/// this mirrors the shape without asserting it's correct) — plus a
/// [placeholderColor]/[icon] pair used in place of real product
/// photography, which only exists once Supabase Storage is connected
/// (Phase 3+).
@immutable
class Product {
  const Product({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.price,
    required this.icon,
    required this.placeholderColor,
  });

  final String id;

  /// Matches [Category.id] of the mock category this product belongs to.
  final String categoryId;

  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;

  /// BHD. `double` is fine for mock/display purposes here — the real
  /// column's type is unconfirmed per docs/API_CONTRACT.md §2.
  final double price;

  final IconData icon;
  final Color placeholderColor;

  String name(Locale locale) => locale.languageCode == 'ar' ? nameAr : nameEn;

  String description(Locale locale) =>
      locale.languageCode == 'ar' ? descriptionAr : descriptionEn;
}
