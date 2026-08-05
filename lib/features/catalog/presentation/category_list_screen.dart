import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/branded_app_bar.dart';
import '../../../core/widgets/category_grid_card.dart';
import '../../../core/widgets/responsive_center.dart';
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
        child: ResponsiveCenter(
          width: ContentWidth.grid,
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
    );
  }
}

/// How many columns the grid should use for a given available width, and
/// each card's resulting width — computed live rather than fixed, so a
/// catalog with only 1–2 categories fills the row instead of rendering a
/// single narrow card stranded in a sea of empty gutter (the bug this was
/// written to fix), while still looking right with a full catalog.
class _GridMetrics {
  const _GridMetrics(this.columns, this.cardWidth);

  final int columns;
  final double cardWidth;

  factory _GridMetrics.of(double availableWidth) {
    final columns = availableWidth < 340
        ? 1
        : availableWidth < 560
        ? 2
        : availableWidth < 800
        ? 3
        : 4;
    final cardWidth =
        (availableWidth - (columns - 1) * AppSpacing.md) / columns;
    return _GridMetrics(columns, cardWidth);
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({super.key, required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _GridMetrics.of(constraints.maxWidth);
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final category in categories)
                CategoryGridCard(
                  width: metrics.cardWidth,
                  title: category.name(locale),
                  description: category.description(locale),
                  icon: category.icon,
                  onTap: () => context.push('/category/${category.id}'),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = _GridMetrics.of(constraints.maxWidth);
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (var i = 0; i < 5; i++)
                SkeletonCategoryGridCard(width: metrics.cardWidth),
            ],
          );
        },
      ),
    );
  }
}
