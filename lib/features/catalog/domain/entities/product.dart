import 'package:flutter/material.dart';

/// Plain domain entity, populated from the real `cms_products` table (see
/// `SupabaseProductRepository`). [icon]/[placeholderColor] are
/// presentation-only fallbacks used while [imageUrl] loads or if it's
/// missing/fails — not backend data.
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
    this.currency = 'BHD',
    this.imageUrl,
    this.galleryImages = const [],
    this.featuresEn = const [],
    this.featuresAr = const [],
    this.stockStatus,
    this.sku,
    this.featured = false,
    this.displayOrder = 0,
    this.createdAt,
  });

  final String id;

  /// Matches [Category.id] of the category this product belongs to.
  final String categoryId;

  final String nameEn;
  final String nameAr;
  final String descriptionEn;
  final String descriptionAr;

  final double price;
  final String currency;

  /// Public Supabase Storage URL (`cms_products.img`) — null/empty falls
  /// back to [icon]/[placeholderColor].
  final String? imageUrl;

  /// Additional gallery photos (`cms_products.gallery_images`); empty in
  /// production today, so Product Detail falls back to [imageUrl] alone.
  final List<String> galleryImages;

  final List<String> featuresEn;
  final List<String> featuresAr;

  final String? stockStatus;
  final String? sku;
  final bool featured;
  final int displayOrder;
  final DateTime? createdAt;

  final IconData icon;
  final Color placeholderColor;

  String name(Locale locale) => locale.languageCode == 'ar' ? nameAr : nameEn;

  String description(Locale locale) =>
      locale.languageCode == 'ar' ? descriptionAr : descriptionEn;

  List<String> features(Locale locale) =>
      locale.languageCode == 'ar' ? featuresAr : featuresEn;

  /// All images for the gallery — [imageUrl] first, then [galleryImages],
  /// de-duplicated, empty entries dropped.
  List<String> get allImages => [
    if (imageUrl != null && imageUrl!.isNotEmpty) imageUrl!,
    for (final url in galleryImages)
      if (url.isNotEmpty && url != imageUrl) url,
  ];
}
