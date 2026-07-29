import 'entities/product.dart';

/// The stable contract catalog providers depend on, mirroring the
/// Auth/Inquiry Cart pattern — a repository swap (e.g. adding caching or
/// server-side pagination) doesn't require touching any screen.
abstract class ProductRepository {
  /// All published, enabled products. Callers filter/sort/derive
  /// (featured, new arrivals, related, search) client-side over this list
  /// — matching the existing `applyProductFilters` pattern rather than a
  /// new query per view.
  Future<List<Product>> getProducts();
}
