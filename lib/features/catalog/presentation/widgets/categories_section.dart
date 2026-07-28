import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/category_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/mock_catalog_data.dart';

/// Home screen "Featured Categories" rail — mock data only, per the
/// Phase 2B brief. Tapping a category navigates to the (still
/// placeholder, Phase 2A) Categories tab — real navigation, not a dead
/// tap, but no filtering logic exists yet.
///
/// No fixed-height wrapper around the row, matching the fix applied to
/// ProductSection — [IntrinsicHeight] sizes the scroller to
/// [CategoryCard]'s real content height instead of a guessed constant.
class CategoriesSection extends StatelessWidget {
  const CategoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < MockCatalogData.categories.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Builder(
                    builder: (context) {
                      final category = MockCatalogData.categories[i];
                      return CategoryCard(
                        label: category.name(locale),
                        icon: category.icon,
                        onTap: () => context.go('/categories'),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
