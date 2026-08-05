import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/entities/product.dart';
import '../domain/product_repository.dart';
import '../presentation/utils/product_placeholder_utils.dart';
import 'catalog_cache_service.dart';

/// Real `cms_products`-backed [ProductRepository], per
/// [SupabaseTables.products]. Replaces the Phase 2/3 mock — same
/// interface, so no screen needed to change to pick this up.
///
/// Fetches the full published catalog in one call (209 rows in
/// production today) rather than a query per screen/filter — cheap at
/// this size and lets every screen keep using the existing
/// `applyProductFilters`-style client-side filtering/sorting instead of
/// re-deriving it as server queries.
///
/// Falls back to [CatalogCacheService]'s last-known-good snapshot when the
/// live fetch fails — see [SupabaseCategoryRepository]'s doc comment for
/// why.
class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this._client, this._cache);

  final SupabaseClient _client;
  final CatalogCacheService _cache;

  @override
  Future<List<Product>> getProducts() async {
    try {
      final rows = await _client
          .from(SupabaseTables.products)
          .select()
          .eq('status', 'published')
          .eq('enabled', true)
          .eq('is_deleted', false)
          .order('display_order');
      final rowMaps = (rows as List<dynamic>).cast<Map<String, dynamic>>();
      await _cache.setProducts(rowMaps);
      return rowMaps.map(_mapRow).toList();
    } catch (error, stackTrace) {
      final cached = _cache.getProducts();
      if (cached != null) {
        AppLogger.instance.warning(
          'getProducts failed, serving cached snapshot',
          error: error,
          stackTrace: stackTrace,
        );
        return cached.map(_mapRow).toList();
      }
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  Product _mapRow(Map<String, dynamic> row) {
    final id = row['id'].toString();
    final imageUrl = row['img'] as String?;

    return Product(
      id: id,
      categoryId: row['category_id'].toString(),
      nameEn: (row['name_en'] as String?) ?? '',
      nameAr: (row['name_ar'] as String?) ?? '',
      descriptionEn: (row['desc_en'] as String?) ?? '',
      descriptionAr: (row['desc_ar'] as String?) ?? '',
      price: double.tryParse(row['price']?.toString() ?? '') ?? 0,
      currency: (row['currency'] as String?) ?? 'BHD',
      imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
      galleryImages: _stringList(row['gallery_images']),
      featuresEn: _stringList(row['features_en']),
      featuresAr: _stringList(row['features_ar']),
      stockStatus: row['stock_status'] as String?,
      sku: row['sku'] as String?,
      featured: (row['featured'] as bool?) ?? false,
      displayOrder: (row['display_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      // Discount columns don't exist in production yet (see
      // docs/DISCOUNT_WISHLIST_MIGRATION.sql) — a full-row `.select()`
      // simply omits missing keys rather than erroring, so every one of
      // these defaults to "no discount" until that migration is applied.
      discountEnabled: (row['discount_enabled'] as bool?) ?? false,
      discountPercentage: (row['discount_percentage'] as num?)?.toDouble(),
      discountPrice: (row['discount_price'] as num?)?.toDouble(),
      discountStartDate: DateTime.tryParse(row['discount_start_date']?.toString() ?? ''),
      discountEndDate: DateTime.tryParse(row['discount_end_date']?.toString() ?? ''),
      icon: productPlaceholderIcon,
      placeholderColor: placeholderColorForProductId(id),
    );
  }

  List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().where((s) => s.isNotEmpty).toList();
  }
}
