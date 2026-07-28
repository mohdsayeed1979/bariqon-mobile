import 'package:flutter/material.dart';

import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/app_bar_search_field.dart';
import '../../../core/widgets/coming_soon_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Search UI shell — Phase 2A ships the input and layout only, per the
/// brief ("no search logic yet"). [onChanged]/[onSubmitted] intentionally
/// go nowhere; wiring to ProductRepository.getProducts(query: ...) lands
/// with the Catalog feature (docs/IMPLEMENTATION_ROADMAP.md §15).
class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: BrandedAppBar(title: l10n.searchTitle, showSearchAction: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppBarSearchField(hintText: l10n.searchHint, autofocus: true),
          ),
          Expanded(
            child: ComingSoonPlaceholder(
              title: l10n.searchTitle,
              icon: Icons.search,
            ),
          ),
        ],
      ),
    );
  }
}
