import 'entities/category.dart';

/// The stable contract catalog providers depend on, mirroring the
/// Auth/Inquiry Cart pattern — a repository swap (e.g. adding caching)
/// doesn't require touching any screen.
abstract class CategoryRepository {
  Future<List<Category>> getCategories();
}
