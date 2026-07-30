import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/entities/product.dart';
import '../domain/product_repository.dart';
import 'catalog_cache_service.dart';

/// Reads `cms_products` directly — confirmed schema per
/// docs/BACKEND_MAPPING_REPORT.md §2. Only the columns the app actually
/// consumes are selected (the table also carries SEO/tags/downloads/specs
/// fields this app has no UI for yet).
///
/// Each method falls back to [CatalogCacheService]'s last-known-good
/// snapshot when the live fetch fails — see
/// [SupabaseCategoryRepository]'s doc comment for why. The four query
/// shapes (all/featured/new-arrivals/best-sellers) select the same lean
/// columns but differ in which rows/order they return, so each gets its
/// own cache slot rather than trying to re-derive one from another.
class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this._client, this._cache);

  final SupabaseClient _client;
  final CatalogCacheService _cache;

  static const _columns =
      'id, category_id, name_en, name_ar, desc_en, desc_ar, price, img';

  @override
  Future<List<Product>> getProducts() async {
    try {
      final rows = await _client
          .from(SupabaseTables.products)
          .select(_columns)
          // RLS already excludes deleted/disabled/unpublished rows for
          // anon reads (confirmed per docs/BACKEND_MAPPING_REPORT.md §2) —
          // filtered again here too, defensively, per
          // docs/SUPABASE_INTEGRATION.md §4/§8's "RLS is the only boundary
          // trusted, never gated purely client-side" principle applied in
          // the safer direction: belt AND suspenders, not one or the other.
          .eq('is_deleted', false)
          .eq('enabled', true)
          .eq('status', 'published')
          .order('display_order');
      return _mapAndCache(rows, _cache.setProducts);
    } catch (error, stackTrace) {
      return _fallbackOrThrow(_cache.getProducts(), error, stackTrace, 'getProducts');
    }
  }

  /// Products with `featured = true` — a real column, ordered by the CMS's
  /// own `display_order`. Only 1 product carries this flag today (per
  /// docs/BACKEND_MAPPING_REPORT.md §3) — an honest reflection of current
  /// data, not a bug.
  @override
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final rows = await _client
          .from(SupabaseTables.products)
          .select(_columns)
          .eq('is_deleted', false)
          .eq('enabled', true)
          .eq('status', 'published')
          .eq('featured', true)
          .order('display_order')
          .limit(limit);
      return _mapAndCache(rows, _cache.setFeaturedProducts);
    } catch (error, stackTrace) {
      return _fallbackOrThrow(
        _cache.getFeaturedProducts(),
        error,
        stackTrace,
        'getFeaturedProducts',
      );
    }
  }

  /// Newest products by `created_at` — the closest honest proxy for "new
  /// arrivals" the schema actually supports; there is no dedicated
  /// "new arrival" flag (confirmed absent).
  @override
  Future<List<Product>> getNewArrivals({int limit = 10}) async {
    try {
      final rows = await _client
          .from(SupabaseTables.products)
          .select(_columns)
          .eq('is_deleted', false)
          .eq('enabled', true)
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(limit);
      return _mapAndCache(rows, _cache.setNewArrivals);
    } catch (error, stackTrace) {
      return _fallbackOrThrow(
        _cache.getNewArrivals(),
        error,
        stackTrace,
        'getNewArrivals',
      );
    }
  }

  /// No sales/order data exists anywhere in this schema (confirmed — the
  /// site is an RFQ/inquiry business, not e-commerce checkout; see
  /// docs/BACKEND_INTEGRATION_REPORT.md §1) — there is no real "best
  /// sellers" signal to query. This uses the CMS's manual `display_order`
  /// as the closest honest proxy for "what staff wants shown prominently."
  /// Flagged in docs/BACKEND_MAPPING_REPORT.md as a content-strategy
  /// decision worth revisiting with you, not a schema fact.
  @override
  Future<List<Product>> getBestSellers({int limit = 10}) async {
    try {
      final rows = await _client
          .from(SupabaseTables.products)
          .select(_columns)
          .eq('is_deleted', false)
          .eq('enabled', true)
          .eq('status', 'published')
          .order('display_order')
          .limit(limit);
      return _mapAndCache(rows, _cache.setBestSellers);
    } catch (error, stackTrace) {
      return _fallbackOrThrow(
        _cache.getBestSellers(),
        error,
        stackTrace,
        'getBestSellers',
      );
    }
  }

  Future<List<Product>> _mapAndCache(
    List<dynamic> rows,
    Future<void> Function(List<Map<String, dynamic>>) cacheWriter,
  ) async {
    final rowMaps = rows.cast<Map<String, dynamic>>();
    await cacheWriter(rowMaps);
    return rowMaps.map(_mapProduct).toList();
  }

  List<Product> _fallbackOrThrow(
    List<Map<String, dynamic>>? cached,
    Object error,
    StackTrace stackTrace,
    String methodName,
  ) {
    if (cached != null) {
      AppLogger.instance.warning(
        '$methodName failed, serving cached snapshot',
        error: error,
        stackTrace: stackTrace,
      );
      return cached.map(_mapProduct).toList();
    }
    throw ExceptionMapper.map(error, stackTrace);
  }

  @override
  Future<Product?> getProductById(String id) async {
    final parsedId = int.tryParse(id);
    if (parsedId == null) return null;
    try {
      final row = await _client
          .from(SupabaseTables.products)
          .select(_columns)
          .eq('id', parsedId)
          .eq('is_deleted', false)
          .eq('enabled', true)
          .eq('status', 'published')
          .maybeSingle();
      return row == null ? null : _mapProduct(row);
    } catch (error, stackTrace) {
      // Not cached individually — the caller (`productByIdProvider`)
      // already checks the cached full product list first and only
      // reaches this repository call when that lookup misses, so a cold
      // deep-link while offline still has a real fallback path upstream.
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  Product _mapProduct(Map<String, dynamic> row) {
    // A handful of rows have `img` as an empty string rather than null
    // (real data-quality noise, per docs/BACKEND_MAPPING_REPORT.md) — an
    // empty URL isn't "no image" to CachedNetworkImage, it's a request
    // that fails oddly, so it's normalized to null here, at the one place
    // every consumer's imageUrl ultimately comes from.
    final rawImg = row['img'] as String?;
    final imageUrl = (rawImg == null || rawImg.trim().isEmpty) ? null : rawImg;

    return Product(
      id: (row['id'] as int).toString(),
      categoryId: (row['category_id'] as int).toString(),
      nameEn: row['name_en'] as String,
      nameAr: row['name_ar'] as String,
      descriptionEn: (row['desc_en'] as String?) ?? '',
      descriptionAr: (row['desc_ar'] as String?) ?? '',
      // `price` is a numeric column PostgREST serializes as a string, per
      // docs/BACKEND_MAPPING_REPORT.md §2.
      price: double.tryParse(row['price']?.toString() ?? '') ?? 0,
      icon: Icons.image_not_supported_outlined,
      placeholderColor: AppColors.primary,
      imageUrl: imageUrl,
    );
  }
}
