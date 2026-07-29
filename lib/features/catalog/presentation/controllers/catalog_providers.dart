import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_service.dart';
import '../../data/supabase_category_repository.dart';
import '../../data/supabase_product_repository.dart';
import '../../domain/category_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/product_repository.dart';

/// The single place each catalog repository is chosen — swap either
/// implementation here later (e.g. add caching) and nothing else needs to
/// change, mirroring the Auth/Inquiry Cart provider pattern.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return SupabaseCategoryRepository(ref.watch(supabaseClientProvider));
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository(ref.watch(supabaseClientProvider));
});

/// The full published category/product list, fetched once and cached by
/// Riverpod — every screen watches these (via [AsyncValueView]) and
/// derives what it needs client-side (see `catalog_selectors.dart`)
/// instead of issuing its own query.
final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getProducts();
});

/// Combines [categoriesProvider] and [productsProvider] into one
/// [AsyncValue] — screens that need both (Category Detail, Product
/// Listing, Product Detail) watch this instead of hand-rolling nested
/// `.when()` calls over two separate futures.
final catalogProvider = Provider<AsyncValue<(List<Category>, List<Product>)>>((
  ref,
) {
  final categories = ref.watch(categoriesProvider);
  final products = ref.watch(productsProvider);
  return categories.when(
    data: (c) => products.when(
      data: (p) => AsyncData((c, p)),
      loading: () => const AsyncLoading(),
      error: AsyncError.new,
    ),
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
  );
});
