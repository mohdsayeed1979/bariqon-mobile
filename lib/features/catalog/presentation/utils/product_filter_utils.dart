import 'package:flutter/widgets.dart';

import '../../domain/entities/product.dart';

/// Shared sort options for any screen that lists products (Category
/// Detail, Product Listing) — one enum so both screens' [SortDropdown]
/// instances stay in sync rather than each defining their own.
enum ProductSortOption { featured, priceLowHigh, priceHighLow, nameAZ }

/// Applies an optional category filter, search query, price-range filter,
/// and sort — in that order — to a product list. Pure, synchronous,
/// entirely local: this is presentation-layer state management over an
/// in-memory mock list, not a backend query. Shared by Category Detail
/// (fixed `categoryId`) and Product Listing (`categoryId` chosen via a
/// filter chip) so the filtering behavior can't drift between the two.
List<Product> applyProductFilters({
  required List<Product> source,
  required Locale locale,
  String? categoryId,
  String searchQuery = '',
  int priceFilterIndex = 0,
  ProductSortOption sort = ProductSortOption.featured,
}) {
  var list = source.where((p) {
    if (categoryId != null && p.categoryId != categoryId) return false;
    if (searchQuery.isNotEmpty &&
        !p.name(locale).toLowerCase().contains(searchQuery.toLowerCase())) {
      return false;
    }
    return switch (priceFilterIndex) {
      1 => p.price < 15,
      2 => p.price >= 15 && p.price <= 25,
      3 => p.price > 25,
      _ => true,
    };
  }).toList();

  switch (sort) {
    case ProductSortOption.priceLowHigh:
      list.sort((a, b) => a.price.compareTo(b.price));
    case ProductSortOption.priceHighLow:
      list.sort((a, b) => b.price.compareTo(a.price));
    case ProductSortOption.nameAZ:
      list.sort((a, b) => a.name(locale).compareTo(b.name(locale)));
    case ProductSortOption.featured:
      break;
  }
  return list;
}
