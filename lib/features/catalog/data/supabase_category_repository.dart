import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_tables.dart';
import '../../../core/error/exception_mapper.dart';
import '../domain/category_repository.dart';
import '../domain/entities/category.dart';
import '../presentation/utils/category_icon_utils.dart';

/// Real `cms_categories`-backed [CategoryRepository], per
/// [SupabaseTables.categories]. Replaces the Phase 2/3 mock — same
/// interface, so no screen needed to change to pick this up.
class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Category>> getCategories() async {
    try {
      final rows = await _client
          .from(SupabaseTables.categories)
          .select()
          .order('display_order');

      return rows.map(_mapRow).toList();
    } catch (error, stackTrace) {
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
