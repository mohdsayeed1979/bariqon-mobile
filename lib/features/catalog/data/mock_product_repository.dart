import '../domain/entities/product.dart';
import '../domain/product_repository.dart';
import 'mock_catalog_data.dart';

/// Backs tests and any unconfigured run — see [MockCategoryRepository].
class MockProductRepository implements ProductRepository {
  @override
  Future<List<Product>> getProducts() async => MockCatalogData.allProducts;

  @override
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async =>
      MockCatalogData.featured;

  @override
  Future<List<Product>> getNewArrivals({int limit = 10}) async =>
      MockCatalogData.newArrivals;

  @override
  Future<List<Product>> getBestSellers({int limit = 10}) async =>
      MockCatalogData.bestSellers;

  @override
  Future<Product?> getProductById(String id) async =>
      MockCatalogData.productById(id);
}
