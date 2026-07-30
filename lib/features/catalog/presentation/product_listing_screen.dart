import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_bar_search_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/filter_chip_row.dart';
import '../../../core/widgets/product_results_view.dart';
import '../../../core/widgets/sort_dropdown.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/catalog_providers.dart';
import 'utils/product_filter_utils.dart';

/// Product Listing screen — search + category filter + price filter +
/// sort over the full catalog, per the Phase 2D brief. Backed by
/// [categoriesProvider]/[productsProvider] as of Phase 5 (Supabase when
/// configured, mock otherwise — see catalog_providers.dart). Pushed
/// outside the bottom-nav shell, matching Category Detail's pattern.
/// Reached from "View All" on any Home product rail.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(productsProvider);

    final loading = categoriesAsync.isLoading || productsAsync.isLoading;
    final error = categoriesAsync.error ?? productsAsync.error;

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.productsTitle, showSearchAction: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: AnimatedSwitcher(
              duration: AppMotion.contentSwitch,
              switchInCurve: AppMotion.standardCurve,
              switchOutCurve: AppMotion.standardCurve,
              child: loading
                  ? ListView(
                      key: const ValueKey('loading'),
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
                    )
                  : error != null
                  ? Center(
                      key: const ValueKey('error'),
                      child: ErrorStateView(
                        onRetry: () {
                          ref.invalidate(categoriesProvider);
                          ref.invalidate(productsProvider);
                        },
                      ),
                    )
                  : Builder(
                      key: const ValueKey('loaded'),
                      builder: (context) {
                        final categories = categoriesAsync.value!;
                        final categoryId = _categoryChipIndex == 0
                            ? null
                            : categories[_categoryChipIndex - 1].id;
                        final filtered = applyProductFilters(
                          source: productsAsync.value!,
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
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      children: [
                        // Tighter vertical rhythm through the filter block
                        // (sm/xs gaps instead of md/lg) per the "filters
                        // consume too much vertical space" polish request
                        // — FilterChipRow/SortDropdown themselves are
                        // unchanged, so their own overflow-safe wrapping
                        // still applies.
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.sm,
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
                        const SizedBox(height: AppSpacing.sm),
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
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
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
                        const SizedBox(height: AppSpacing.md),
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
            ),
          ),
        ),
      ),
    );
  }
}
