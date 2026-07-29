import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/category_grid_card.dart';
import '../../../core/widgets/skeleton_category_grid_card.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/entities/category.dart';
import 'controllers/catalog_providers.dart';

/// Categories tab root — the real Category List screen, per
/// docs/SCREEN_SPECIFICATIONS.md §4, backed by [categoriesProvider]
/// (real `cms_categories` data) since the Supabase connection pass.
class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

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
              child: AsyncValueView(
                value: categoriesAsync,
                onRetry: () => ref.invalidate(categoriesProvider),
                loading: () =>
                    const _CategoryGridSkeleton(key: ValueKey('loading')),
                data: (categories) => _CategoryGrid(
                  key: const ValueKey('loaded'),
                  categories: categories,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({super.key, required this.categories});

  final List<Category> categories;

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
          for (final category in categories)
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
