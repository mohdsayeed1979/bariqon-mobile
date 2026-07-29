import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/app_bar_search_field.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/product_results_view.dart';
import '../../../core/widgets/responsive_center.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'controllers/catalog_providers.dart';
import 'utils/product_filter_utils.dart';

/// Search screen — live search over the real product catalog
/// ([productsProvider]), reusing [applyProductFilters]/[ProductResultsView]
/// just like Category Detail and Product Listing rather than a third copy
/// of the same filtering/rendering logic.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.searchTitle, showSearchAction: false),
      body: ResponsiveCenter(
        width: ContentWidth.wide,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppBarSearchField(
                hintText: l10n.searchHint,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: EmptyStateView(
                        icon: Icons.search_outlined,
                        message: l10n.searchPromptMessage,
                      ),
                    )
                  : productsAsync.when(
                      data: (products) {
                        final results = applyProductFilters(
                          source: products,
                          locale: locale,
                          searchQuery: _query,
                        );
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: ProductResultsView(
                            loading: false,
                            products: results,
                            locale: locale,
                            sendInquiryLabel: l10n.homeSendInquiry,
                            sendInquirySnackbarText:
                                l10n.homeSendInquirySnackbar,
                            onProductTap: (product) =>
                                context.push('/product/${product.id}'),
                            emptyIcon: Icons.search_outlined,
                            emptyMessage: l10n.categoryEmptyFilteredMessage,
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(
                        child: ErrorStateView.forError(
                          context,
                          error,
                          onRetry: () => ref.invalidate(productsProvider),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
