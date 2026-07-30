import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/category_repository.dart';
import '../domain/entities/category.dart';
import 'catalog_cache_service.dart';

/// Reads `cms_categories` directly — confirmed schema per
/// docs/BACKEND_MAPPING_REPORT.md §2: `id, key, name_en, name_ar,
/// display_order, created_at`. No description or image/icon column exists
/// in the real table (confirmed absent by live probing, not just
/// unpopulated) — see [Category]'s doc comment for why
/// [Category.descriptionEn]/[descriptionAr] are left null here rather than
/// filled with invented copy, and [_iconFor] for the icon fallback.
///
/// Falls back to [CatalogCacheService]'s last-known-good snapshot when the
/// live fetch fails (no connectivity, timeout, flaky connection) — the
/// "offline polish" phase's requirement that Categories still shows data
/// rather than an error screen whenever there's something to show.
class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this._client, this._cache);

  final SupabaseClient _client;
  final CatalogCacheService _cache;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final rows = await _client
          .from(SupabaseTables.categories)
          .select('id, name_en, name_ar')
          .order('display_order');
      final rowMaps = (rows as List<dynamic>).cast<Map<String, dynamic>>();
      await _cache.setCategories(rowMaps);
      return rowMaps.map(_mapCategory).toList();
    } catch (error, stackTrace) {
      final cached = _cache.getCategories();
      if (cached != null) {
        AppLogger.instance.warning(
          'getCategories failed, serving cached snapshot',
          error: error,
          stackTrace: stackTrace,
        );
        return cached.map(_mapCategory).toList();
      }
      throw ExceptionMapper.map(error, stackTrace);
    }
  }

  Category _mapCategory(Map<String, dynamic> row) {
    final nameEn = row['name_en'] as String;
    return Category(
      id: (row['id'] as int).toString(),
      nameEn: nameEn,
      nameAr: row['name_ar'] as String,
      icon: _iconFor(nameEn),
    );
  }

  /// Same icons already shown for these two categories in the mock data —
  /// visually unchanged for what exists today. Any category added to the
  /// backend later without a matching name here just gets the generic
  /// fallback rather than breaking.
  IconData _iconFor(String nameEn) => switch (nameEn) {
    'Luxury Gift Boxes' => Icons.card_giftcard_outlined,
    'General Trading' => Icons.storefront_outlined,
    _ => Icons.category_outlined,
  };
}
