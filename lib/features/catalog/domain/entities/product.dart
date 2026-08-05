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
    this.discountEnabled = false,
    this.discountPercentage,
    this.discountPrice,
    this.discountStartDate,
    this.discountEndDate,
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

  /// Whether a discount is currently on for this product — the CMS flag
  /// plus, when set, a start/end window. Absent columns (schema not
  /// migrated yet) map to `false`/`null` via [SupabaseProductRepository],
  /// so this is safe to check unconditionally before that migration runs.
  final bool discountEnabled;
  final double? discountPercentage;
  final double? discountPrice;
  final DateTime? discountStartDate;
  final DateTime? discountEndDate;

  /// True only when [discountEnabled] is on, a [discountPrice] exists,
  /// and (if set) the current time falls within the discount window.
  bool get hasActiveDiscount {
    if (!discountEnabled || discountPrice == null) return false;
    final now = DateTime.now();
    final start = discountStartDate;
    final end = discountEndDate;
    if (start != null && now.isBefore(start)) return false;
    if (end != null && now.isAfter(end)) return false;
    return true;
  }

  /// [discountPrice] while a discount is active, [price] otherwise — the
  /// one price every screen should actually display/inquire about.
  double get effectivePrice => hasActiveDiscount ? discountPrice! : price;

  /// Whole-percent badge value (e.g. `20` for "-20%") — uses the CMS's
  /// own [discountPercentage] when set, otherwise derives it from
  /// [price] vs [discountPrice] so the badge is never wrong even if only
  /// one of the two was filled in. `null` when no discount is active.
  int? get discountBadgePercent {
    if (!hasActiveDiscount) return null;
    if (discountPercentage != null) return discountPercentage!.round();
    if (price <= 0) return null;
    return (((price - discountPrice!) / price) * 100).round();
  }

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
