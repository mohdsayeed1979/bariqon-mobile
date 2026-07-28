import 'package:flutter/material.dart';

import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/coming_soon_placeholder.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Categories tab root — Phase 2A placeholder. Becomes the real Category
/// List screen (docs/SCREEN_SPECIFICATIONS.md §4) in Phase 2B.
class CategoryListScreen extends StatelessWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: BrandedAppBar(title: l10n.navCategories),
      body: ComingSoonPlaceholder(
        title: l10n.navCategories,
        icon: Icons.category_outlined,
      ),
    );
  }
}
