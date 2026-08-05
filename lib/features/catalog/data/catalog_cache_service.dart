import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/local_preferences_service.dart';

/// Last-known-good snapshot of the catalog's two fetches (categories,
/// products), so Home/Categories/Products still show real data when a
/// live Supabase fetch fails (no connectivity, a timeout, a flaky
/// connection) rather than an empty error screen.
///
/// Stores the *raw* Postgrest row maps (JSON-safe: strings/ints/nulls/
/// lists), not domain entities — [Category]/[Product] carry an
/// [IconData]/[Color] that don't round-trip through JSON, and the
/// repositories already have `_mapRow` functions to turn a row into an
/// entity, so a cached row rehydrates through the exact same path a fresh
/// one does.
///
/// Reuses [sharedPreferencesProvider] rather than a new storage plugin —
/// same "defaults to null, tests degrade gracefully" shape as
/// [LocalPreferencesService].
class CatalogCacheService {
  CatalogCacheService(this._prefs);

  final SharedPreferences? _prefs;

  static const _categoriesKey = 'cache_categories';
  static const _productsKey = 'cache_products';

  List<Map<String, dynamic>>? _read(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, List<Map<String, dynamic>> rows) async {
    await _prefs?.setString(key, jsonEncode(rows));
  }

  List<Map<String, dynamic>>? getCategories() => _read(_categoriesKey);
  Future<void> setCategories(List<Map<String, dynamic>> rows) =>
      _write(_categoriesKey, rows);

  List<Map<String, dynamic>>? getProducts() => _read(_productsKey);
  Future<void> setProducts(List<Map<String, dynamic>> rows) =>
      _write(_productsKey, rows);
}

final catalogCacheServiceProvider = Provider<CatalogCacheService>((ref) {
  return CatalogCacheService(ref.watch(sharedPreferencesProvider));
});
