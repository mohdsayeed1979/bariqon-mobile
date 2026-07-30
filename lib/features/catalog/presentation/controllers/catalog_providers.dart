import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/env_config.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/network/supabase_service.dart';
import '../../data/catalog_cache_service.dart';
import '../../data/supabase_category_repository.dart';
import '../../data/supabase_product_repository.dart';
import '../../domain/category_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/product_repository.dart';

/// The single place each catalog repository is chosen — swap either
/// implementation here later and nothing else needs to change, mirroring
/// the Auth/Inquiry Cart provider pattern. Both repositories get
/// [catalogCacheServiceProvider] for offline fallback (see
/// [CatalogCacheService]'s doc comment).
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return SupabaseCategoryRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(catalogCacheServiceProvider),
  );
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(catalogCacheServiceProvider),
  );
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

/// Keeps [categoriesProvider]/[productsProvider] live-updating whenever
/// `cms_products`/`cms_categories` change on the backend — Supabase
/// Realtime's Postgres Changes feature. A no-op when unconfigured (tests
/// override the repository providers directly and never call
/// `Supabase.initialize`, so `supabaseClientProvider` isn't safe to touch
/// here without this guard) so it's always safe to watch.
///
/// Deliberately doesn't hand-merge row-level diffs into the existing
/// `FutureProvider<List<...>>` shape every screen already depends on — it
/// just invalidates them on any change event, so they refetch through the
/// exact same (now cache-backed) path a manual pull-to-refresh would. If
/// Realtime replication isn't enabled for these two tables in the
/// Supabase dashboard, this channel simply never emits — the app still
/// works exactly as before via the normal one-shot fetch.
final catalogRealtimeSyncProvider = Provider<void>((ref) {
  if (!EnvConfig.isConfigured) return;
  final client = ref.watch(supabaseClientProvider);

  void invalidateAll() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(productsProvider);
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
