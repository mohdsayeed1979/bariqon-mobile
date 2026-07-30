import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'skeleton_box.dart';

/// Loading placeholder matching [CategoryCard]'s exact proportions — same
/// shimmer primitive as [SkeletonProductCard], used by Home's category
/// rail while `categoriesProvider` is loading.
class SkeletonCategoryCard extends StatelessWidget {
  const SkeletonCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 96,
      child: Column(
        children: [
          SkeletonBox(width: 72, height: 72, borderRadius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: 64, height: 14),
        ],
      ),
    );
  }
}
