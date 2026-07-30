import '../domain/category_repository.dart';
import '../domain/entities/category.dart';
import 'mock_catalog_data.dart';

/// Backs tests and any unconfigured run (per `EnvConfig.isConfigured` —
/// see catalog_providers.dart) — same mock data every catalog screen used
/// before Phase 5, now reached through the repository interface instead
/// of static calls.
class MockCategoryRepository implements CategoryRepository {
  @override
  Future<List<Category>> getCategories() async => MockCatalogData.categories;
}
