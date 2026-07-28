import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/category_grid_card.dart';
import '../../../core/widgets/skeleton_category_grid_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/mock_catalog_data.dart';

/// Categories tab root — the real Category List screen, per
/// docs/SCREEN_SPECIFICATIONS.md §4, built out in Phase 2C. UI only: mock
/// data (see mock_catalog_data.dart), a simulated brief loading phase to
/// demonstrate the skeleton state, no Supabase/repository calls.
class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Simulated load — there's no repository yet to await. Kept short and
    // purely cosmetic, so the skeleton state (Phase 2C requirement) is
    // actually visible rather than instant.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: BrandedAppBar(title: l10n.navCategories),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Keeps the grid from stretching edge-to-edge on tablet/desktop
            // widths — mobile-first, tablet-ready per the Phase 2C brief.
            constraints: const BoxConstraints(maxWidth: 900),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _loading
                  ? _CategoryGridSkeleton(key: const ValueKey('loading'))
                  : _CategoryGrid(key: const ValueKey('loaded')),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final category in MockCatalogData.categories)
            CategoryGridCard(
              title: category.name(locale),
              description: category.description(locale),
              icon: category.icon,
              onTap: () => context.push('/category/${category.id}'),
            ),
        ],
      ),
    );
  }
}

class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: const [
          SkeletonCategoryGridCard(),
          SkeletonCategoryGridCard(),
          SkeletonCategoryGridCard(),
          SkeletonCategoryGridCard(),
          SkeletonCategoryGridCard(),
        ],
      ),
    );
  }
}
