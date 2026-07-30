import 'entities/product.dart';

/// The stable contract catalog screens depend on — see
/// [CategoryRepository]'s doc comment for the same pattern applied here.
///
/// The three curated-rail methods exist because Home's UI structurally
/// needs three distinct product lists (per the original Phase 2B design)
/// and the real backend has no "new arrivals"/"best sellers" concept to
/// match mock data's hand-picked lists — see [SupabaseProductRepository]'s
/// doc comment and docs/BACKEND_MAPPING_REPORT.md for exactly what each
/// one actually queries on the real backend.
abstract class ProductRepository {
  /// The full catalog — Product Listing, Category Detail, and related
  /// products all filter/sort this client-side (see
  /// presentation/utils/product_filter_utils.dart).
  Future<List<Product>> getProducts();

  Future<List<Product>> getFeaturedProducts({int limit = 10});

  Future<List<Product>> getNewArrivals({int limit = 10});

  Future<List<Product>> getBestSellers({int limit = 10});

  Future<Product?> getProductById(String id);
}
