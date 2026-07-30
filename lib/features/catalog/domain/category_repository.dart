import 'entities/category.dart';

/// The stable contract catalog screens depend on — mirrors the pattern
/// established for Inquiry (Phase 3) and Auth (Phase 4):
/// [MockCategoryRepository] backs tests/unconfigured runs,
/// [SupabaseCategoryRepository] backs the real app once
/// `SUPABASE_URL`/`SUPABASE_ANON_KEY` are supplied — see
/// presentation/controllers/catalog_providers.dart for the switch.
abstract class CategoryRepository {
  Future<List<Category>> getCategories();
}
