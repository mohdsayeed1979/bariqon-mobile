import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/category_repository.dart';
import '../domain/entities/category.dart';
import '../presentation/utils/category_icon_utils.dart';
import 'catalog_cache_service.dart';

/// Real `cms_categories`-backed [CategoryRepository], per
/// [SupabaseTables.categories]. Replaces the Phase 2/3 mock — same
/// interface, so no screen needed to change to pick this up.
///
/// Falls back to [CatalogCacheService]'s last-known-good snapshot when the
/// live fetch fails (no connectivity, timeout, flaky connection) — offline
/// resilience so Categories still shows real data rather than an error
/// screen whenever there's something to show.
class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this._client, this._cache);

  final SupabaseClient _client;
  final CatalogCacheService _cache;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final rows = await _client
          .from(SupabaseTables.categories)
          .select()
          .order('display_order');
      final rowMaps = (rows as List<dynamic>).cast<Map<String, dynamic>>();
      await _cache.setCategories(rowMaps);
      return rowMaps.map(_mapRow).toList();
    } catch (error, stackTrace) {
      final cached = _cache.getCategories();
      if (cached != null) {
        AppLogger.instance.warning(
          'getCategories failed, serving cached snapshot',
          error: error,
          stackTrace: stackTrace,
        );
        return cached.map(_mapRow).toList();
      }
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  Category _mapRow(Map<String, dynamic> row) {
    final key = (row['key'] as String?) ?? '';
    return Category(
      id: row['id'].toString(),
      key: key,
      nameEn: (row['name_en'] as String?) ?? '',
      nameAr: (row['name_ar'] as String?) ?? '',
      icon: iconForCategoryKey(key),
      displayOrder: (row['display_order'] as num?)?.toInt() ?? 0,
    );
  }
}
