import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/category_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_category_card.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/category.dart';
import '../controllers/catalog_providers.dart';

/// Home screen "Featured Categories" rail, per the Phase 5 brief — backed
/// by [categoriesProvider] (Supabase when configured, mock otherwise; see
/// catalog_providers.dart). Tapping a category opens its real Category
/// Detail screen; the section header's "View All" goes to the Categories
/// tab instead, since that's a browse-everything action rather than a
/// single category.
///
/// No fixed-height wrapper around the row, matching the fix applied to
/// ProductSection — [IntrinsicHeight] sizes the scroller to
/// [CategoryCard]'s real content height instead of a guessed constant.
class CategoriesSection extends ConsumerWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.homeSectionFeaturedCategories,
          actionLabel: l10n.homeViewAll,
          onAction: () => context.go('/categories'),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: AsyncValueView<List<Category>>(
              value: categoriesAsync,
              loading: () => const Row(
                children: [
                  SkeletonCategoryCard(),
                  SizedBox(width: AppSpacing.md),
                  SkeletonCategoryCard(),
                  SizedBox(width: AppSpacing.md),
                  SkeletonCategoryCard(),
                ],
              ),
              error: (error, stackTrace) => SizedBox(
                width: 200,
                child: Text(
                  l10n.genericErrorMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              data: (categories) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < categories.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.md),
                    Builder(
                      builder: (context) {
                        final category = categories[i];
                        return CategoryCard(
                          label: category.name(locale),
                          icon: category.icon,
                          onTap: () =>
                              context.push('/category/${category.id}'),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
