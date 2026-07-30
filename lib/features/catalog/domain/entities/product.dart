import 'package:flutter/material.dart';

/// Plain domain entity for the catalog screens. Field shape mirrors the
/// confirmed `cms_products` columns per docs/BACKEND_MAPPING_REPORT.md §2
/// — bilingual name/description pair, price, [categoryId] (the confirmed
/// `category_id` FK), and now [imageUrl] (the confirmed `img` column, a
/// public Supabase Storage URL). [icon]/[placeholderColor] remain as the
/// fallback visual for the rare product with no `img` — see
/// [ProductCard]/[ProductDetailScreen] for how the two are chosen between.
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
    this.imageUrl,
  });

  final String id;

  /// Matches [Category.id] of the category this product belongs to.
  final String categoryId;

  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;

  /// BHD. Confirmed as a real column (`price`) per
  /// docs/BACKEND_MAPPING_REPORT.md §2 — PostgREST serializes it as a
  /// string, parsed to `double` at the repository boundary.
  final double price;

  final IconData icon;
  final Color placeholderColor;

  /// Public Supabase Storage URL (`img` column) — null for the mock
  /// repository and for any real product without a photo, in which case
  /// [icon]/[placeholderColor] are used instead.
  final String? imageUrl;

  String name(Locale locale) => locale.languageCode == 'ar' ? nameAr : nameEn;

  String description(Locale locale) =>
      locale.languageCode == 'ar' ? descriptionAr : descriptionEn;
}
