import 'package:flutter/material.dart';

/// Plain domain entity for Phase 2B's mock-data Home screen. Field shape
/// mirrors what's confirmed (and left open) in docs/API_CONTRACT.md §2 —
/// bilingual name pair, price — plus a [placeholderColor]/[icon] pair used
/// in place of real product photography, which only exists once Supabase
/// Storage is connected (Phase 3+).
@immutable
class Product {
  const Product({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.price,
    required this.icon,
    required this.placeholderColor,
  });

  final String id;
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
