import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bar_search_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/filter_chip_row.dart';
import '../../../core/widgets/product_results_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../core/widgets/sort_dropdown.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/catalog_providers.dart';
import '../domain/entities/category.dart';
import 'utils/catalog_selectors.dart';
import 'utils/product_filter_utils.dart';

/// Category Detail screen, per docs/SCREEN_SPECIFICATIONS.md-style scope
/// and the Phase 2C brief — banner, description, breadcrumb, local
/// filter/sort/search over this category's products (real `cms_products`
/// data via [catalogProvider]), empty and loading states. Pushed outside
/// the bottom-nav shell, reached from [CategoryGridCard] taps.
///
/// Filtering/sorting/search here operate entirely client-side over the
/// already-fetched product list — no query per keystroke, matching the
/// existing `applyProductFilters` pattern.
///
/// Shares [applyProductFilters]/[ProductSortOption]/[ProductResultsView]
/// with Product Listing (Phase 2D) rather than each screen keeping its own
/// copy of the same filtering/rendering logic.
class CategoryDetailScreen extends ConsumerStatefulWidget {
  const CategoryDetailScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  ConsumerState<CategoryDetailScreen> createState() =>
      _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen> {
  String _searchQuery = '';
  int _filterIndex = 0;
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
      _filterIndex = 0;
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

    return catalogAsync.when(
      loading: () => _CategoryDetailScaffold(
        title: l10n.navCategories,
        body: ListView(
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
      ),
      error: (error, stackTrace) => _CategoryDetailScaffold(
        title: l10n.navCategories,
        body: Center(child: ErrorStateView(onRetry: _retry)),
      ),
      data: (catalog) {
        final (categories, products) = catalog;
        final category = categoryById(categories, widget.categoryId);

        if (category == null) {
          return Scaffold(
            appBar: BrandedAppBar(
              title: l10n.navCategories,
              showSearchAction: false,
            ),
            body: Center(
              child: ErrorStateView(
                message: l10n.categoryNotFound,
                actionLabel: MaterialLocalizations.of(
                  context,
                ).backButtonTooltip,
                onRetry: () => context.canPop()
                    ? context.pop()
                    : context.go('/categories'),
              ),
            ),
          );
        }

        final rawProducts = productsForCategory(products, category.id);
        final visibleProducts = applyProductFilters(
          source: rawProducts,
          locale: locale,
          searchQuery: _searchQuery,
          priceFilterIndex: _filterIndex,
          sort: _sort,
        );
        final filtersActive =
            _searchQuery.isNotEmpty ||
            _filterIndex != 0 ||
            _sort != ProductSortOption.featured;

        return Scaffold(
          appBar: BrandedAppBar(
            title: category.name(locale),
            showSearchAction: false,
          ),
          body: SafeArea(
            child: ResponsiveCenter(
              width: ContentWidth.grid,
              child: ListView(
                      physics: const BouncingScrollPhysics(),
                      key: const ValueKey('loaded'),
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      children: [
                        _Breadcrumb(l10n: l10n, categoryName: category.name(locale)),
                        _CategoryBanner(category: category, locale: locale),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.sm,
                          ),
                          child: Text(
                            category.description(locale),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: AppBarSearchField(
                            controller: _searchController,
                            hintText: l10n.categorySearchHint,
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilterChipRow(
                          labels: [
                            l10n.categoryFilterAll,
                            l10n.categoryFilterUnder15,
                            l10n.categoryFilter15to25,
                            l10n.categoryFilterOver25,
                          ],
                          selectedIndex: _filterIndex,
                          onSelected: (i) => setState(() => _filterIndex = i),
                        ),
                        const SizedBox(height: AppSpacing.md),
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
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Text(
                            l10n.categoryProductsHeading,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: ProductResultsView(
                            loading: false,
                            products: visibleProducts,
                            locale: locale,
                            sendInquiryLabel: l10n.homeSendInquiry,
                            sendInquirySnackbarText: l10n.homeSendInquirySnackbar,
                            onProductTap: (product) =>
                                context.push('/product/${product.id}'),
                            emptyIcon: rawProducts.isEmpty
                                ? Icons.inventory_2_outlined
                                : Icons.search_off_outlined,
                            emptyMessage: rawProducts.isEmpty
                                ? l10n.categoryEmptyNoProductsMessage
                                : l10n.categoryEmptyFilteredMessage,
                            emptyActionLabel: rawProducts.isEmpty
                                ? l10n.categoryEmptyNoProductsCta
                                : (filtersActive
                                    ? l10n.categoryEmptyFilteredCta
                                    : null),
                            onEmptyAction: rawProducts.isEmpty
                                ? () => context.go('/categories')
                                : (filtersActive ? _clearFilters : null),
                          ),
                        ),
                      ],
                    ),
              ),
            ),
        );
      },
    );
  }
}

class _CategoryDetailScaffold extends StatelessWidget {
  const _CategoryDetailScaffold({required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandedAppBar(title: title, showSearchAction: false),
      body: SafeArea(
        child: ResponsiveCenter(width: ContentWidth.grid, child: body),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.l10n, required this.categoryName});

  final AppLocalizations l10n;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop() ? context.pop() : context.go('/categories'),
            child: Text(
              l10n.navCategories,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Directionality.of(context) == TextDirection.rtl
                ? Icons.chevron_left
                : Icons.chevron_right,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          Flexible(
            child: Text(
              categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBanner extends StatelessWidget {
  const _CategoryBanner({required this.category, required this.locale});

  final Category category;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          height: 140,
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, Color(0xFF1B5A44)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -12,
                bottom: -12,
                child: Icon(
                  category.icon,
                  size: 96,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Text(
                  category.name(locale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
