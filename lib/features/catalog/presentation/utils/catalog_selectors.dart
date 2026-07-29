import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

/// Pure, in-memory derivations over the full category/product lists
/// fetched by `catalog_providers.dart` — the real-data equivalent of what
/// `MockCatalogData`'s static helpers used to do, kept as free functions
/// (not repository methods) since none of this is a backend query.
Category? categoryById(List<Category> categories, String id) {
  for (final category in categories) {
    if (category.id == id) return category;
  }
  return null;
}

Product? productById(List<Product> products, String id) {
  for (final product in products) {
    if (product.id == id) return product;
  }
  return null;
}

List<Product> productsForCategory(List<Product> products, String categoryId) =>
    products.where((p) => p.categoryId == categoryId).toList();

/// Other products in the same category, excluding [product] itself —
/// backs Product Detail's Related Products rail. `cms_products` has a
/// `related_products` column but it's empty in production today, so this
/// category-based fallback is the actual behavior, not a fallback for one.
List<Product> relatedProducts(
  List<Product> products,
  Product product, {
  int limit = 6,
}) {
  final related = productsForCategory(products, product.categoryId)
      .where((p) => p.id != product.id)
      .toList();
  return related.length > limit ? related.sublist(0, limit) : related;
}

/// Products explicitly flagged `featured` in the CMS. Only as many
/// products as the CMS team has actually flagged — a short (or empty)
/// rail here reflects real content, not a bug.
List<Product> featuredProducts(List<Product> products, {int limit = 8}) {
  final featured = products.where((p) => p.featured).toList()
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return featured.length > limit ? featured.sublist(0, limit) : featured;
}

/// Most recently added products, per `created_at`.
List<Product> newArrivalProducts(List<Product> products, {int limit = 8}) {
  final sorted = [...products]..sort((a, b) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null || bDate == null) return 0;
    return bDate.compareTo(aDate);
  });
  return sorted.length > limit ? sorted.sublist(0, limit) : sorted;
}

/// `cms_products` has no sales/order-count column, so there's no real
/// "best seller" signal to sort by yet. Until one exists, this rail shows
/// real catalog products ordered by their CMS `display_order`, excluding
/// anything already shown in the Featured rail (for rail variety) — a
/// content-team-controlled curation, not a fabricated metric.
List<Product> bestSellerProducts(List<Product> products, {int limit = 8}) {
  final featuredIds = featuredProducts(products).map((p) => p.id).toSet();
  final sorted = products.where((p) => !featuredIds.contains(p.id)).toList()
    ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  return sorted.length > limit ? sorted.sublist(0, limit) : sorted;
}
