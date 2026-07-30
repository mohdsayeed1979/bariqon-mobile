import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/local_preferences_service.dart';

/// Last-known-good snapshot of each catalog query, so Home/Categories/
/// Products still show real data when a live Supabase fetch fails (no
/// connectivity, a timeout, a flaky connection) rather than an empty error
/// screen — the "offline polish" half of this phase's scope.
///
/// Stores the *raw* Postgrest row maps (JSON-safe: strings/ints/nulls),
/// not domain entities — [Category]/[Product] carry an [IconData]/[Color]
/// that don't round-trip through JSON, and the repositories already have
/// `_mapCategory`/`_mapProduct` functions to turn a row into an entity, so
/// a cached row rehydrates through the exact same path a fresh one does
/// (identical icon/placeholder derivation, no second mapping to maintain).
///
/// Reuses [sharedPreferencesProvider] rather than a new storage plugin —
/// same "defaults to null, tests degrade gracefully" shape as
/// [LocalPreferencesService].
class CatalogCacheService {
  CatalogCacheService(this._prefs);

  final SharedPreferences? _prefs;

  static const _categoriesKey = 'cache_categories';
  static const _productsKey = 'cache_products_all';
  static const _featuredKey = 'cache_products_featured';
  static const _newArrivalsKey = 'cache_products_new_arrivals';
  static const _bestSellersKey = 'cache_products_best_sellers';

  List<Map<String, dynamic>>? _read(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List)
          .cast<Map<String, dynamic>>();
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

  List<Map<String, dynamic>>? getFeaturedProducts() => _read(_featuredKey);
  Future<void> setFeaturedProducts(List<Map<String, dynamic>> rows) =>
      _write(_featuredKey, rows);

  List<Map<String, dynamic>>? getNewArrivals() => _read(_newArrivalsKey);
  Future<void> setNewArrivals(List<Map<String, dynamic>> rows) =>
      _write(_newArrivalsKey, rows);

  List<Map<String, dynamic>>? getBestSellers() => _read(_bestSellersKey);
  Future<void> setBestSellers(List<Map<String, dynamic>> rows) =>
      _write(_bestSellersKey, rows);
}

final catalogCacheServiceProvider = Provider<CatalogCacheService>((ref) {
  return CatalogCacheService(ref.watch(sharedPreferencesProvider));
});
