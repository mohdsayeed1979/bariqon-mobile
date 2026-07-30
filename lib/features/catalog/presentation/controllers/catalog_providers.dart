import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/network/supabase_service.dart';
import '../../data/catalog_cache_service.dart';
import '../../data/mock_category_repository.dart';
import '../../data/mock_product_repository.dart';
import '../../data/supabase_category_repository.dart';
import '../../data/supabase_product_repository.dart';
import '../../domain/category_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/product_repository.dart';

/// Picks the repository implementation the same way [EnvConfig]/bootstrap
/// already decide whether Supabase itself gets initialized: unconfigured
/// (no `--dart-define` — true for every `flutter test` run today, and for
/// any dev run without credentials) falls back to the mock repository, so
/// tests and the existing widget suite keep working unchanged. A
/// configured build talks to the real backend. This mirrors, rather than
/// invents, the pattern bootstrap.dart already uses for
/// `Supabase.initialize` itself.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  if (!EnvConfig.isConfigured) return MockCategoryRepository();
  return SupabaseCategoryRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(catalogCacheServiceProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  if (!EnvConfig.isConfigured) return MockProductRepository();
  return SupabaseProductRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(catalogCacheServiceProvider),
  );
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

/// The full product list — 209 rows today, each ~8 lean columns (see
/// [SupabaseProductRepository]'s `_columns`), fetched once and filtered/
/// sorted client-side by the existing `applyProductFilters` /
/// `relatedProducts` helpers, same "in-memory list" shape those already
/// assumed before this phase.
final productsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getProducts();
});

/// Home's three curated rails — see [ProductRepository]'s doc comment for
/// why these are separate repository methods rather than derived
/// client-side from [productsProvider].
final featuredProductsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getFeaturedProducts();
});

final newArrivalsProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getNewArrivals();
});

final bestSellersProvider = FutureProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).getBestSellers();
});

/// Looks up a single product by id — reuses [productsProvider]'s
/// already-fetched list when available (e.g. navigating from a list the
/// user just saw) rather than always making a second round trip, falling
/// back to a direct repository fetch (deep link, or a cold Product Detail
/// open) when it isn't.
final productByIdProvider = FutureProvider.family<Product?, String>((
  ref,
  id,
) async {
  final cached = ref.watch(productsProvider).value;
  if (cached != null) {
    for (final product in cached) {
      if (product.id == id) return product;
    }
  }
  return ref.watch(productRepositoryProvider).getProductById(id);
});

/// Keeps the five catalog providers above live-updating whenever
/// `cms_products`/`cms_categories` change on the backend — Supabase
/// Realtime's Postgres Changes feature, per this phase's "realtime
/// polish" scope. A no-op when unconfigured (tests, dev without
/// credentials) so it's always safe to watch.
///
/// This deliberately doesn't try to hand-merge row-level diffs into the
/// existing `FutureProvider<List<...>>` shape every screen already
/// depends on — it just invalidates them on any change event, so they
/// refetch through the exact same (now cache-backed) path a manual pull
/// -to-refresh would. Simpler, and doesn't require reshaping any
/// consuming widget. If Realtime replication isn't enabled for these two
/// tables in the Supabase dashboard, this channel simply never emits —
/// the app still works exactly as before via the normal one-shot fetch.
final catalogRealtimeSyncProvider = Provider<void>((ref) {
  if (!EnvConfig.isConfigured) return;
  final client = ref.watch(supabaseClientProvider);

  void invalidateAll() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(featuredProductsProvider);
    ref.invalidate(newArrivalsProvider);
    ref.invalidate(bestSellersProvider);
  }

  final channel = client.channel('catalog-sync')
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: SupabaseTables.products,
      callback: (_) => invalidateAll(),
    )
    ..onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: SupabaseTables.categories,
      callback: (_) => invalidateAll(),
    )
    ..subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });
});
