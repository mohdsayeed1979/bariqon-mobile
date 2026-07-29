import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_bar_search_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/filter_chip_row.dart';
import '../../../core/widgets/product_results_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/sort_dropdown.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/catalog_providers.dart';
import 'utils/product_filter_utils.dart';

/// Product Listing screen — the full real catalog (`cms_products`, via
/// [catalogProvider]), with search + category filter + price filter +
/// sort, per the Phase 2D brief. Pushed outside the bottom-nav shell,
/// matching Category Detail's pattern. Reached from "View All" on any
/// Home product rail.
///
/// Shares [applyProductFilters]/[ProductSortOption] and
/// [ProductResultsView] with Category Detail rather than re-implementing
/// filtering or result rendering — the only thing unique to this screen is
/// the extra category filter dimension (Category Detail's category is
/// fixed, this one's is chosen via a chip).
class ProductListingScreen extends ConsumerStatefulWidget {
  const ProductListingScreen({super.key});

  @override
  ConsumerState<ProductListingScreen> createState() =>
      _ProductListingScreenState();
}

class _ProductListingScreenState extends ConsumerState<ProductListingScreen> {
  String _searchQuery = '';
  int _categoryChipIndex = 0; // 0 = All
  int _priceFilterIndex = 0;
  ProductSortOption _sort = ProductSortOption.featured;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _categoryChipIndex = 0;
      _priceFilterIndex = 0;
      _sort = ProductSortOption.featured;
    });
  }

  void _retry() {
    ref.invalidate(categoriesProvider);
    ref.invalidate(productsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final catalogAsync = ref.watch(catalogProvider);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.productsTitle, showSearchAction: false),
      body: SafeArea(
        child: ResponsiveCenter(
          width: ContentWidth.grid,
          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: switch (catalogAsync) {
                AsyncData(:final value) => Builder(
                    key: const ValueKey('loaded'),
                    builder: (context) {
                      final (categories, allProducts) = value;
                      final categoryId = _categoryChipIndex == 0
                          ? null
                          : categories[_categoryChipIndex - 1].id;

                      final filtered = applyProductFilters(
                        source: allProducts,
                        locale: locale,
                        categoryId: categoryId,
                        searchQuery: _searchQuery,
                        priceFilterIndex: _priceFilterIndex,
                        sort: _sort,
                      );
                      final filtersActive = _searchQuery.isNotEmpty ||
                          _categoryChipIndex != 0 ||
                          _priceFilterIndex != 0 ||
                          _sort != ProductSortOption.featured;

                      return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.md,
                          ),
                          child: AppBarSearchField(
                            controller: _searchController,
                            hintText: l10n.productListingSearchHint,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            l10n.filterCategoryLabel,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FilterChipRow(
                          labels: [
                            l10n.categoryFilterAll,
                            for (final c in categories) c.name(locale),
                          ],
                          selectedIndex: _categoryChipIndex,
                          onSelected: (i) =>
                              setState(() => _categoryChipIndex = i),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            l10n.filterPriceLabel,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        FilterChipRow(
                          labels: [
                            l10n.categoryFilterAll,
                            l10n.categoryFilterUnder15,
                            l10n.categoryFilter15to25,
                            l10n.categoryFilterOver25,
                          ],
                          selectedIndex: _priceFilterIndex,
                          onSelected: (i) =>
                              setState(() => _priceFilterIndex = i),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SortDropdown<ProductSortOption>(
                              label: l10n.categorySortLabel,
                              value: _sort,
                              onChanged: (value) =>
                                  setState(() => _sort = value ?? _sort),
                              entries: [
                                DropdownMenuEntry(
                                  value: ProductSortOption.featured,
                                  label: l10n.categorySortFeatured,
                                ),
                                DropdownMenuEntry(
                                  value: ProductSortOption.priceLowHigh,
                                  label: l10n.categorySortPriceLowHigh,
                                ),
                                DropdownMenuEntry(
                                  value: ProductSortOption.priceHighLow,
                                  label: l10n.categorySortPriceHighLow,
                                ),
                                DropdownMenuEntry(
                                  value: ProductSortOption.nameAZ,
                                  label: l10n.categorySortNameAZ,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: ProductResultsView(
                            loading: false,
                            products: filtered,
                            locale: locale,
                            sendInquiryLabel: l10n.homeSendInquiry,
                            sendInquirySnackbarText: l10n.homeSendInquirySnackbar,
                            onProductTap: (product) =>
                                context.push('/product/${product.id}'),
                            emptyIcon: Icons.search_off_outlined,
                            emptyMessage: l10n.categoryEmptyFilteredMessage,
                            emptyActionLabel: filtersActive
                                ? l10n.categoryEmptyFilteredCta
                                : null,
                            onEmptyAction: filtersActive ? _clearFilters : null,
                          ),
                        ),
                      ],
                    );
                    },
                  ),
                AsyncError() => Padding(
                    key: const ValueKey('error'),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: ErrorStateView(onRetry: _retry)),
                  ),
                _ => ListView(
                    key: const ValueKey('loading'),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      ProductResultsView(
                        loading: true,
                        products: const [],
                        locale: locale,
                        sendInquiryLabel: l10n.homeSendInquiry,
                        sendInquirySnackbarText: l10n.homeSendInquirySnackbar,
                        emptyIcon: Icons.search_off_outlined,
                        emptyMessage: '',
                      ),
                    ],
                  ),
              },
            ),
          ),
        ),
    );
  }
}
