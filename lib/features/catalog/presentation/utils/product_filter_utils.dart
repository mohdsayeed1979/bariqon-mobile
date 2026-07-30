import 'package:flutter/widgets.dart';

import '../../domain/entities/product.dart';

/// Shared sort options for any screen that lists products (Category
/// Detail, Product Listing) — one enum so both screens' [SortDropdown]
/// instances stay in sync rather than each defining their own.
enum ProductSortOption { featured, priceLowHigh, priceHighLow, nameAZ }

/// Applies an optional category filter, search query, price-range filter,
/// and sort — in that order — to a product list. Pure, synchronous,
/// entirely local: this is presentation-layer state management over an
/// in-memory mock list, not a backend query. Shared by Category Detail
/// (fixed `categoryId`) and Product Listing (`categoryId` chosen via a
/// filter chip) so the filtering behavior can't drift between the two.
List<Product> applyProductFilters({
  required List<Product> source,
  required Locale locale,
  String? categoryId,
  String searchQuery = '',
  int priceFilterIndex = 0,
  ProductSortOption sort = ProductSortOption.featured,
}) {
  var list = source.where((p) {
    if (categoryId != null && p.categoryId != categoryId) return false;
    if (searchQuery.isNotEmpty &&
        !p.name(locale).toLowerCase().contains(searchQuery.toLowerCase())) {
      return false;
    }
    return switch (priceFilterIndex) {
      1 => p.price < 15,
      2 => p.price >= 15 && p.price <= 25,
      3 => p.price > 25,
      _ => true,
    };
  }).toList();

  switch (sort) {
    case ProductSortOption.priceLowHigh:
      list.sort((a, b) => a.price.compareTo(b.price));
    case ProductSortOption.priceHighLow:
      list.sort((a, b) => b.price.compareTo(a.price));
    case ProductSortOption.nameAZ:
      list.sort((a, b) => a.name(locale).compareTo(b.name(locale)));
    case ProductSortOption.featured:
      break;
  }
  return list;
}

/// Other products in the same category as [product], excluding [product]
/// itself — backs Product Detail's Related Products rail. Pure/local, same
/// as [applyProductFilters]: operates over an already-fetched list (see
/// `catalog_providers.dart`'s `productsProvider`), not a backend query.
List<Product> relatedProducts(
  List<Product> allProducts,
  Product product, {
  int limit = 6,
}) {
  final related = allProducts
      .where((p) => p.categoryId == product.categoryId && p.id != product.id)
      .toList();
  return related.length > limit ? related.sublist(0, limit) : related;
}

/// Generic, category-derived mock specification values for Product
/// Detail's "Specifications" section — per-category rather than
/// per-product, so this doesn't require hand-authoring specs for every
/// mock product individually. Values are honest placeholders (Origin is
/// the one real, safe claim — Bariqon Trading is Bahrain-based, confirmed
/// in docs/BACKEND_INTEGRATION_REPORT.md); everything else is
/// deliberately generic until real product data exists.
({String material, String origin, String packaging}) mockSpecificationValues(
  String categoryId,
  Locale locale,
) {
  final isAr = locale.languageCode == 'ar';
  const origin = 'Bahrain';
  const originAr = 'البحرين';

  return switch (categoryId) {
    // '1' is the real `cms_categories.id` for Luxury Gift Boxes (see
    // docs/BACKEND_MAPPING_REPORT.md §2) — the mock repository's own slug
    // id is matched alongside it so both data sources still get tailored
    // copy instead of falling through to the generic case below.
    'luxury-gift-boxes' || '1' => (
      material: isAr ? 'خشب ونسيج مضفور' : 'Wood & woven fabric',
      origin: isAr ? originAr : origin,
      packaging: isAr ? 'صندوق هدايا جاهز للتقديم' : 'Gift-ready presentation box',
    ),
    'hospitality' => (
      material: isAr ? 'سيراميك وزجاج' : 'Ceramic & glass',
      origin: isAr ? originAr : origin,
      packaging: isAr ? 'طقم تقديم للضيافة' : 'Hospitality tray set',
    ),
    'perfumery-cosmetics' => (
      material: isAr ? 'زجاج ومعدن' : 'Glass & metal',
      origin: isAr ? originAr : origin,
      packaging: isAr ? 'معبأ مع غلاف واقٍ' : 'Boxed with protective wrap',
    ),
    'toiletries' => (
      material: isAr ? 'قطن وألياف طبيعية' : 'Cotton & natural fibers',
      origin: isAr ? originAr : origin,
      packaging: isAr ? 'حقيبة مناسبة للسفر' : 'Travel-friendly pouch',
    ),
    _ => (
      material: isAr ? 'خامات متنوعة' : 'Mixed materials',
      origin: isAr ? originAr : origin,
      packaging: isAr ? 'تغليف قياسي' : 'Standard packaging',
    ),
  };
}
